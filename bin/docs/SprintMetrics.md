# Daily sprint metrics

The `Daily sprint metrics` workflow reads [CAHSI-Game-Studios project #3](https://github.com/orgs/CAHSI-Game-Studios/projects/3) every day at **09:05 America/La_Paz (13:05 UTC)**, including weekends. It also supports **Actions → Daily sprint metrics → Run workflow**. GitHub may delay scheduled runs.

On a day with an active iteration, it creates one check-in discussion in **Daily Check In** and publishes a Markdown report to the **metrics** branch. The report includes the check-in outline and link, a completion graph for each active sprint, completed points by collaborator, and participation in yesterday's check-in.

On a day with no active iteration, it requests cancellation of its own workflow run before reading issue metrics, creating discussions, or updating the branch. Missing configuration or API permissions cause a failure, not a misleading “no sprint” result.

## Enable the workflow

1. In repository **Settings → General → Features**, enable **Discussions** and confirm the **Daily Check In** category exists.
2. Add an Actions repository secret named **`METRICS_TOKEN`** in **Settings → Secrets and variables → Actions**. Use an organization-authorized token belonging to an organization member who can read project #3, every repository whose issues appear in that project, the **The Arcade Collaborator** team, and the **Producer** team.
   - For a fine-grained personal access token, select **CAHSI-Game-Studios** as resource owner; grant organization **Projects: read** and **Members: read**, plus repository **Issues: read** and **Metadata: read** for the relevant repositories. Complete any organization approval required for that token.
   - If using a classic token instead, it needs **`read:project`**, **`read:org`**, and **`repo`** for private repositories. Authorize it for the organization's SSO if required.
   - Keep the token in Actions secrets. Do not commit it or put it in the JSON configuration.
3. The roster comes from [The Arcade Collaborator](https://github.com/orgs/CAHSI-Game-Studios/teams/the-arcade-collaborator), including members inherited from child teams. Confirm the Producer sub-team's URL ends in `/teams/producer`; if its slug differs, change `producer_team_slug`. Producer members (including any of its own child teams) are excluded from points but included in participation. Repository access alone does not put someone in either collaborator table.
4. Merge the workflow and scripts into the repository's default branch to enable scheduled runs. Allow the workflow's built-in `GITHUB_TOKEN` to use **contents: write**, **discussions: write**, and **actions: write**. Repository/organization policy and branch rules must permit it to create and update `metrics`.
5. Run the workflow manually during a sprint to validate live access. Its first successful active run creates the `metrics` branch automatically.

`METRICS_TOKEN` reads organization data. The built-in `GITHUB_TOKEN` creates discussions, publishes reports, and cancels inactive runs; no extra write permissions are needed on the personal token. A GitHub App installation token with the corresponding read permissions can also replace `METRICS_TOKEN`, but short-lived installation tokens must be minted by an added workflow step rather than stored permanently.

GitHub references: [Project automation authentication](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/automating-projects-using-actions), [Project API authentication](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects), [team membership permissions and inherited membership](https://docs.github.com/en/rest/teams/members#list-team-members), [scheduled workflow behavior](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule).

## Configuration

Edit [`.github/metrics-config.json`](../../.github/metrics-config.json):

| Setting | Configured value / behavior |
| --- | --- |
| `project_number` | `3`; an Actions variable named `METRICS_PROJECT_NUMBER` can override it |
| `iteration_field` | `null`: discover the project's single iteration field, whether named Sprint or Iteration; set the exact field name if multiple iteration fields exist |
| `size_field` | `Size`; numeric sizes are used directly |
| `size_points` | `XS: 1`, `S: 2`, `M: 3`, `L: 5`, `XL: 8` |
| `discussion_category` | `Daily Check In`; exact category name |
| `collaborator_team_slug` | `the-arcade-collaborator`; roster for both collaborator tables, including child-team members |
| `producer_team_slug` | `producer` |
| `timezone` | `America/La_Paz`, used for sprint boundaries and yesterday's date |

The organization is derived from the repository owner. Changing `timezone` does not change the cron expression; adjust both if you want a different local run time. An iteration starts at local midnight on its `startDate` and ends at local midnight `duration` days later. The last day is included. A closed project is treated as inactive. Multiple active iterations receive separate sprint sections within the day's single report/discussion.

## What the numbers mean

**Completion graph:** The y-axis maximum is the number of issues currently assigned to that sprint in the project. The x-axis spans the entire iteration, ending at the following midnight. The blue line shows currently completed issues using their latest close timestamps and stops at report time; future dates are left blank. Issues completed before the sprint form the starting baseline. This is an issue-count burn-up chart, rather than the usual across-sprint velocity chart measured in points. An empty sprint is shown explicitly.

All issue items returned by the project API are included, including archived items and issues from other repositories in this organization project. Pull requests and draft items are excluded. An inaccessible issue in an active sprint fails the run to avoid publishing incomplete totals. Removed project items cannot be recovered from the current API snapshot.

**Completed points:** Credit requires an issue to be closed with reason `COMPLETED`, with its latest closure inside the sprint and no later than the snapshot. Moving a project card to Done without closing its issue does not qualify. Reopened issues and issues closed as `NOT_PLANNED` earn no points. Unestimated issues count in the graph and are labeled in the audit table, but contribute no points. Unknown size labels fail the run so the mapping can be corrected.

Points are divided equally among **all current assignees**. The table lists human members of **The Arcade Collaborator**, including inherited child-team members, except members of the Producer team, and includes zero-point collaborators. Shares for Producers, people outside that team roster, and unassigned issues are reported as uncredited points; they are not redistributed to other assignees. For example, a 5-point issue assigned to two people gives each 2.5 points. Displayed totals round to two decimal places. A missing or unreadable team fails the run; it never falls back to repository collaborators.

**Yesterday's participation:** Each top-level comment and reply in the previous calendar day's generated discussion counts once for its human author through snapshot time, including late replies. Edits, reactions, the opening post, bots and deleted authors do not count. Only members of **The Arcade Collaborator** (including child teams) appear in this table. This includes Producers, because the Producer exclusion applies to completed points. A collaborator with no comments receives zero. If yesterday had no generated discussion, everyone receives **N/A**, rather than being marked absent. The first sprint day does not fall back to an older check-in.

Reports are snapshots of current scope, assignees, sizes and issue states. Reopening/reclosing an issue, changing its Size, or reassigning it can change the next report's historical curve and points attribution. Earlier daily files retain their earlier snapshots. Counts are read over multiple API requests and are not a transactionally frozen view of GitHub.

## Published files and repeat runs

```text
metrics branch
├── README.md                         # Link to latest report
├── daily/
│   └── YYYY-MM-DD.md                  # Outline, discussion links, graph, tables, issue audit
└── charts/
    └── YYYY-MM-DD-ITERATION_ID.svg    # Embedded in that day's Markdown
```

The Markdown includes a date/count table as an accessible alternative to the graph. Keep the corresponding `charts/` files with it when exporting.

One hidden marker in the discussion body identifies each project/date. Reruns reuse the discussion even if its title or category changes; retain that marker. The report for the same date is refreshed and the previous version remains in branch history. Other dates are preserved. Workflow concurrency serializes scheduled and manual runs. Publication is a single commit followed by a non-forced reference update; an external branch conflict fails safely and can be rerun.

The first publication creates `metrics` with a separate history containing only reports and charts. Workflow code remains on the default branch. If discussion creation succeeds but publication fails, a rerun reuses that discussion.

The normal morning run is a partial-day snapshot. There is **no finalization run after a sprint ends**, because inactive days must cancel. For an end-of-sprint update, manually run it late on the last active day, before the iteration ends. Yesterday's attendance is likewise measured at the next active day's run; if no sprint is active on the following day, no attendance report is produced for that last discussion.

## Development checks

The Python script uses only the standard library. Run the offline tests with Python 3.13:

```sh
python -B -m unittest discover -s .github/scripts/tests -v
```

`Test sprint metrics` runs these tests on pull requests and pushes that change the scripts, configuration or metrics workflows. Tests use fake GitHub responses and never create real discussions or commits. They exercise iteration boundaries, size values, point splitting, Producer exclusions, pagination, discussion reuse, participation counting and branch publication.

Ubuntu runners include timezone data. To execute the production script locally on Windows, install the `tzdata` package if `zoneinfo` reports that the configured timezone is unavailable. Local production commands require the same credentials as Actions and can create live discussions/commits; use the offline tests when only checking code.
