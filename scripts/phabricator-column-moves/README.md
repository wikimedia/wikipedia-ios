# Phabricator column moves

Charts how many times tasks moved between similarly named columns
(e.g. "In progress" → "Code review") across a set of sprint boards, per user.

## Run

```bash
python3 scripts/phabricator-column-moves/serve.py
```

Open http://127.0.0.1:8765/ and:

1. Paste a Conduit API token (Phabricator → Settings → Conduit API Tokens).
2. Search for the sprint boards (e.g. "iOS Sprint"), optionally narrow with a regex, and tick the ones you want.
3. Click **Load column moves**. This fetches every task on those boards and its history.
4. Enter usernames and the "from"/"to" column names, then **Update chart**.

Column matching ignores case and punctuation, so `code review` matches
"Code Review" and "In code-review". Use commas for alternatives, or `/regex/`.
Leave "from" blank to count any move into the "to" column, including a task being added to the board.

Moves can be attributed to the person who moved the card or to the task's
current assignee, and counted as moves or as distinct tasks. The
"Column transitions seen" table lists the actual column names, so you can see what to filter on.

`serve.py` is needed because Phabricator's API sends no CORS headers. It only
listens on 127.0.0.1 and forwards `/api/*` calls. Use `--phab <url>` to point it at another Phabricator instance.
