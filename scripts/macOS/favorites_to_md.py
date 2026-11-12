"""Convert a Netscape-format bookmarks export (Edge favorites) to Markdown.

Usage: python3 -I favorites_to_md.py <source.html> <target.md>

Folders become headings (nested folders go one level deeper, capped at H6),
links become bullets. Icons and date attributes are dropped.
"""
import os
import sys
from datetime import date
from html.parser import HTMLParser
from urllib.parse import quote


class BookmarkParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = {"name": None, "children": []}
        self.stack = [self.root]
        self.last_folder = self.root  # the first <DL> is the root list
        self.capture = None  # "h3" or "a" while inside that element
        self.text = ""
        self.href = ""

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        if tag == "h3":
            self.capture = "h3"
            self.text = ""
        elif tag == "a":
            self.capture = "a"
            self.text = ""
            self.href = dict(attrs).get("href") or ""
        elif tag == "dl":
            self.stack.append(self.last_folder)
            self.last_folder = None

    def handle_data(self, data):
        if self.capture:
            self.text += data

    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag == "h3":
            folder = {"name": self.text.strip(), "children": []}
            self.stack[-1]["children"].append(folder)
            self.last_folder = folder
            self.capture = None
        elif tag == "a":
            self.stack[-1]["children"].append(
                {"title": self.text.strip(), "href": self.href}
            )
            self.capture = None
        elif tag == "dl":
            self.stack.pop()
            self.last_folder = None


def escape_text(text):
    for ch in "\\[]<>*_`":
        text = text.replace(ch, "\\" + ch)
    return text


def escape_url(href):
    # Keep existing %XX escapes; encode spaces, parentheses and other characters
    # that would break the Markdown link destination.
    return quote(href, safe=":/?#[]@!$&'*+,;=%~-._")


def render(node, depth, out, counts):
    for child in node["children"]:
        if "children" in child:
            counts["folders"] += 1
            level = min(2 + depth, 6)
            out.append("")
            out.append(f"{'#' * level} {escape_text(child['name'] or 'Unnamed folder')}")
            out.append("")
            render(child, depth + 1, out, counts)
        else:
            counts["links"] += 1
            title = child["title"] or child["href"]
            out.append(f"- [{escape_text(title)}]({escape_url(child['href'])})")


def main(source, target):
    parser = BookmarkParser()
    with open(source, encoding="utf-8") as f:
        parser.feed(f.read())
    parser.close()

    counts = {"folders": 0, "links": 0}
    body = []
    render(parser.root, 0, body, counts)

    lines = [
        "# Edge Browser Favorites",
        "",
        f"Converted from `{os.path.basename(source)}` on {date.today().isoformat()}. "
        f"{counts['links']} links in {counts['folders']} folders.",
    ]
    lines.extend(body)
    text = "\n".join(lines).rstrip("\n") + "\n"

    with open(target, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"wrote {target}: {counts['links']} links, {counts['folders']} folders")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: favorites_to_md.py <source.html> <target.md>")
    main(sys.argv[1], sys.argv[2])
