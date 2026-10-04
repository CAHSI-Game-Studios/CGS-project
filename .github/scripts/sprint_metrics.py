"""Daily GitHub Project metrics. Python 3.13; standard library only."""

import argparse
from collections import Counter
from datetime import date, datetime, time, timedelta, timezone
from html import escape
import json
import math
import os
from pathlib import Path
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo


PAGE = "pageInfo { hasNextPage endCursor }"
CONFIG = Path(__file__).resolve().parents[1] / "metrics-config.json"
OUTLINE = """### Worked on yesterday
- ...

### Blockers
- None / describe the blocker and help needed.

### Planned for today
- ..."""


class MetricsError(Exception):
    pass


class GitHub:
    def __init__(self, token):
        if not token:
            raise MetricsError("Required token is missing. See bin/docs/SprintMetrics.md.")
        self.token = token
        self.api_url = os.environ.get("GITHUB_API_URL", "https://api.github.com")
        self.graphql_url = os.environ.get("GITHUB_GRAPHQL_URL", "https://api.github.com/graphql")

    def request(self, method, path, body=None, missing_ok=False):
        url = self.graphql_url if path == "graphql" else self.api_url + path
        request = Request(url, method=method, headers={
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/vnd.github+json",
            "Content-Type": "application/json",
            "User-Agent": "the-arcade-sprint-metrics",
            "X-GitHub-Api-Version": "2022-11-28",
        }, data=None if body is None else json.dumps(body).encode())
        try:
            with urlopen(request, timeout=60) as response:
                data = response.read()
                return json.loads(data) if data else None
        except HTTPError as error:
            if missing_ok and error.code == 404:
                return None
            raise MetricsError(
                f"GitHub {method} {path}: HTTP {error.code}. "
                "Check token permissions, organization authorization, and configuration."
            ) from error
        except URLError as error:
            raise MetricsError(f"Unable to reach GitHub: {error.reason}") from error

    def graphql(self, query, **variables):
        response = self.request("POST", "graphql", {"query": query, "variables": variables})
        if response.get("errors"):
            messages = "; ".join(error["message"] for error in response["errors"])
            raise MetricsError(f"GitHub GraphQL: {messages}")
        return response["data"]

    def connection(self, query, path, **variables):
        cursor = None
        while True:
            value = self.graphql(query, **variables, cursor=cursor)
            for key in path:
                if value is None:
                    raise MetricsError(f"GitHub returned an inaccessible object at {'.'.join(path)}.")
                value = value[key]
            yield from (node for node in value["nodes"] if node is not None)
            if not value["pageInfo"]["hasNextPage"]:
                return
            cursor = value["pageInfo"]["endCursor"]

    def rest_list(self, path):
        page = 1
        while True:
            separator = "&" if "?" in path else "?"
            values = self.request("GET", f"{path}{separator}per_page=100&page={page}")
            yield from values
            if len(values) < 100:
                return
            page += 1


def local_zone(name):
    return timezone.utc if name == "UTC" else ZoneInfo(name)


def timestamp(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def sprint_bounds(sprint, zone):
    start = date.fromisoformat(sprint["startDate"])
    end = start + timedelta(days=sprint["duration"])
    return datetime.combine(start, time.min, zone), datetime.combine(end, time.min, zone)


def active_sprints(configuration, today):
    iterations = configuration["iterations"] + configuration["completedIterations"]
    unique = {iteration["id"]: iteration for iteration in iterations}
    return sorted((iteration for iteration in unique.values()
                   if date.fromisoformat(iteration["startDate"]) <= today
                   < date.fromisoformat(iteration["startDate"]) + timedelta(days=iteration["duration"])),
                  key=lambda iteration: (iteration["startDate"], iteration["id"]))


def detect(api, config, repository, now):
    owner, _ = repository.split("/")
    raw_number = os.environ.get("METRICS_PROJECT_NUMBER") or config["project_number"]
    try:
        number = int(raw_number)
        if number <= 0:
            raise ValueError
    except (TypeError, ValueError) as error:
        raise MetricsError("Set project_number in .github/metrics-config.json or METRICS_PROJECT_NUMBER.") from error
    query = """query($owner: String!, $number: Int!) {
      organization(login: $owner) { projectV2(number: $number) {
        id title url closed
      } }
    }"""
    organization = api.graphql(query, owner=owner, number=number)["organization"]
    project = organization and organization["projectV2"]
    if not project:
        raise MetricsError("Project not found or METRICS_TOKEN cannot read it.")
    fields_query = """query($id: ID!, $cursor: String) {
      node(id: $id) { ... on ProjectV2 { fields(first: 100, after: $cursor) {
        nodes { ... on ProjectV2IterationField {
          name configuration {
            iterations { id title startDate duration }
            completedIterations { id title startDate duration }
          }
        } } PAGE
      } } }
    }""".replace("PAGE", PAGE)
    fields = [field for field in api.connection(fields_query, ("node", "fields"), id=project["id"])
              if "configuration" in field
              and (not config["iteration_field"] or field["name"] == config["iteration_field"])]
    if len(fields) != 1:
        raise MetricsError("Set iteration_field to the exact name of one iteration field in the project.")
    field = fields[0]
    config = dict(config, iteration_field=field["name"])
    today = now.astimezone(local_zone(config["timezone"])).date()
    active = [] if project["closed"] else active_sprints(field["configuration"], today)
    return {"repository": repository, "project": {key: project[key] for key in ("id", "title", "url")},
            "project_number": number, "date": today.isoformat(), "active_sprints": active,
            "config": config}


def points_for(value, mapping):
    if not value:
        return None
    if value.get("__typename") == "ProjectV2ItemFieldNumberValue":
        points = value.get("number")
    elif value.get("__typename") == "ProjectV2ItemFieldSingleSelectValue":
        label = value.get("name")
        if label not in mapping:
            raise MetricsError(f"Size {label!r} has no point mapping in size_points.")
        points = mapping[label]
    else:
        raise MetricsError("Size must be a number or a single-select field.")
    if points is None:
        return None
    if isinstance(points, bool) or not isinstance(points, (int, float)) or not math.isfinite(points) or points < 0:
        raise MetricsError("Size points must be finite, non-negative numbers.")
    return float(points)


def collect_issues(api, context):
    config = context["config"]
    field = api.graphql("""query($id: ID!, $name: String!) {
      node(id: $id) { ... on ProjectV2 { field(name: $name) {
        ... on ProjectV2FieldCommon { name dataType }
      } } }
    }""", id=context["project"]["id"], name=config["size_field"])["node"]["field"]
    if not field or field.get("dataType") not in ("NUMBER", "SINGLE_SELECT"):
        raise MetricsError(f"Size field {config['size_field']!r} must exist and be numeric or single-select.")
    query = """query($id: ID!, $iteration: String!, $size: String!, $cursor: String) {
      node(id: $id) { ... on ProjectV2 { items(first: 100, after: $cursor) {
        nodes {
          iteration: fieldValueByName(name: $iteration) {
            ... on ProjectV2ItemFieldIterationValue { iterationId }
          }
          size: fieldValueByName(name: $size) {
            __typename
            ... on ProjectV2ItemFieldNumberValue { number }
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          content { __typename ... on Issue {
            id number title url state stateReason closedAt
            repository { nameWithOwner }
            assignees(first: 100) { nodes { login } PAGE }
          } }
        } PAGE
      } } }
    }""".replace("PAGE", PAGE)
    active = {sprint["id"] for sprint in context["active_sprints"]}
    issues = {}
    for item in api.connection(query, ("node", "items"), id=context["project"]["id"],
                               iteration=config["iteration_field"], size=config["size_field"]):
        iteration_id = (item.get("iteration") or {}).get("iterationId")
        if iteration_id not in active:
            continue
        content = item.get("content")
        if content is None:
            raise MetricsError("An active sprint contains an inaccessible item; grant access before reporting totals.")
        if content["__typename"] != "Issue":
            continue
        # The selected organization project defines sprint scope, including linked repositories.
        assignees = content.pop("assignees")
        if assignees["pageInfo"]["hasNextPage"]:
            raise MetricsError("Issue assignee list exceeded 100; refusing to publish incomplete credit.")
        content["assignees"] = [user["login"] for user in assignees["nodes"]]
        content["points"] = points_for(item.get("size"), config["size_points"])
        content["iteration_id"] = iteration_id
        issues[content["id"]] = content
    return list(issues.values())


def roster(api, repository, collaborator_slug, producer_slug):
    owner, _ = repository.split("/")
    # GitHub includes child-team members, so the parent roster includes Producers.
    # Missing or unreadable teams fail; never fall back to repository collaborators.
    collaborators = {user["login"] for user in api.rest_list(
        f"/orgs/{owner}/teams/{quote(collaborator_slug, safe='')}/members")
        if user.get("type") != "Bot"}
    producers = {user["login"].casefold() for user in api.rest_list(
        f"/orgs/{owner}/teams/{quote(producer_slug, safe='')}/members")}
    return sorted(collaborators, key=str.casefold), producers


def discussion_marker(context, day):
    return f"<!-- arcade-daily:{context['project']['id']}:{day} -->"


def discussion_context(api, context):
    owner, name = context["repository"].split("/")
    repo = api.graphql("""query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        id hasDiscussionsEnabled discussionCategories(first: 100) { nodes { id name } }
      }
    }""", owner=owner, name=name)["repository"]
    if not repo or not repo["hasDiscussionsEnabled"]:
        raise MetricsError("Enable repository Discussions before running sprint metrics.")
    category_name = context["config"]["discussion_category"]
    category = next((category for category in repo["discussionCategories"]["nodes"]
                     if category["name"] == category_name), None)
    if not category:
        raise MetricsError(f"Discussion category {category_name!r} does not exist.")
    today = context["date"]
    yesterday = (date.fromisoformat(today) - timedelta(days=1)).isoformat()
    found = {}
    query = """query($owner: String!, $name: String!, $cursor: String) {
      repository(owner: $owner, name: $name) {
        discussions(first: 100, after: $cursor, orderBy: {field: CREATED_AT, direction: DESC}) {
          nodes { id number url body } PAGE
        }
      }
    }""".replace("PAGE", PAGE)
    # Paginate repository discussions instead of search (which can lag after creation).
    # Scan all categories so moving a discussion does not cause a duplicate.
    for discussion in api.connection(query, ("repository", "discussions"), owner=owner, name=name):
        for day in (today, yesterday):
            if discussion_marker(context, day) in discussion["body"]:
                if day in found:
                    raise MetricsError(f"Multiple daily discussions found for {day}; resolve duplicates first.")
                found[day] = discussion
    return repo["id"], category["id"], found.get(today), found.get(yesterday)


def participation(api, discussion, now):
    counts = Counter()
    if discussion is None:
        return counts
    query = """query($id: ID!, $cursor: String) {
      node(id: $id) { ... on Discussion { comments(first: 100, after: $cursor) {
        nodes { id author { login __typename } createdAt } PAGE
      } } }
    }""".replace("PAGE", PAGE)
    replies = """query($id: ID!, $cursor: String) {
      node(id: $id) { ... on DiscussionComment { replies(first: 100, after: $cursor) {
        nodes { id author { login __typename } createdAt } PAGE
      } } }
    }""".replace("PAGE", PAGE)
    seen = set()

    def count(comment):
        author = comment["author"]
        if (comment["id"] not in seen and author and author["__typename"] == "User"
                and timestamp(comment["createdAt"]) <= now):
            counts[author["login"].casefold()] += 1
        seen.add(comment["id"])

    for comment in api.connection(query, ("node", "comments"), id=discussion["id"]):
        count(comment)
        for reply in api.connection(replies, ("node", "replies"), id=comment["id"]):
            count(reply)
    return counts


def is_completed(issue, now):
    return (issue["state"] == "CLOSED" and issue["stateReason"] == "COMPLETED"
            and issue["closedAt"] is not None and timestamp(issue["closedAt"]) <= now)


def sprint_metrics(sprint, issues, collaborators, producers, now, zone):
    scoped = [issue for issue in issues if issue["iteration_id"] == sprint["id"]]
    completed = [issue for issue in scoped if is_completed(issue, now)]
    start, end = sprint_bounds(sprint, zone)
    credit = {login: 0.0 for login in collaborators if login.casefold() not in producers}
    by_login = {login.casefold(): login for login in credit}
    unattributed = 0.0
    for issue in completed:
        if not start <= timestamp(issue["closedAt"]) < end or issue["points"] is None:
            continue
        assignees = {login.casefold() for login in issue["assignees"]}
        if not assignees:
            unattributed += issue["points"]
        for login in assignees:
            share = issue["points"] / len(assignees)
            if login in by_login:
                credit[by_login[login]] += share
            else:
                unattributed += share
    # Current snapshot, using latest close dates; reopened issues are no longer complete.
    days = [start.date() + timedelta(days=offset) for offset in range(sprint["duration"])]
    series = [(day, sum(timestamp(issue["closedAt"]).astimezone(zone).date() <= day
                        for issue in completed)) for day in days if day <= now.astimezone(zone).date()]
    return {"issues": scoped, "completed": completed, "credit": credit,
            "unattributed": unattributed, "series": series, "start": start, "end": end}


def chart_svg(sprint, metrics, now):
    width, height, left, right, top, bottom = 960, 380, 70, 930, 58, 300
    total = len(metrics["issues"])
    start, end = metrics["start"], metrics["end"]

    def x(moment):
        return left + (right - left) * ((moment - start).total_seconds() / (end - start).total_seconds())

    def y(count):
        return bottom - (bottom - top) * count / max(total, 1)

    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
           f'<title id="title">{escape(sprint["title"])}: completed issues</title>',
           f'<desc id="desc">Sprint scope: {total} issues. Completed: {len(metrics["completed"])}. Line stops at report time.</desc>',
           '<rect width="100%" height="100%" fill="#ffffff"/>',
           '<g font-family="system-ui, sans-serif" font-size="13" fill="#24292f">',
           f'<text x="70" y="28" font-size="18">Completed issues / {total} issues in sprint</text>']
    ticks = sorted({round(total * part / 5) for part in range(6)})
    for tick in ticks:
        svg.extend([f'<line x1="{left}" x2="{right}" y1="{y(tick):.2f}" y2="{y(tick):.2f}" stroke="#d0d7de"/>',
                    f'<text x="58" y="{y(tick) + 5:.2f}" text-anchor="end">{tick}</text>'])
    duration = sprint["duration"]
    for offset in sorted({round(duration * part / min(duration, 6)) for part in range(min(duration, 6) + 1)}):
        moment = start + timedelta(days=offset)
        svg.append(f'<text x="{x(moment):.2f}" y="326" text-anchor="middle">{moment:%m-%d}</text>')
    svg.append(f'<path d="M {left} {top} V {bottom} H {right}" fill="none" stroke="#57606a"/>')
    if total:
        closures = sorted(timestamp(issue["closedAt"]).astimezone(start.tzinfo) for issue in metrics["completed"])
        count = sum(moment <= start for moment in closures)
        points = [(x(start), y(count))]
        for moment in closures:
            if start < moment < end:
                points.append((x(moment), y(count)))
                count += 1
                points.append((x(moment), y(count)))
        points.append((x(min(now.astimezone(start.tzinfo), end)), y(count)))
        coordinates = " ".join(f"{px:.2f},{py:.2f}" for px, py in points)
        svg.append(f'<polyline points="{coordinates}" fill="none" stroke="#0969da" stroke-width="3"/>')
    else:
        svg.append('<text x="480" y="180" text-anchor="middle">No issues assigned to this sprint.</text>')
    svg.append('<text x="480" y="362" text-anchor="middle">Sprint dates (last tick is the exclusive end boundary)</text></g></svg>')
    return "\n".join(svg) + "\n"


def md(value):
    return escape(str(value)).replace("|", "&#124;").replace("\n", " ").replace("[", "&#91;").replace("]", "&#93;")


def discussion_body(context):
    sprints = ", ".join(md(sprint["title"]) for sprint in context["active_sprints"])
    return (f"{discussion_marker(context, context['date'])}\n\n"
            f"Daily check-in for **{context['date']}** ({md(context['config']['timezone'])}).\n\n"
            f"Active sprints: {sprints}.\n\n"
            "Post a comment using the outline below. Link the issues you worked on and flag any help you need.\n\n"
            f"{OUTLINE}\n")


def render_report(context, all_metrics, collaborators, counts, today_discussion, yesterday, now):
    yesterday_date = (date.fromisoformat(context["date"]) - timedelta(days=1)).isoformat()
    lines = [f"# Sprint metrics — {context['date']}", "",
             f"Project: [{md(context['project']['title'])}]({context['project']['url']})", "",
             f"Snapshot: {now.isoformat()} · Calendar timezone: {md(context['config']['timezone'])}.", "",
             f"Collaborator tables include members of `{md(context['config']['collaborator_team_slug'])}` "
             "and its child teams.", "",
             "## Daily check-in", "", f"[Join today's discussion]({today_discussion['url']})", "", OUTLINE, ""]
    for sprint, metrics, image_path in all_metrics:
        completed_in_sprint = [issue for issue in metrics["completed"]
                               if metrics["start"] <= timestamp(issue["closedAt"]) < metrics["end"]]
        lines += [f"## {md(sprint['title'])}", "",
                  f"{metrics['start']:%Y-%m-%d} through {metrics['end'] - timedelta(days=1):%Y-%m-%d} (inclusive).", "",
                  "### Sprint velocity (issue completion burn-up)", "",
                  f"![Completed issues over the sprint]({image_path})", "",
                  f"**{len(metrics['completed'])} / {len(metrics['issues'])} issues complete**; "
                  f"{len(completed_in_sprint)} closed as completed during this sprint.", "",
                  "The y-axis maximum is the current sprint issue count. The x-axis spans the full sprint; "
                  "the line stops at snapshot time. Earlier completions form the starting baseline.", "",
                  "| Date | Completed issues as of this snapshot |", "| --- | ---: |"]
        lines += [f"| {day} | {count} |" for day, count in metrics["series"]]
        lines += ["", "### Completed points by collaborator", "",
                  "Producer team members are excluded. Points are split equally among all current assignees; "
                  "shares belonging to excluded people are not redistributed.", "",
                  "| Collaborator | Points closed during sprint |", "| --- | ---: |"]
        lines += [f"| @{login} | {points:.2f} |" for login, points in sorted(
            metrics["credit"].items(), key=lambda row: (-row[1], row[0].casefold()))]
        lines += ["", f"Points not credited to listed collaborators: **{metrics['unattributed']:.2f}** "
                  "(unassigned issues, Producers, or people outside the collaborator team).", "",
                  "### Sprint issue audit", "", "| Issue | State | Size points | Assignees | Latest close |",
                  "| --- | --- | ---: | --- | --- |"]
        for issue in sorted(metrics["issues"], key=lambda issue: issue["url"]):
            size = "Unestimated" if issue["points"] is None else f"{issue['points']:g}"
            label = f"{issue['repository']['nameWithOwner']}#{issue['number']} {issue['title']}"
            state = issue["stateReason"] or issue["state"]
            lines.append(f"| [{md(label)}]({issue['url']}) | {state} | {size} | "
                         f"{', '.join('@' + login for login in issue['assignees']) or 'Unassigned'} | {issue['closedAt'] or '—'} |")
        lines += ["", "Unestimated issues count toward issue totals and contribute no points. Only issues closed "
                  "as COMPLETED earn points; NOT_PLANNED and reopened issues do not. "
                  "Scope, sizes and assignees reflect the current project. Historical chart values are reconstructed "
                  "from currently completed issues and their latest close times; previous daily reports preserve earlier snapshots.", ""]
    lines += [f"## Participation in the {yesterday_date} daily check-in", ""]
    if yesterday:
        lines += [f"[Previous day's discussion]({yesterday['url']})", "",
                  "Counts top-level comments and replies in that discussion through snapshot time, including late replies. "
                  "Edits, reactions, the opening post, bots and deleted authors do not count. This table includes Producers.", ""]
    else:
        lines += ["No daily check-in was found for the previous calendar day. N/A means there was no discussion to measure.", ""]
    lines += ["| Collaborator | Participations |", "| --- | ---: |"]
    lines += [f"| @{login} | {counts[login.casefold()] if yesterday else 'N/A'} |" for login in collaborators]
    return "\n".join(lines) + "\n"


def publish_files(api, repository, files, day):
    prefix = f"/repos/{repository}/git"
    ref = api.request("GET", prefix + "/ref/heads/metrics", missing_ok=True)
    parent = ref["object"]["sha"] if ref else None
    base_tree = None
    if parent:
        base_tree = api.request("GET", prefix + f"/commits/{parent}")["tree"]["sha"]
    entries = [{"path": path, "mode": "100644", "type": "blob", "content": content}
               for path, content in sorted(files.items())]
    tree_body = {"tree": entries}
    if base_tree:
        tree_body["base_tree"] = base_tree
    tree = api.request("POST", prefix + "/trees", tree_body)
    if tree["sha"] == base_tree:
        return False
    commit = api.request("POST", prefix + "/commits", {
        "message": f"metrics: daily sprint report {day}", "tree": tree["sha"],
        "parents": [parent] if parent else [],
        "author": {"name": "github-actions[bot]", "email": "41898282+github-actions[bot]@users.noreply.github.com"},
    })
    if parent:
        api.request("PATCH", prefix + "/refs/heads/metrics", {"sha": commit["sha"], "force": False})
    else:
        api.request("POST", prefix + "/refs", {"ref": "refs/heads/metrics", "sha": commit["sha"]})
    return True


def publish(read_api, repo_api, context, output, now):
    if not context["active_sprints"]:
        return
    zone = local_zone(context["config"]["timezone"])
    if now.astimezone(zone).date().isoformat() != context["date"]:
        raise MetricsError("Calendar date changed after sprint detection; rerun the workflow.")
    issues = collect_issues(read_api, context)
    collaborators, producers = roster(read_api, context["repository"],
                                      context["config"]["collaborator_team_slug"],
                                      context["config"]["producer_team_slug"])
    repo_id, category_id, discussion, yesterday = discussion_context(repo_api, context)
    counts = participation(repo_api, yesterday, now)
    files, results = {}, []
    for sprint in context["active_sprints"]:
        metrics = sprint_metrics(sprint, issues, collaborators, producers, now, zone)
        filename = f"{context['date']}-{quote(sprint['id'], safe='')}.svg"
        files[f"charts/{filename}"] = chart_svg(sprint, metrics, now)
        results.append((sprint, metrics, f"../charts/{filename}"))
    # Finish reads and validation before posting. Reruns locate the marker and reuse the thread.
    if discussion is None:
        discussion = repo_api.graphql("""mutation($input: CreateDiscussionInput!) {
          createDiscussion(input: $input) { discussion { id number url } }
        }""", input={"repositoryId": repo_id, "categoryId": category_id,
                      "title": f"Daily check-in — {context['date']}", "body": discussion_body(context)})["createDiscussion"]["discussion"]
    report = render_report(context, results, collaborators, counts, discussion, yesterday, now)
    files[f"daily/{context['date']}.md"] = report
    files["README.md"] = ("# The Arcade sprint metrics\n\n"
                          f"[Latest daily report: {context['date']}](daily/{context['date']}.md)\n\n"
                          f"[All daily reports](daily/) · [Workflow setup](https://github.com/{context['repository']}/blob/HEAD/bin/docs/SprintMetrics.md)\n")
    output.mkdir(parents=True, exist_ok=True)
    for path, content in files.items():
        target = output / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
    publish_files(repo_api, context["repository"], files, context["date"])
    summary(f"Published [{context['date']} metrics](https://github.com/{context['repository']}/blob/metrics/daily/{context['date']}.md).\n")


def summary(message):
    print(message)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as handle:
            handle.write(message + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("detect", "publish", "cancel"))
    parser.add_argument("--context", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    repository = os.environ.get("GITHUB_REPOSITORY", "")
    if not repository or repository.count("/") != 1:
        raise MetricsError("GITHUB_REPOSITORY must be owner/repository.")
    if args.command == "cancel":
        summary("No sprint is underway today. Cancelling without creating discussions or metrics.")
        GitHub(os.environ.get("GITHUB_TOKEN")).request(
            "POST", f"/repos/{repository}/actions/runs/{os.environ['GITHUB_RUN_ID']}/cancel")
        return
    if args.context is None:
        parser.error("--context is required")
    now = datetime.now(timezone.utc)
    api = GitHub(os.environ.get("METRICS_TOKEN"))
    if args.command == "detect":
        config = json.loads(CONFIG.read_text(encoding="utf-8"))
        context = detect(api, config, repository, now)
        args.context.write_text(json.dumps(context), encoding="utf-8")
        active = bool(context["active_sprints"])
        if os.environ.get("GITHUB_OUTPUT"):
            with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as handle:
                handle.write(f"active={str(active).lower()}\n")
        summary(f"Found {len(context['active_sprints'])} active sprint(s) on {context['date']}.")
    else:
        if args.output is None:
            parser.error("--output is required")
        context = json.loads(args.context.read_text(encoding="utf-8"))
        if context["repository"] != repository:
            raise MetricsError("Sprint context belongs to a different repository.")
        publish(api, GitHub(os.environ.get("GITHUB_TOKEN")), context, args.output, now)


if __name__ == "__main__":
    try:
        main()
    except (MetricsError, ValueError, KeyError) as error:
        print(f"Sprint metrics failed: {error}", file=sys.stderr)
        sys.exit(1)
