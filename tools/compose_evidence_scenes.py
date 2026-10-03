#!/usr/bin/env python3
"""Compose self-contained evidence SVGs without changing puzzle resources.

Requires fonttools only when authoring. Layer sizes/anchors live in the JSON
manifest; hero/evidence destinations come directly from existing POIData.
"""
import copy
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / 'Assets/evidence_assets/svg'
NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', NS)
FONT = TTFont(ROOT / 'Assets/fonts/DejaVuSans.ttf')
GLYPHS = FONT.getGlyphSet()
CMAP = FONT.getBestCmap()


def tag(name):
    return f'{{{NS}}}{name}'


def outline_text(root):
    for parent in list(root.iter()):
        for node in list(parent):
            if node.tag != tag('text'):
                continue
            text = ''.join(node.itertext())
            scale = float(node.get('font-size', 16)) / FONT['head'].unitsPerEm
            advances = [GLYPHS[CMAP.get(ord(c), '.notdef')].width for c in text]
            x, y = float(node.get('x', 0)), float(node.get('y', 0))
            if node.get('text-anchor') == 'middle':
                x -= sum(advances) * scale / 2
            group = ET.Element(tag('g'), {'fill': node.get('fill', '#eee8d7'),
                                         'aria-label': text})
            if node.get('transform'):
                group.set('transform', node.get('transform'))
            for c, advance in zip(text, advances):
                pen = SVGPathPen(GLYPHS)
                GLYPHS[CMAP.get(ord(c), '.notdef')].draw(pen)
                ET.SubElement(group, tag('path'), {
                    'd': pen.getCommands(),
                    'transform': f'translate({x} {y}) scale({scale} {-scale})'})
                x += advance * scale
            parent.insert(list(parent).index(node), group)
            parent.remove(node)


def imported_asset(path, prefix):
    root = ET.parse(PACK / f'{path}.svg').getroot()
    ids = {n.get('id'): prefix + '_' + n.get('id') for n in root.iter() if n.get('id')}
    for n in root.iter():
        for key, value in list(n.attrib.items()):
            if key == 'id':
                n.set(key, ids[value])
            else:
                for old, new in ids.items():
                    value = value.replace(f'url(#{old})', f'url(#{new})')
                    if value == f'#{old}':
                        value = f'#{new}'
                n.set(key, value)
    outline_text(root)
    return root


def point(resource, name):
    block = re.search(r'\[sub_resource[^\n]*id="' + name + r'"\](.*?)(?=\n\[)', resource, re.S).group(1)
    return [float(n) for n in re.search(r'position_uv = Vector2\(([^)]+)\)', block).group(1).split(',')]


def compose(spec):
    resource = (ROOT / spec['resource']).read_text()
    target = ROOT / re.search(r'path="res://([^"\n]+\.svg)"', resource).group(1)
    width, height = spec['size']
    names = re.findall(r'\[sub_resource[^\n]*id="([^"]+)"\](?:(?!\n\[).)*?position_uv', resource, re.S)
    pois = {name.lower(): [v * dimension for v, dimension in zip(point(resource, name), spec['size'])]
            for name in names}
    root = ET.Element(tag('svg'), {'width': str(width), 'height': str(height),
        'viewBox': f'0 0 {width} {height}', 'stroke-linecap': 'round', 'stroke-linejoin': 'round'})
    ET.SubElement(root, tag('title')).text = spec['title']
    ET.SubElement(root, tag('desc')).text = 'Editable scene layers. POI anchors preserved from PanelData.'
    defs = ET.SubElement(root, tag('defs'))
    clip = ET.SubElement(defs, tag('clipPath'), {'id': 'photo_crop'})
    ET.SubElement(clip, tag('rect'), {'width': str(width), 'height': str(height)})
    scene = ET.SubElement(root, tag('g'), {'clip-path': 'url(#photo_crop)'})
    for index, layer in enumerate(spec['layers']):
        group = ET.SubElement(scene, tag('g'), {'id': f'layer_{index:02d}',
            'data-label': layer['label']})
        destination = list(pois[layer['poi']]) if 'poi' in layer else layer.get('at', [0, 0])
        destination = [v + offset for v, offset in zip(destination, layer.get('offset', [0, 0]))]
        scale = layer.get('scale', [1, 1])
        if isinstance(scale, (int, float)):
            scale = [scale, scale]
        else:
            scale = list(scale)
        if layer.get('mirror'):
            scale[0] = -scale[0]
        anchor = layer.get('anchor', [0, 0])
        group.set('transform', f'translate({destination[0]} {destination[1]}) '
                  f'scale({scale[0]} {scale[1]}) translate({-anchor[0]} {-anchor[1]})')
        if 'asset' in layer:
            asset = imported_asset(layer['asset'], f'p{index}')
            for child in asset:
                group.append(copy.deepcopy(child))
        else:
            fragment = ET.fromstring(f'<svg xmlns="{NS}">{layer["svg"]}</svg>')
            outline_text(fragment)
            group.extend(fragment)
    # A muted photographic palette, baked into vector colors (no SVG filters).
    amount = spec['desaturation']
    for node in root.iter():
        for key in ['fill', 'stroke', 'stop-color']:
            color = node.get(key, '')
            if re.fullmatch(r'#[0-9a-fA-F]{6}', color):
                rgb = [int(color[i:i+2], 16) for i in [1, 3, 5]]
                gray = sum(v * weight for v, weight in zip(rgb, [.2126, .7152, .0722]))
                node.set(key, '#' + ''.join(f'{round(v*(1-amount)+gray*amount):02x}' for v in rgb))
    ET.indent(root)
    target.write_text(ET.tostring(root, encoding='unicode') + '\n')
    return target


def main():
    specs = json.loads((ROOT / 'data/art/evidence_compositions.json').read_text())
    for spec in specs:
        print(compose(spec).relative_to(ROOT))


if __name__ == '__main__':
    main()
