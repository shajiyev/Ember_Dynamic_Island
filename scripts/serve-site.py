"""Serves the website in site/ at http://localhost:8765 for local checks.

Like `python3 -m http.server`, but every response says `Cache-Control: no-cache`, so the
browser always rechecks the files and never mixes a new page with an old stylesheet.
Run from the repository root: python3 scripts/serve-site.py
"""

import functools
import http.server

PORT = 8765


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


if __name__ == "__main__":
    handler = functools.partial(NoCacheHandler, directory="site")
    with http.server.ThreadingHTTPServer(("", PORT), handler) as server:
        print(f"Serving site/ at http://localhost:{PORT}")
        server.serve_forever()
