#!/usr/bin/env python3
"""Downloads a multilingual seed corpus of Parsoid HTML for oracle round-trip testing.

Uses the public REST API (/api/rest_v1/page/html/{title}), which returns the same
Parsoid HTML the visual editor edits. Writes files plus a manifest recording the
exact revision (etag) of every document, so results are reproducible.
"""

import json
import pathlib
import sys
import time
import urllib.parse
import urllib.request

ORACLE_DIRECTORY = pathlib.Path(__file__).resolve().parent
CORPUS_DIRECTORY = ORACLE_DIRECTORY / "corpus"
MANIFEST_PATH = CORPUS_DIRECTORY / "manifest.json"

USER_AGENT = "WMFVisualEditorKit-oracle-spike (https://github.com/wikimedia/wikipedia-ios)"
MAXIMUM_DOCUMENT_BYTES = 800_000

# Deliberately diverse: LTR/RTL, CJK, language variants, templates/refs-heavy pages.
SEED_TITLES = {
    "en.wikipedia.org": ["Cheese", "Otter", "Saturn", "Haiku", "Federated learning"],
    "pt.wikipedia.org": ["Queijo", "Lontra", "Samba", "Lisboa"],
    "ar.wikipedia.org": ["جبن", "قط", "زحل"],
    "he.wikipedia.org": ["גבינה"],
    "ja.wikipedia.org": ["チーズ", "猫", "俳句"],
    "zh.wikipedia.org": ["乳酪", "貓"],
}


def fetch(host, title):
    encoded_title = urllib.parse.quote(title.replace(" ", "_"), safe="")
    url = f"https://{host}/api/rest_v1/page/html/{encoded_title}"
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=30) as response:
        body = response.read()
        return body, response.headers.get("etag", ""), url


def main():
    CORPUS_DIRECTORY.mkdir(parents=True, exist_ok=True)
    manifest = []
    skipped = []

    for host, titles in SEED_TITLES.items():
        for title in titles:
            try:
                body, etag, url = fetch(host, title)
            except Exception as error:
                print(f"FAILED {host} {title}: {error}", file=sys.stderr)
                skipped.append({"host": host, "title": title, "reason": str(error)})
                continue

            if len(body) > MAXIMUM_DOCUMENT_BYTES:
                print(f"skip (too large, {len(body)} bytes): {host} {title}")
                skipped.append({"host": host, "title": title, "reason": f"too large: {len(body)} bytes"})
                continue

            language = host.split(".")[0]
            safe_title = urllib.parse.quote(title.replace(" ", "_"), safe="")
            file_name = f"{language}__{safe_title}.html"
            (CORPUS_DIRECTORY / file_name).write_bytes(body)
            manifest.append({
                "host": host,
                "title": title,
                "file": file_name,
                "bytes": len(body),
                "etag": etag,
                "url": url,
            })
            print(f"fetched {file_name} ({len(body)} bytes)")
            time.sleep(0.5)

    MANIFEST_PATH.write_text(json.dumps({"documents": manifest, "skipped": skipped}, indent=2, ensure_ascii=False))
    print(f"\n{len(manifest)} documents, {len(skipped)} skipped. Manifest: {MANIFEST_PATH.relative_to(ORACLE_DIRECTORY)}")


if __name__ == "__main__":
    main()
