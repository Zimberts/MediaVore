#!/usr/bin/env python3
"""Build a static HTML gallery from the output of test/screenshots/capture_screens.dart.

Usage: build_gallery.py OUT_DIR [--inline]

OUT_DIR holds one sub-directory per run (e.g. ``fr-light``, ``fr-dark``), each
with PNGs and a ``manifest.json``. Writes ``OUT_DIR/index.html``. With
``--inline`` every image is embedded as a data URI, giving a single
self-contained file. Standard library only.
"""

from __future__ import annotations

import base64
import html
import json
import sys
from pathlib import Path

THEME_LABEL = {"light": "Clair", "dark": "Sombre"}


def load_runs(out: Path) -> list[tuple[str, dict]]:
    runs = []
    manifests = sorted(
        out.glob("*/manifest.json"), key=lambda p: ("dark" in p.parent.name, p)
    )
    for manifest in manifests:
        runs.append((manifest.parent.name, json.loads(manifest.read_text("utf-8"))))
    if not runs:
        sys.exit(f"No */manifest.json under {out}: run tool/screenshots.sh first.")
    return runs


def src(out: Path, rel: str, inline: bool) -> str:
    if not inline:
        return html.escape(rel)
    data = base64.b64encode((out / rel).read_bytes()).decode()
    return f"data:image/png;base64,{data}"


def render(out: Path, runs: list[tuple[str, dict]], inline: bool) -> str:
    esc = html.escape
    tabs, panels = [], []
    for i, (name, m) in enumerate(runs):
        label = f"{m['locale'].upper()} · {THEME_LABEL.get(m['theme'], m['theme'])}"
        tabs.append(
            f'<button role="tab" data-run="{esc(name)}" '
            f'aria-selected="{str(i == 0).lower()}">{esc(label)}</button>'
        )
        shots = "\n".join(
            f'<figure><div class="phone"><img loading="lazy" '
            f'src="{src(out, f"{name}/{s["file"]}", inline)}" alt="{esc(s["title"])}"></div>'
            f"<figcaption>{esc(s['title'])}</figcaption></figure>"
            for s in m["screens"]
        )
        panels.append(
            f'<section class="run" data-run="{esc(name)}"'
            f'{"" if i == 0 else " hidden"}><div class="grid">{shots}</div></section>'
        )

    _, first = runs[0]
    cards = "\n".join(
        f'<article class="film"><img loading="lazy" '
        f'src="{src(out, f"{runs[0][0]}/{c["poster"]}", inline)}" alt="">'
        f"<div><h3>{esc(c['title'])}</h3>"
        f"<p class=\"meta\">{c['year']} · {'Série' if c['type'] == 'tv' else 'Film'}"
        f" · ★ {c['rating']:.1f} · {esc(', '.join(c['genres']))}</p>"
        f"<p>{esc(c['overview'])}</p></div></article>"
        for c in first.get("catalog", [])
    )
    w, h = first["size"]
    return TEMPLATE.format(
        tabs="".join(tabs),
        panels="\n".join(panels),
        cards=cards,
        count=len(first["screens"]),
        films=len(first.get("catalog", [])),
        ratio=f"{w} / {h}",
    )


TEMPLATE = """<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="claude:viewport-fit-sides" content="cover">
<title>MediaVore · Écrans</title>
<style>
:root {{
  --bg: #f6f5fa; --fg: #1d1b20; --muted: #625b71; --card: #fff;
  --accent: #6750a4; --line: #e3dfec; --frame: #1d1b20;
}}
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{ --bg: #141218; --fg: #e6e0e9; --muted: #cac4d0;
    --card: #1d1b20; --accent: #d0bcff; --line: #2b2930; color-scheme: dark; }}
}}
:root[data-theme="dark"] {{ --bg: #141218; --fg: #e6e0e9; --muted: #cac4d0;
  --card: #1d1b20; --accent: #d0bcff; --line: #2b2930; color-scheme: dark; }}
* {{ box-sizing: border-box; }}
body {{ margin: 0; background: var(--bg); color: var(--fg);
  font: 15px/1.5 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }}
header, main {{ max-width: 1280px; margin: 0 auto;
  padding-left: max(16px, env(safe-area-inset-left, 0px));
  padding-right: max(16px, env(safe-area-inset-right, 0px)); }}
header {{ padding-top: 40px; }}
h1 {{ margin: 0 0 4px; font-size: 28px; }}
h2 {{ margin: 48px 0 16px; font-size: 20px; }}
.sub {{ color: var(--muted); margin: 0 0 24px; }}
[role=tablist] {{ display: flex; gap: 8px; flex-wrap: wrap; }}
[role=tab] {{ border: 1px solid var(--line); background: var(--card); color: var(--fg);
  padding: 8px 16px; border-radius: 999px; font: inherit; cursor: pointer; }}
[role=tab][aria-selected=true] {{ background: var(--accent); color: var(--bg);
  border-color: var(--accent); }}
.grid {{ display: grid; gap: 28px 20px; margin-top: 24px;
  grid-template-columns: repeat(auto-fill, minmax(min(220px, 100%), 1fr)); }}
figure {{ margin: 0; }}
.phone {{ border-radius: 28px; overflow: hidden; border: 6px solid var(--frame);
  aspect-ratio: {ratio}; background: #000; box-shadow: 0 8px 24px #0002; }}
.phone img {{ width: 100%; height: 100%; display: block; cursor: zoom-in; }}
figcaption {{ text-align: center; margin-top: 8px; color: var(--muted); }}
.films {{ display: grid; gap: 16px; grid-template-columns: repeat(auto-fill, minmax(min(300px, 100%), 1fr)); }}
.film {{ display: flex; gap: 12px; background: var(--card); border: 1px solid var(--line);
  border-radius: 12px; padding: 12px; }}
.film img {{ width: 72px; height: 108px; border-radius: 6px; flex: none; }}
.film > div {{ min-width: 0; }}
.film h3 {{ margin: 0; font-size: 15px; }}
.film p {{ margin: 4px 0 0; font-size: 13px; }}
.film .meta {{ color: var(--muted); }}
footer {{ color: var(--muted); font-size: 13px; padding: 40px 16px; text-align: center; }}
dialog {{ border: 0; padding: 0; background: transparent; max-height: 95vh; }}
dialog img {{ max-height: 92vh; max-width: 92vw; border-radius: 20px; display: block; }}
dialog::backdrop {{ background: rgb(0 0 0 / .8); }}
</style>
</head>
<body>
<header>
  <h1>MediaVore</h1>
  <p class="sub">{count} écrans de l'application, générés hors ligne avec {films} films et séries d'exemple.</p>
  <div role="tablist">{tabs}</div>
</header>
<main>
{panels}
<h2>Catalogue d'exemple</h2>
<div class="films">{cards}</div>
</main>
<footer>Données d'illustration (notes, durées, disponibilités arrondies ou fictives).
Affiches générées localement, aucune image TMDB.</footer>
<dialog id="zoom"><img alt=""></dialog>
<script>
const tabs = document.querySelectorAll('[role=tab]');
tabs.forEach(t => t.addEventListener('click', () => {{
  tabs.forEach(o => o.setAttribute('aria-selected', o === t));
  document.querySelectorAll('.run').forEach(r => r.hidden = r.dataset.run !== t.dataset.run);
}}));
const zoom = document.getElementById('zoom');
document.querySelectorAll('.phone img').forEach(img => img.addEventListener('click', () => {{
  zoom.querySelector('img').src = img.src; zoom.showModal();
}}));
zoom.addEventListener('click', () => zoom.close());
</script>
</body>
</html>
"""


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        sys.exit(__doc__)
    out = Path(args[0])
    inline = "--inline" in sys.argv
    page = render(out, load_runs(out), inline)
    target = out / ("index-inline.html" if inline else "index.html")
    target.write_text(page, "utf-8")
    print(target)


if __name__ == "__main__":
    main()
