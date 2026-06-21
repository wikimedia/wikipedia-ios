# URL schemes

The URL scheme is `wikipedia://`. The following URLs are currently handled:

| Feature            | Format                                     | Example                                                                 |
| ------------------ | -------------------------------------------| ------------------------------------------------------------------------|
| Article            | wikipedia://[site]/wiki/[page_id]          | wikipedia://en.wikipedia.org/wiki/Red                                   |
|                    | https://[[site]/wiki/[page_id]             | https://en.wikipedia.org/wiki/Red                                       |
| Content            | wikipedia://content                        | wikipedia://content/on-this-day/wikipedia.org/en/2024/08/15             |
| Explore            | wikipedia://explore                        |                                                                         |
| History            | wikipedia://history                        |                                                                         |
| Places             | wikipedia://places[?WMFArticleURL=]        | wikipedia://places/?WMFArticleURL=https://en.wikipedia.org/wiki/Dallas  |
| Places(coordinate) | wikipedia://places?lat=..&lon=..[&name=..] | wikipedia://places?lat=52.3676&lon=4.9041&name=Amsterdam                |
| Saved pages        | wikipedia://saved                          |                                                                         |
