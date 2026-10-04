#!/usr/bin/env python3
"""WARNING: this regenerates generic captions, layouts and equal hitbox weights, overwriting the
authored story text (tools/author_content.py) and the enlarged layouts. If you run it, re-run
tools/author_content.py afterwards and restore photo_layouts from git.

Apply supplied stage 1 – 6 PNGs, evidence anchors, layouts and tool loadouts.
Run after build_tutorial_cases.py if regenerating the historical SVG campaign.
"""
import json
import re
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
# (label, POIData.Type, desired visible, u, v, radius). Coordinates are image UVs.
STAGES = [
 ('hero', ['01_Peoples_hero.png'], [[('Hero',0,True,.49,.52,.09)]], ['Torch'], 'Aim the torch at Halcyon.\nSpace switches it on.\nQ/E or wheel aims it.'),
 ('fans', ['02_PeopleCheer.png'], [[('Hero',0,True,.51,.44,.075),('Cheering woman',2,True,.73,.69,.05),('Cheering man',2,True,.85,.72,.05),('Cheering child',2,True,.91,.82,.04),('Accusing man',4,False,.14,.79,.055),('Murderer accusation',9,False,.20,.69,.055)]], ['Torch'], 'Light Halcyon and the\ncheering crowd on the right.\nHide the left accusation.'),
 ('lake', ['03_drowning_girl.png'], [[('Hero',0,True,.66,.46,.085),('Girl on shore',4,False,.11,.83,.055),('Drowning woman',2,False,.29,.74,.055)]], ['Torch','Paperweight'], 'Light Halcyon.\nHide both women.\nDrag the weight for a shadow.'),
 ('peace', ['04_peacekeeper01.png','04_peacekeeper02.png'], [[('Hero',0,True,.65,.30,.055),('Officer',6,True,.59,.73,.05),('Civilian',2,True,.23,.73,.05)],[('Hero',0,True,.53,.61,.07),('Dead civilian',2,True,.79,.92,.065),('Officer',6,False,.34,.85,.05),('Officer dialogue',9,False,.19,.74,.065)]], ['Torch','ReadingGlasses'], 'Light everyone in print 1.\nHide the cop in print 2.\nGlasses redirect the torch.'),
 ('rescue', ['05_burning_building01.png','05_burning_building02.png'], [[('Hero',0,False,.17,.27,.065),('Witness',4,True,.18,.81,.065),('Burning building',7,True,.75,.62,.09)],[('Hero',0,True,.15,.30,.06),('Rescued child',2,True,.21,.29,.035),('Dead witness',2,False,.46,.90,.065)]], ['Torch','MagnifyingGlass'], 'Print 1: witness and fire.\nPrint 2: hero and child.\nUse the lens to focus light.'),
 ('robbery', ['06_bank01.png','06_bank02.png','06_bank03.png','06_bank04.png'], [[('Hero',0,False,.17,.27,.06),('Fleeing man',2,False,.075,.82,.045),('Fleeing woman',2,False,.20,.84,.045),('Fleeing child',2,False,.10,.92,.035),('Car hitting bank',5,True,.61,.57,.055)],[('Hero',0,True,.40,.71,.08),('Dead guard',2,True,.20,.57,.065),('Broken bank vault',5,False,.70,.38,.11)],[('Hero head',0,False,.24,.48,.033),('Hero dialogue',9,False,.17,.36,.065),('Manager',4,True,.55,.64,.075)],[('Hero',0,True,.34,.36,.06),('Falling bill 1',3,False,.50,.43,.028),('Falling bill 2',3,False,.43,.49,.028),('Falling bill 3',3,False,.515,.50,.028),('Falling bill 4',3,False,.67,.56,.028),('Falling bill 5',3,False,.56,.60,.028)]], ['Torch','Torch2'], 'Two torches, four prints.\nChoose what to expose.\nMinimize the damage.'),
]
q = lambda s: json.dumps(s, ensure_ascii=False)
for folder, photos, groups, tools, hint in STAGES:
 base = ROOT/'data/levels'/folder
 for i,(photo,pois) in enumerate(zip(photos,groups),1):
  path=base/f'{i:02}_panel.tres'
  old=path.read_text() if path.exists() else (base/'01_panel.tres').read_text()
  tail=old[old.index('[resource]'):]
  tail=re.sub(r'id = &"[^"]+"',f'id = &"{folder}_{i:02}_panel"',tail,count=1)
  titles={'hero':['THE HERO'],'fans':["THE PEOPLE’S HERO"],'lake':['ABOVE THE LAKE'],'peace':['KEEPING THE PEACE','THE CRIMINAL'],'rescue':['THE FIRE','THE RESCUE'],'robbery':['THE APPROACH','THE VAULT','THE MANAGER','THE GETAWAY']}
  tail=re.sub(r'title = .*', 'title = '+q(titles[folder][i-1]),tail,count=1)
  tail=re.sub(r'pois = .*','pois = Array[ExtResource("poi")](['+', '.join(f'SubResource("Poi{j}")' for j in range(len(pois)))+'])',tail)
  visible=', '.join(p[0].lower() for p in pois if p[2])
  hidden=', '.join(p[0].lower() for p in pois if not p[2])
  spun=f'The print highlights {visible}.'
  damning=f'The print also exposes {hidden}.' if hidden else 'The scene is fully visible.'
  captions={'SPUN':spun,'DAMNING':damning,'MURKY':'The required subjects need clearer lighting.','TAMPERED':'The print is scorched. Prepare a fresh copy.'}
  for key,values in [('captions',captions),('comments',captions),('balloons',{'SPUN':'','DAMNING':'','MURKY':'','TAMPERED':''})]:
   tail=re.sub(rf'^{key} = .*',key+' = '+json.dumps(values,ensure_ascii=False),tail,flags=re.M)
  header='[gd_resource type="Resource" script_class="PanelData" format=3]\n[ext_resource type="Script" path="res://scripts/data/panel_data.gd" id="panel"]\n[ext_resource type="Script" path="res://scripts/data/poi_data.gd" id="poi"]\n'+f'[ext_resource type="Texture2D" path="res://Assets/evidence_assets/stages/{photo}" id="photo"]\n'
  for j,(label,kind,vis,u,v,radius) in enumerate(pois):
   header+=f'[sub_resource type="Resource" id="Poi{j}"]\nscript = ExtResource("poi")\nid = &"{folder}_{i}_{j}"\ntype = {kind}\ndescription = {q(label)}\ndesired = {0 if vis else 1}\nposition_uv = Vector2({u}, {v})\nradius_uv = {radius}\nimportance = 2.0\n'
  path.write_text(header+tail)
 level=base/'level.tres'; data=level.read_text()
 data=re.sub(r'^\[ext_resource type="Resource"[^\n]+id="p\d+"\]\n','',data,flags=re.M)
 refs=''.join(f'[ext_resource type="Resource" path="res://data/levels/{folder}/{i:02}_panel.tres" id="p{i}"]\n' for i in range(1,len(photos)+1))
 data=data.replace('[resource]',refs+'[resource]',1)
 data=re.sub(r'^panels = .*','panels = Array[ExtResource("panel")](['+', '.join(f'ExtResource("p{i}")' for i in range(1,len(photos)+1))+'])',data,flags=re.M)
 centers=[(0,.25)] if len(photos)==1 else [(-1.1,.25),(1.1,.25)] if len(photos)==2 else [(-1.1,-.95),(1.1,-.95),(-1.1,1.45),(1.1,1.45)]
 width=3.65 if len(photos)==1 else 1.95
 rects=[]
 for photo,(x,y) in zip(photos,centers):
  w,h=Image.open(ROOT/'Assets/evidence_assets/stages'/photo).size
  rects.append(f'Rect2({x}, {y}, {width}, {width*h/w:.6f})')
 data=re.sub(r'^photo_layouts = .*','photo_layouts = Array[Rect2](['+', '.join(rects)+'])',data,flags=re.M)
 data=re.sub(r'^required_spun = .*',f'required_spun = {len(photos)}',data,flags=re.M)
 if tools is not None: data=re.sub(r'^available_tools = .*','available_tools = PackedStringArray('+', '.join(q(t) for t in ['CeilingLight', *tools])+')',data,flags=re.M)
 data=re.sub(r'^mechanic_hint = .*','mechanic_hint = '+q(hint).replace('\\','\\\\'),data,flags=re.M)
 positions = {'DeskLamp':(3.8,0,.1),'Torch':(3.7,0,.1),'Torch2':(3.7,0,2.1),'Paperweight':(-3.6,0,1),'Paperweight2':(-3.1,0,2),'Paperweight3':(-3.7,0,2.8),'ReadingGlasses':(-3.5,0,-.8),'MagnifyingGlass':(-3.5,0,.8)}
 data=re.sub(r'^tool_positions = .*', 'tool_positions = {'+', '.join(q(k)+': Vector3('+', '.join(map(str,v))+')' for k,v in positions.items())+'}',data,flags=re.M)
 level.write_text(data)
 reaction=base/'reaction.tres'; reward=100/len(photos)
 reaction.write_text(re.sub(r'^state_weights = .*', 'state_weights = '+json.dumps({'SPUN':reward,'DAMNING':-reward,'MURKY':-reward*.48,'TAMPERED':-reward}),reaction.read_text(),flags=re.M))
print('Updated stages 1–6; stage 6 loadout applied.')

# Make the hitboxes reviewable without opening the resource files.
from PIL import ImageDraw
rows = []
lines = ['# PNG evidence hitboxes', '', 'Green circles in [the preview](previews/stage-photo-hitboxes.png) must be visible; red circles must be hidden. UV coordinates start at the top-left. Each circle supplies nine light samples; their mean determines visibility.', '', '| PNG | Subject | Required | U | V | Radius |', '| --- | --- | --- | ---: | ---: | ---: |']
for folder, photos, groups, *_ in STAGES:
 for photo, pois in zip(photos, groups):
  im = Image.open(ROOT/'Assets/evidence_assets/stages'/photo).convert('RGB').resize((400,400))
  draw = ImageDraw.Draw(im)
  for label, kind, visible, u, v, radius in pois:
   x,y,r = u*400,v*400,radius*400
   color = '#00ff88' if visible else '#ff3355'
   draw.ellipse((x-r,y-r,x+r,y+r),outline=color,width=3)
   draw.text((max(0,x-r),max(0,y-r-12)),label,fill=color,stroke_width=1,stroke_fill='black')
   lines.append(f'| {photo} | {label} | {"Visible" if visible else "Hidden"} | {u} | {v} | {radius} |')
  rows.append((photo,im))
canvas = Image.new('RGB',(1200,((len(rows)+2)//3)*425),'#ddd')
draw = ImageDraw.Draw(canvas)
for i,(name,im) in enumerate(rows):
 x,y=(i%3)*400,(i//3)*425
 draw.text((x+5,y+5),name,fill='black')
 canvas.paste(im,(x,y+25))
canvas.save(ROOT/'docs/previews/stage-photo-hitboxes.png')
(ROOT/'docs/stage-photo-pois.md').write_text('\n'.join(lines)+'\n')
