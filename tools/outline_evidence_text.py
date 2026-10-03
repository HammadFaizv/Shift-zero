#!/usr/bin/env python3
"""Convert evidence SVG lettering to paths (Godot's SVG importer omits text).

Requires fonttools. Uses the included OFL-licensed Caveat font.
"""
from pathlib import Path
import xml.etree.ElementTree as ET
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

root = Path(__file__).resolve().parents[1]
font = TTFont(root / "Assets/fonts/Caveat.ttf")
glyphs = font.getGlyphSet()
cmap = font.getBestCmap()
units = font["head"].unitsPerEm
namespace = "http://www.w3.org/2000/svg"
ET.register_namespace("", namespace)

for file in (root / "Assets/evidence/bank").glob("*.svg"):
    tree = ET.parse(file)
    for parent in tree.getroot().iter():
        for element in list(parent):
            if element.tag != "{" + namespace + "}text":
                continue
            text = "".join(element.itertext())
            scale = float(element.get("font-size", 16)) / units
            advances = [glyphs[cmap.get(ord(char), ".notdef")].width for char in text]
            x = float(element.get("x", 0))
            y = float(element.get("y", 0))
            if element.get("text-anchor") == "middle":
                x -= sum(advances) * scale / 2
            group = ET.Element("{" + namespace + "}g", {"fill": element.get("fill", "#303944"), "aria-label": text})
            for char, advance in zip(text, advances):
                pen = SVGPathPen(glyphs)
                glyphs[cmap.get(ord(char), ".notdef")].draw(pen)
                ET.SubElement(group, "{" + namespace + "}path", {"d": pen.getCommands(), "transform": f"translate({x} {y}) scale({scale} {-scale})"})
                x += advance * scale
            parent.insert(list(parent).index(element), group)
            parent.remove(element)
    tree.write(file, encoding="unicode")
    print(file.name)
