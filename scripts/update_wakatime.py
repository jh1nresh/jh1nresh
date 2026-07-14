#!/usr/bin/env python3
"""Replace the profile README WakaTime section with seven-day language stats."""

from __future__ import annotations

import base64
import datetime as dt
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

API_URL = "https://wakatime.com/api/v1/users/current/stats/last_7_days"
START_MARKER = "<!--START_SECTION:waka-->"
END_MARKER = "<!--END_SECTION:waka-->"
MAX_LANGUAGES = 8
BAR_WIDTH = 20


def fetch_stats(api_key: str) -> dict[str, Any]:
    token = base64.b64encode(api_key.encode("utf-8")).decode("ascii")
    request = urllib.request.Request(
        API_URL,
        headers={
            "Accept": "application/json",
            "Authorization": f"Basic {token}",
            "User-Agent": "jh1nresh-profile/1.0",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            status = response.status
            payload = json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"WakaTime returned HTTP {error.code}") from error
    except urllib.error.URLError as error:
        raise RuntimeError(f"WakaTime request failed: {error.reason}") from error

    if status == 202:
        raise RuntimeError("WakaTime is refreshing stats; run the workflow again later")
    if status != 200:
        raise RuntimeError(f"WakaTime returned unexpected HTTP {status}")

    data = payload.get("data")
    if not isinstance(data, dict):
        raise RuntimeError("WakaTime response does not contain a stats object")
    return data


def clean_text(value: Any, fallback: str) -> str:
    text = " ".join(str(value or "").split())
    return text[:40] or fallback


def render_bar(percent: float) -> str:
    bounded = min(100.0, max(0.0, percent))
    filled = round((bounded / 100.0) * BAR_WIDTH)
    return "#" * filled + "." * (BAR_WIDTH - filled)


def display_date(data: dict[str, Any], fallback: dt.date | None = None) -> str:
    raw_end = str(data.get("end") or "")
    try:
        return dt.datetime.fromisoformat(raw_end.replace("Z", "+00:00")).date().isoformat()
    except ValueError:
        return (fallback or dt.datetime.now(dt.timezone.utc).date()).isoformat()


def render_section(data: dict[str, Any], fallback_date: dt.date | None = None) -> str:
    raw_languages = data.get("languages")
    languages = raw_languages if isinstance(raw_languages, list) else []
    ranked = sorted(
        (item for item in languages if isinstance(item, dict)),
        key=lambda item: float(item.get("total_seconds") or 0),
        reverse=True,
    )[:MAX_LANGUAGES]

    total = clean_text(data.get("human_readable_total"), "no tracked activity")
    lines = [f"**Last 7 days:** {total}", "", "```text"]

    if not ranked:
        lines.append("No language activity was recorded.")
    else:
        names = [clean_text(item.get("name"), "Other") for item in ranked]
        width = max(len(name) for name in names)
        for name, item in zip(names, ranked):
            percent = float(item.get("percent") or 0)
            duration = clean_text(item.get("text"), "0 secs")
            lines.append(
                f"{name:<{width}}  {duration:>14}  {percent:5.1f}%  {render_bar(percent)}"
            )

    lines.extend(
        [
            "```",
            "",
            f"_Updated {display_date(data, fallback_date)} from WakaTime. Project names are intentionally excluded._",
        ]
    )
    return "\n".join(lines)


def replace_section(readme: str, section: str) -> str:
    pattern = re.compile(
        rf"{re.escape(START_MARKER)}[\s\S]*?{re.escape(END_MARKER)}"
    )
    if len(pattern.findall(readme)) != 1:
        raise RuntimeError("README must contain exactly one WakaTime marker pair")
    replacement = f"{START_MARKER}\n{section}\n{END_MARKER}"
    return pattern.sub(lambda _match: replacement, readme)


def main() -> int:
    api_key = os.environ.get("WAKATIME_API_KEY", "").strip()
    if not api_key:
        print("WAKATIME_API_KEY is required", file=sys.stderr)
        return 2

    readme_path = Path(__file__).resolve().parents[1] / "README.md"
    updated = replace_section(
        readme_path.read_text(encoding="utf-8"),
        render_section(fetch_stats(api_key)),
    )
    readme_path.write_text(updated, encoding="utf-8")
    print("WakaTime section updated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
