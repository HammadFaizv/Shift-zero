#!/usr/bin/env python3
"""Regenerate only the authored protest/factory PNG stages, never stages 1–6."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[1]
def poi(name,kind,visible,u,v,r=.06,weight=3): return (name,kind,visible,u,v,r,weight)
H=lambda u,v:poi('Hero',0,True,u,v,.07,3)
STAGES=[
 ('protest',7,'ASSEMBLY SQUARE',3,False,['Torch','Torch2','Paperweight','ReadingGlasses','ReadingGlasses2'],[
 ('THE GATHERING',[H(.20,.23),poi('Protesters',4,False,.82,.75,.07),poi('Protest signs',9,False,.74,.65,.09),poi('Protesting crowd',4,False,.94,.70,.055)],'Halcyon arrives to help settle the protest.','Citizens protest against Halcyon in Assembly Square.'),
 ('MAKING SPACE',[H(.65,.81),poi('Citizen crushed by car',2,False,.31,.85,.085,6)],'Halcyon creates space between police and citizens.','A citizen lies beneath a car beside Halcyon.'),
 ('WITH THE PEOPLE',[H(.77,.32),poi('Running citizen 1',2,False,.15,.71,.065),poi('Running citizen 2',2,False,.44,.80,.065)],'Humble as ever, Halcyon joins the people’s protest.','Citizens flee as Halcyon flies over the square.'),
 ('HOLDING THE LINE',[H(.24,.42),poi('Police officers',6,True,.68,.61,.11),poi('Nurse',4,False,.70,.87,.075),poi('Dead citizen',2,False,.45,.91,.08,6)],'Halcyon objects as officers prepare to use force.','A nurse tends a dead citizen while Halcyon confronts police.'),
 ('STANDING WATCH',[H(.72,.31),poi('Destroyed car 1',5,False,.22,.83,.09,4),poi('Destroyed car 2',5,False,.72,.91,.10,4),poi('Rubble',5,False,.31,.93,.11,4)],'First City’s protector stands watch over the square.','Destroyed cars and rubble surround Halcyon.'),
 ('KEEPING THE PEACE',[H(.82,.43),poi('Police hitting citizens',6,False,.10,.68,.09,5),poi('Citizen being hit',2,False,.25,.86,.075,5),poi('Fleeing citizen',2,False,.40,.81,.075),poi('Fallen citizen',2,False,.32,.95,.055,5)],'Halcyon brings a steady presence to Assembly Square.','Police strike citizens below Halcyon.'),
 ]),
 ('factory',8,'THE FACTORY',2,True,['Torch','ReadingGlasses','ReadingGlasses2','MagnifyingGlass'],[
 ('THE INSPECTION',[H(.84,.28),poi('Factory',5,True,.33,.68,.14)],'Halcyon arrives for a factory safety inspection.','Halcyon surveys the Reckon factory.'),
 ('FIRE SAFETY',[H(.77,.57),poi('Oil cans',7,False,.22,.67,.12,4),poi('Oil spill',7,False,.33,.84,.10,5),poi('Lighter',7,False,.52,.87,.04,5)],'Halcyon checks the factory for fire hazards.','Oil and a lit lighter sit beside Halcyon inside the factory.'),
 ('AT WORK',[H(.80,.44),poi('Worker 1',2,False,.17,.53,.08,5),poi('Worker 2',2,False,.35,.84,.09,5)],'Halcyon moves swiftly through the factory.','Two workers are caught in the destruction around Halcyon.'),
 ('THE RESPONSE',[H(.30,.43),poi('Dead worker 1',2,False,.59,.84,.12,6),poi('Dead worker 2',2,False,.87,.92,.07,6)],'Halcyon responds as the emergency unfolds.','Dead workers lie on the factory floor beneath Halcyon.'),
 ('ABOVE IT ALL',[H(.67,.33),poi('Ruined factory',5,False,.24,.59,.11,4),poi('Rubble left',5,False,.24,.85,.15,4),poi('Rubble right',5,False,.68,.86,.15,4)],'Halcyon keeps watch over First City.','Halcyon floats above the ruined factory and its rubble.'),
 ])]
q=lambda value:json.dumps(value,ensure_ascii=False)
previews=[]
lines=['# Stage 7–8 evidence targets','','U/V start at the image’s top-left. Visible ≥ 0.55; hidden < 0.30. Each target samples nine points.','','| Stage/photo | Subject | Desired | U | V | Radius |','|---|---|---|---:|---:|---:|']
for folder,number,title,columns,wide,tools,panels in STAGES:
 base=ROOT/'data/levels'/folder;base.mkdir(exist_ok=True)
 sizes=[]
 for i,(name,pois,spun,damning) in enumerate(panels,1):
  filename=f'{number:02}_{folder}{i:02}.png'
  image=Image.open(ROOT/'Assets/evidence_assets/stages'/filename)
  sizes.append(image.size)
  data='[gd_resource type="Resource" script_class="PanelData" format=3]\n'
  data+='[ext_resource type="Script" path="res://scripts/data/panel_data.gd" id="panel"]\n[ext_resource type="Script" path="res://scripts/data/poi_data.gd" id="poi"]\n'
  data+=f'[ext_resource type="Texture2D" path="res://Assets/evidence_assets/stages/{filename}" id="photo"]\n'
  for j,(label,kind,vis,u,v,r,weight) in enumerate(pois):
   data+=f'\n[sub_resource type="Resource" id="Poi{j}"]\nscript = ExtResource("poi")\nid = &"{folder}_{i}_{j}"\ntype = {kind}\ndescription = {q(label)}\ndesired = {0 if vis else 1}\nposition_uv = Vector2({u}, {v})\nradius_uv = {r}\nimportance = {float(weight)}\n'
   if not vis:data+='comment_lines = PackedStringArray('+q(f'Why is {label.lower()} visible in panel {{n}}?')+')\n'
   lines.append(f'| {number}/{i} | {label} | {"Visible" if vis else "Hidden"} | {u} | {v} | {r} |')
  captions={'SPUN':spun,'DAMNING':damning,'MURKY':'The scene needs clearer lighting.','TAMPERED':'This print is scorched. Prepare a fresh copy.'}
  data+='\n[resource]\nscript = ExtResource("panel")\n'+f'id = &"{folder}_{i:02}"\ntitle = {q(name)}\ntexture = ExtResource("photo")\n'
  data+='pois = Array[ExtResource("poi")](['+', '.join(f'SubResource("Poi{j}")' for j in range(len(pois)))+'])\n'
  data+='rule_order = PackedInt32Array(1, 0, 2)\n'
  for field,values in [('captions',captions),('balloons',dict.fromkeys(captions,'')),('sound_effects',{'SPUN':'','DAMNING':'','MURKY':'','TAMPERED':'FZZT!'}),('comments',{'SPUN':f'Another day saved in panel {{n}}!','DAMNING':damning+' Look at panel {n}.','MURKY':'Panel {n} is difficult to read.'})]:data+=field+' = '+q(values)+'\n'
  data+='rationale = '+q(spun)+'\n';(base/f'{i:02}_panel.tres').write_text(data)
  im=image.convert('RGB');im.thumbnail((400,400));tile=Image.new('RGB',(400,425),'#ddd');tile.paste(im,(0,25));draw=ImageDraw.Draw(tile);draw.text((5,5),filename,fill='black')
  for label,kind,vis,u,v,r,weight in pois:
   x,y=u*im.width,25+v*im.height;rx,ry=r*im.width,r*im.height;color='#00ff88' if vis else '#ff3355'
   draw.ellipse((x-rx,y-ry,x+rx,y+ry),outline=color,width=2);draw.text((max(0,x-rx),max(25,y-ry-12)),label,fill=color,stroke_width=1,stroke_fill='black')
  previews.append(tile)
 # Preserve image proportions. Stage 8's last print spans both columns.
 layouts=[]
 if number==7:
  for i,(w,h) in enumerate(sizes):layouts.append(((-1.5,0,1.5)[i%3],(-1.05,.75)[i//3],1.36,1.36*h/w))
 else:
  width=1.30;gap=.16;top=-2.08
  for row in range(2):
   height=max(width*sizes[i][1]/sizes[i][0] for i in range(row*2,row*2+2))
   for i in range(row*2,row*2+2):layouts.append(((-.73,.73)[i%2],top+height/2,width,width*sizes[i][1]/sizes[i][0]))
   top+=height+.12
  width=2.76;height=width*sizes[-1][1]/sizes[-1][0];layouts.append((0,top+height/2,width,height))
 data='[gd_resource type="Resource" script_class="LevelData" format=3]\n'
 for id,path,kind in [('script','scripts/data/level_data.gd','Script'),('panel','scripts/data/panel_data.gd','Script'),('comments',f'data/levels/{folder}/comments.tres','Resource'),('reaction',f'data/levels/{folder}/reaction.tres','Resource')]:data+=f'[ext_resource type="{kind}" path="res://{path}" id="{id}"]\n'
 for i in range(1,len(panels)+1):data+=f'[ext_resource type="Resource" path="res://data/levels/{folder}/{i:02}_panel.tres" id="p{i}"]\n'
 data+='\n[resource]\nscript = ExtResource("script")\n'+f'id = &"{folder}"\ntitle = {q(title)}\ncase_number = {number}\nincident = {q("First City / archive sequence "+str(number))}\n'
 data+='panels = Array[ExtResource("panel")](['+', '.join(f'ExtResource("p{i}")' for i in range(1,len(panels)+1))+'])\n'
 data+='photo_layouts = Array[Rect2](['+', '.join('Rect2('+', '.join(f'{v:.6f}' for v in rect)+')' for rect in layouts)+'])\n'
 data+=f'comic_columns = {columns}\ncomic_wide_last = {str(wide).lower()}\nrequired_spun = {len(panels)}\nceiling_starts_on = false\n'
 data+='available_tools = PackedStringArray('+', '.join(q(t) for t in ['CeilingLight',*tools])+')\n'
 data+='tool_positions = {"Torch": Vector3(3.7,0,-1.0), "Torch2": Vector3(3.7,0,1.5), "Paperweight": Vector3(-3.8,0,1.4), "ReadingGlasses": Vector3(-3.7,0,-1.2), "ReadingGlasses2": Vector3(-3.7,0,0.2), "MagnifyingGlass": Vector3(-3.7,0,1.6)}\n'
 data+='tool_yaws = {"Torch":180.0,"Torch2":180.0,"ReadingGlasses":0.0,"ReadingGlasses2":0.0}\n'
 data+='tool_settings = {"Torch/Beam/VisualLight:spot_angle":16.0,"Torch2/Beam/VisualLight:spot_angle":16.0,"Torch/GameplayLight:intensity":2.0,"Torch2/GameplayLight:intensity":2.0}\n'
 data+='editor_note = '+q('Keep the focus on Halcyon. Make the sequence read clearly.')+'\n'
 data+='mechanic_hint = '+q('Six prints. Two torches.\nUse both pairs of glasses\nand the weight’s shadow.' if number==7 else 'Five prints. One torch.\nRedirect with both glasses.\nFocus weak light with the lens.')+'\n'
 data+='subtitles = '+q({'perfect':'A STEADY HAND FOR FIRST CITY!' if number==7 else 'SAFETY FIRST, HERO ALWAYS!','damning':'AN EVENTFUL DAY IN FIRST CITY','mixed':'HALCYON AT THE SCENE','murky':'A QUIET EDITION','tampered':'A PRINTING MISHAP'})+'\ncomment_templates = ExtResource("comments")\nreaction_config = ExtResource("reaction")\n'
 (base/'level.tres').write_text(data)
 (base/'reaction.tres').write_text('[gd_resource type="Resource" script_class="ReactionConfig" format=3]\n[ext_resource type="Script" path="res://scripts/data/reaction_config.gd" id="script"]\n[resource]\nscript = ExtResource("script")\n')
 comments=(ROOT/'data/levels/greatest/comments.tres').read_text();comments=comments.replace("OUR CITY'S GREATEST HERO!",'KEEPING FIRST CITY SAFE!' if number==7 else 'OUR HERO AT WORK!');(base/'comments.tres').write_text(comments)
canvas=Image.new('RGB',(1200,((len(previews)+2)//3)*425),'#ddd')
for i,im in enumerate(previews):canvas.paste(im,(i%3*400,i//3*425))
canvas.save(ROOT/'docs/previews/stages-7-8-hitboxes.png')
(ROOT/'docs/stages-7-8-pois.md').write_text('\n'.join(lines)+'\n')
print('Authored Stage 7 (6 photographs) and Stage 8 (5 photographs).')
if __name__=='__main__':pass
