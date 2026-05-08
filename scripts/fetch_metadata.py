#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["requests", "beautifulsoup4", "lxml", "playwright", "googlenewsdecoder"]
# ///
"""Fetch og: meta tags for each mention URL and cache to data/metadata.json.

Reads URLs from curated.json + discoveries.json, fetches HTML for any URL not
already cached (and retries previously errored ones), parses Open Graph and
Twitter Card meta tags, and persists an array sorted by URL.

Fallback chain:
  1. requests with browser User-Agent
  2. requests with Twitterbot User-Agent (recovers some paywalled previews)
  3. Playwright headless Chromium (only when --playwright is passed; required
     to handle Google News consent-screen redirects, since those URLs only
     resolve via JS)

CI normally runs without --playwright; refresh the cache locally with
--playwright when new Google News URLs appear in discoveries.json.
"""

import argparse
import json
import sys
from pathlib import Path

import requests
from bs4 import BeautifulSoup

DATA_DIR = Path("data")
METADATA_PATH = DATA_DIR / "metadata.json"
INPUT_FILES = [DATA_DIR / "curated.json", DATA_DIR / "discoveries.json"]

TIMEOUT = 30
BASE_HEADERS = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}
USER_AGENTS = [
    (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    ),
    "Twitterbot/1.0",
]

META_PICK_JS = """() => {
    const pick = (...names) => {
        for (const n of names) {
            const el = document.querySelector(
                `meta[property="${n}"], meta[name="${n}"]`
            );
            if (el && el.getAttribute('content')) return el.getAttribute('content').trim();
        }
        return null;
    };
    return {
        og_title: pick('og:title', 'twitter:title'),
        og_description: pick('og:description', 'twitter:description', 'description'),
        og_image: pick('og:image', 'og:image:url', 'twitter:image', 'twitter:image:src'),
        og_site_name: pick('og:site_name'),
    };
}"""


def load_cache() -> dict[str, dict]:
    if not METADATA_PATH.exists():
        return {}
    records = json.loads(METADATA_PATH.read_text())
    return {r["url"]: r for r in records}


def save_cache(cache: dict[str, dict]) -> None:
    records = sorted(cache.values(), key=lambda r: r["url"])
    METADATA_PATH.write_text(json.dumps(records, indent=2, ensure_ascii=False) + "\n")


def collect_urls() -> list[str]:
    seen: set[str] = set()
    urls: list[str] = []
    for path in INPUT_FILES:
        if not path.exists():
            continue
        for item in json.loads(path.read_text()):
            url = item.get("url")
            if url and url not in seen:
                seen.add(url)
                urls.append(url)
    return urls


def parse_meta(html: str) -> dict[str, str | None]:
    soup = BeautifulSoup(html, "lxml")

    def pick(*names: str) -> str | None:
        for name in names:
            tag = soup.find("meta", attrs={"property": name}) or soup.find(
                "meta", attrs={"name": name}
            )
            if tag and tag.get("content"):
                value = tag["content"].strip()
                if value:
                    return value
        return None

    return {
        "og_title": pick("og:title", "twitter:title"),
        "og_description": pick("og:description", "twitter:description", "description"),
        "og_image": pick("og:image", "og:image:url", "twitter:image", "twitter:image:src"),
        "og_site_name": pick("og:site_name"),
    }


def is_useless_result(meta: dict, final_url: str) -> bool:
    """Detect generic landing-page metadata (e.g. Google News consent page,
    publisher home redirect) so we fall through to a stronger fetcher."""
    if "consent." in final_url or "news.google.com" in final_url:
        return True
    title = (meta.get("og_title") or "").strip()
    if title in {"Google News", "DER SPIEGEL | Online-Nachrichten"}:
        return True
    return False


def image_is_reachable(image_url: str) -> bool:
    """HEAD-check an og:image URL — some publishers expose URLs that 404 on
    their CDN. We discard those so the override path or placeholder kicks in."""
    try:
        resp = requests.head(
            image_url,
            headers={**BASE_HEADERS, "User-Agent": USER_AGENTS[0]},
            timeout=10,
            allow_redirects=True,
        )
        if resp.status_code == 200:
            return True
        if resp.status_code in (405, 403):
            resp = requests.get(
                image_url,
                headers={**BASE_HEADERS, "User-Agent": USER_AGENTS[0]},
                timeout=15,
                stream=True,
            )
            return resp.status_code == 200
    except Exception:
        pass
    return False


def resolve_google_news(url: str) -> str | None:
    """Decode a news.google.com redirect URL to the real destination."""
    from googlenewsdecoder import gnewsdecoder

    try:
        result = gnewsdecoder(url)
        if result.get("status") and result.get("decoded_url"):
            return result["decoded_url"]
    except Exception:
        pass
    return None


def fetch_via_requests(url: str) -> dict | None:
    """Try basic HTTP fetch with each UA. Returns a record on success, None when
    we should fall through to a stronger fetcher (or no usable response)."""
    fetch_url = url
    if "news.google.com" in url:
        decoded = resolve_google_news(url)
        if not decoded:
            return None
        fetch_url = decoded

    last_error: str | None = None
    for ua in USER_AGENTS:
        try:
            resp = requests.get(
                fetch_url,
                headers={**BASE_HEADERS, "User-Agent": ua},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            resp.raise_for_status()
            meta = parse_meta(resp.text)
            if meta["og_image"] and not image_is_reachable(meta["og_image"]):
                meta["og_image"] = None
            if (meta["og_image"] or meta["og_title"]) and not is_useless_result(meta, resp.url):
                return {"url": url, "final_url": resp.url, **meta, "via": "requests"}
        except Exception as exc:
            last_error = str(exc)[:300]
    return None if last_error is None else {"url": url, "error": last_error}


def fetch_via_playwright(urls: list[str]) -> dict[str, dict]:
    """Resolve a batch of URLs through a headless browser. Skips consent screens
    by waiting for the JS redirect to complete."""
    from playwright.sync_api import sync_playwright

    results: dict[str, dict] = {}
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(
            user_agent=USER_AGENTS[0],
            locale="en-US",
            timezone_id="America/New_York",
        )
        for url in urls:
            page = ctx.new_page()
            try:
                page.goto(url, wait_until="domcontentloaded", timeout=30_000)
                page.wait_for_timeout(4000)
                # If still stuck on a consent screen, give it a moment longer
                if "consent." in page.url:
                    page.wait_for_timeout(4000)
                final_url = page.url
                meta = page.evaluate(META_PICK_JS)
                if (meta.get("og_image") or meta.get("og_title")) and not is_useless_result(meta, final_url):
                    results[url] = {
                        "url": url,
                        "final_url": final_url,
                        **meta,
                        "via": "playwright",
                    }
                else:
                    results[url] = {
                        "url": url,
                        "final_url": final_url,
                        "error": f"no og: tags after browser load (title: {page.title()[:80]!r})",
                    }
            except Exception as exc:
                results[url] = {"url": url, "error": str(exc)[:300]}
            finally:
                page.close()
        browser.close()
    return results


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--playwright",
        action="store_true",
        help="Use Playwright as a final fallback (handles Google News consent redirects).",
    )
    args = parser.parse_args()

    cache = load_cache()
    urls = collect_urls()

    def stale(record: dict | None) -> bool:
        if not record:
            return True
        if record.get("error"):
            return True
        if not record.get("og_image"):
            return True
        return is_useless_result(record, record.get("final_url") or "")

    needs_fetch: list[str] = [u for u in urls if stale(cache.get(u))]

    requests_recovered = 0
    for url in needs_fetch:
        print(f"  requests {url}", file=sys.stderr)
        result = fetch_via_requests(url)
        if result is not None:
            cache[url] = result
            requests_recovered += 1
        else:
            cache.setdefault(url, {"url": url, "error": "no metadata via requests"})
        save_cache(cache)

    playwright_recovered = 0
    if args.playwright:
        still_missing = [u for u in urls if stale(cache.get(u))]
        if still_missing:
            print(f"  playwright batch: {len(still_missing)} URLs", file=sys.stderr)
            for url, result in fetch_via_playwright(still_missing).items():
                if not result.get("error"):
                    playwright_recovered += 1
                cache[url] = result
            save_cache(cache)

    save_cache(cache)
    errors = sum(1 for r in cache.values() if r.get("error"))
    with_image = sum(1 for r in cache.values() if r.get("og_image"))
    print(
        f"metadata: {len(cache)} cached, {with_image} with image, {errors} errored "
        f"(requests recovered {requests_recovered}, playwright recovered {playwright_recovered})",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
