#!/usr/bin/env python3
"""Serve the column-move chart page and proxy Conduit API calls to Phabricator.

Phabricator does not send CORS headers, so a browser page cannot call its API
directly. This script serves index.html on localhost and forwards
POST /api/<method> to <phabricator>/api/<method>. Nothing is stored; the API
token travels in the request body from your browser to Phabricator.

Usage:
    python3 serve.py [--port 8765] [--phab https://phabricator.wikimedia.org]
"""
import argparse
import os
import urllib.error
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))


def make_handler(phab_url):
    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=HERE, **kwargs)

        def do_POST(self):
            if not self.path.startswith("/api/"):
                self.send_error(404)
                return
            method = self.path[len("/api/"):].split("?", 1)[0]
            if not method.replace(".", "").replace("_", "").isalnum():
                self.send_error(400, "Bad method name")
                return
            length = int(self.headers.get("Content-Length") or 0)
            body = self.rfile.read(length)
            req = urllib.request.Request(
                f"{phab_url}/api/{method}",
                data=body,
                headers={
                    "Content-Type": "application/x-www-form-urlencoded",
                    "User-Agent": "phabricator-column-moves/1.0",
                },
                method="POST",
            )
            try:
                with urllib.request.urlopen(req, timeout=120) as resp:
                    status, payload = resp.status, resp.read()
            except urllib.error.HTTPError as e:
                status, payload = e.code, e.read()
            except Exception as e:  # network errors
                status, payload = 502, str(e).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def log_message(self, fmt, *args):
            # Keep the console quiet apart from errors.
            if args and str(args[1]).startswith(("4", "5")):
                super().log_message(fmt, *args)

    return Handler


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--phab", default="https://phabricator.wikimedia.org")
    args = parser.parse_args()
    server = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(args.phab.rstrip("/")))
    print(f"Open http://127.0.0.1:{args.port}/  (proxying to {args.phab})  Ctrl+C to stop")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
