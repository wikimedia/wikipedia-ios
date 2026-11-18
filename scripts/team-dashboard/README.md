# Team delivery dashboard

One page that shows, per engineer and per month:

- **Code review (GitHub):** inline review comments on the pull requests each engineer opened,
  split between human and automated reviewers.
- **Column moves (Phabricator):** how often tasks move between similarly named sprint-board
  columns (e.g. "In progress" → "Code review") across sprint boards.
- **Output:** cycle time and throughput by assignee, by week or month.
- **Overview:** both side by side: a comparison table and a monthly chart (review comments as
  bars, column moves as a line).

## Run

```bash
python3 scripts/team-dashboard/serve.py
```

Then open http://127.0.0.1:8765/. Only Python 3 is needed.

`serve.py` is required for the Phabricator tab, because Phabricator's API sends no CORS headers.
It only listens on 127.0.0.1 and forwards `/api/*` to Phabricator (`--phab <url>` for another
instance). GitHub calls go straight from the browser to api.github.com.

## Use

1. **Team** (top of the page): one person per line, `Name | GitHub login | Phabricator username`.
   Leave a column blank if someone isn't on that system.
2. **Code review (GitHub)** tab: paste a GitHub token, set one or more repositories (comma
   separated, e.g. `wikimedia/wikipedia-ios, wikimedia/apps-android-wikipedia`) and the date range,
   and click *Fetch from GitHub*. With several repositories, a *Repo* filter appears; it also
   applies to the overview. Use *Export JSON* / *Import JSON* to keep or share a fetch.
3. **Column moves (Phabricator)** tab: paste a Conduit API token, search for the sprint boards
   (comma-separate several searches; open milestones are included and sorted by date), tick the
   boards, and click *Load column moves*. The project list, ticks and everything fetched are saved in
   the browser (IndexedDB), so a reload shows the charts without any queries. *Load column moves*
   then refreshes incrementally: it lists each board's tasks but only re-fetches the history of tasks
   that are new or modified. *Clear saved data* forces a full fetch next time. Tick or untick engineers to include or exclude them from
   every chart, total and table (the choice is remembered). The per-month chart can show engineers
   side by side, stacked, or as a single team total.
   *Count* can be moves, tasks closed (tasks on the selected boards closed in the date range,
   credited to the assignee; Resolved only by default), or moves per task (an engineer's matching
   moves ÷ their tasks closed). A per-engineer table shows all three, with a team row. A separate
   *Moves per task by month* chart always shows a monthly rate per engineer and for the team, dividing
   each month's matching moves by one of: the distinct tasks moved that month, the tasks open at any
   point that month (credited to the assignee), the tasks closed that month, or all column moves that
   month (*Share of all moves*, a percentage). Then set the "from"/"to" column names. A name matches the
   whole column name, ignoring case, spaces and punctuation (`signoff` matches "Sign-off" but not
   "Design signoff"); `*` is a wildcard (`*code review*`), commas separate alternatives, and
   `/regex/` works.
4. **Output** tab: built from the Phabricator data and ticked engineers on the Column moves tab
   (no extra queries). *Cycle time* runs from a task's first move into "Doing" to its next move into
   "Signoff" or "Ready for PM Signoff" (both editable). *Throughput by assignee* counts tasks that
   first reached signoff, in tasks or points (the larger of Story Points and Final Story Points).
   Group by week (starting Monday 00:00 UTC) or by month (UTC).
5. **Overview** tab: uses the current data and filters from the other two tabs. When GitHub data
   is loaded, the overview covers the same date range.

Review comments are counted in the month the pull request was opened; column moves in the month
the move happened. Tokens can optionally be remembered in the browser's local storage.
