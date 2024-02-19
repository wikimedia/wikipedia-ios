# URL schemes

The URL scheme is `wikipedia://`. The following URLs are currently handled:

| Feature            | Format                                   | Example                                  |
| ------------------ | ---------------------------------------- | ---------------------------------------- |
| Article            | wikipedia://[site]/wiki/[page_id]        | wikipedia://en.wikipedia.org/wiki/Red    |
|                    | https://[[site]/wiki/[page_id]           | https://en.wikipedia.org/wiki/Red        |
| Content            | wikipedia://content                      |                                          |
| Explore            | wikipedia://explore                      |                                          |
| History            | wikipedia://history                      |                                          |
| Places from article             | wikipedia://places[?WMFArticleURL=]      |    wikipedia://places?WMFArticleURL=https://en.m.wikipedia.org/wiki/Utrecht                                      |
| Places from coordinate             | wikipedia://places[?coordinate=title=]      |    wikipedia://places?coordinate=52.090833,5.121667&title=Utrecht wikipedia://places?coordinate=52.090833,5.121667                                    |
| Saved pages        | wikipedia://saved                        |                                          |
| Search             | wikipedia://[site]/w/index.php?search=[query] | wikipedia://en.wikipedia.org/w/index.php?search=dog |
