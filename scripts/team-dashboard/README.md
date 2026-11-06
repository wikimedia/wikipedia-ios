# Team delivery dashboard

One page that shows, per engineer and per month:

- **Code review (GitHub):** inline review comments on the pull requests each engineer opened,
  split between human and automated reviewers.
- **Column moves (Phabricator):** how often tasks move between similarly named sprint-board
  columns (e.g. "In progress" → "Code review") across sprint boards.
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
2. **Code review (GitHub)** tab: paste a GitHub token, set the repository and date range, and
   click *Fetch from GitHub*. Use *Export JSON* / *Import JSON* to keep or share a fetch.
3. **Column moves (Phabricator)** tab: paste a Conduit API token, search for the sprint boards
   (comma-separate several searches; open milestones are included and sorted by date), tick the
   boards, and click *Load column moves*. Then set the "from"/"to" column names. Matching ignores
   case and punctuation, commas separate alternatives, and `/regex/` works.
4. **Overview** tab: uses the current data and filters from the other two tabs. When GitHub data
   is loaded, the overview covers the same date range.

Review comments are counted in the month the pull request was opened; column moves in the month
the move happened. Tokens can optionally be remembered in the browser's local storage.
