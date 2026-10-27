# src/game.html → index.html (GitHub Pages에 올라가는 완성 페이지)
# 사용법: python3 tools/build.py
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
src = (ROOT / "src" / "game.html").read_text(encoding="utf-8")
head, body = src.split("<!--BODY-->", 1)

TITLE = "딸기 습격"
DESC = "꼬마 소인이 되어 인간이 돌아오기 전에 딸기 디저트를 해치우는 3D 웹 게임. 설치 없이 휴대폰과 PC에서 무료로."

page = f"""<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="description" content="{DESC}">
<meta property="og:type" content="website">
<meta property="og:title" content="{TITLE}">
<meta property="og:description" content="{DESC}">
<meta property="og:locale" content="ko_KR">
<meta name="twitter:card" content="summary">
{head.strip()}
</head>
<body>
{body.strip()}
</body>
</html>
"""
(ROOT / "index.html").write_text(page, encoding="utf-8")
print("index.html", len(page.encode()), "bytes")
