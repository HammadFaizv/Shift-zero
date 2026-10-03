#!/usr/bin/env python3
"""Author the seven tutorial cases, their POIs and SVG composition manifest.

Run compose_evidence_scenes.py after this tool to rebuild textures.
"""
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / 'Assets/evidence_assets/svg'
TYPES = {'HERO':0,'VICTIM':2,'MONEY':3,'WITNESS':4,'DAMAGE':5,'POLICE':6,'FIRE':7,'SPEECH_BUBBLE':9}


def q(value): return json.dumps(value,ensure_ascii=False)
def dictionary(values): return '{'+', '.join(q(k)+': '+q(v) for k,v in values.items())+'}'
def poi(name,kind,x,y,visible=False,radius=.055):
    return dict(name=name,kind=kind,uv=[x,y],visible=visible,radius=radius)
def layer(asset,anchor_to=None,scale=1,anchor=None,offset=None,at=None,mirror=False,label=None):
    item={'asset':asset,'label':label or asset.split('/')[-1].replace('_',' '),'scale':scale}
    if anchor_to:item['poi']=anchor_to.lower()
    if at is not None:item['at']=at
    if anchor is None:
        box=list(map(float,ET.parse(PACK/(asset+'.svg')).getroot().get('viewBox').split()))
        anchor=[box[0]+box[2]/2,box[1]+box[3]/2] if anchor_to else [0,0]
    item['anchor']=anchor
    if offset:item['offset']=offset
    if mirror:item['mirror']=True
    return item

def drawing(label,svg,anchor_to=None,**kwargs):
    d=dict(label=label,svg=svg,**kwargs)
    if anchor_to:d['poi']=anchor_to.lower()
    return d

def background(name):return layer('backgrounds/'+name,scale=[1.2,1])
def hero(pose='standing',scale=1,mirror=False):
    anchor={'standing':[80,102],'dramatic':[80,102],'waving':[80,102],
            'flying':[98,70],'flying_arms_crossed':[95,70],'attack':[114,102]}[pose]
    return layer('characters/hero_'+pose,'Hero',scale,anchor,mirror=mirror)
def bubble(words,anchor_to):
    return drawing('Captured quote', '<path d="M-83-25H83V24H-6L-25 46-19 24H-83Z" fill="#ece8d9" stroke="#33383b" stroke-width="4"/><text x="0" y="7" text-anchor="middle" font-size="14" fill="#983f41">'+words+'</text>',anchor_to)
def panel(title,spun,damning,pois,layers):return dict(title=title,spun=spun,damning=damning,pois=pois,layers=layers)
H=lambda x=.76,y=.46:poi('Hero','HERO',x,y,True,.055)
CASES=[]

def case(id,title,note,hint,panels,tools,perfect):
    CASES.append(dict(id=id,title=title,note=note,hint=hint,panels=panels,tools=tools,perfect=perfect))

case('hero','THE HERO','Every hero deserves the right light.','Select the desk lamp.\nDrag it toward Halcyon.\nQ/E or wheel aims it.',[
 panel('THE HERO',"Captain Halcyon — First City's shining protector.",'Captain Halcyon poses above First City.',[H(.5,.49)],
       [background('rooftops_day'),hero('dramatic',1.3)])],['CeilingLight','DeskLamp'],'FIRST CITY’S SHINING PROTECTOR!')
case('fans',"THE PEOPLE'S HERO",'Make sure we can see how much the city loves him.','Keep Halcyon and\nhis supporters lit.\nA broad beam helps.',[
 panel('THE ARRIVAL',"First City's protector makes another welcome appearance.",'Citizens welcome Halcyon to the square.',[H(.67,.35),poi('Crowd','VICTIM',.35,.65,True,.10)],
 [background('plaza_day'),layer('characters/citizen_cheer_man','Crowd',.85,offset=[-42,0]),layer('characters/citizen_cheer_woman','Crowd',.85,offset=[42,0]),hero('flying',1.15)]),
 panel('THE FANS',"Citizens gather to greet their favourite hero.",'Halcyon stands with his cheering supporters.',[H(.68,.50),poi('Crowd','VICTIM',.31,.54,True,.11)],
 [background('plaza_day'),layer('characters/citizen_cheer_kid','Crowd',1,offset=[-34,25]),layer('characters/citizen_cheer_woman','Crowd',1,offset=[37,0]),hero('waving',1.05)])],['CeilingLight','DeskLamp'],'THE PEOPLE’S HERO!')
case('lake','ABOVE THE LAKE','Beautiful shot. Clean up the distraction in the water.','Keep Halcyon lit.\nPlace the paperweight\nin the light’s path.',[
 panel('ABOVE THE LAKE','Halcyon patrols the skies above First City.','Halcyon flies past as a woman struggles in the lake.',[H(.74,.34),poi('Woman','VICTIM',.27,.71,False,.075)],
 [background('lake_day'),layer('effects/water_ripples','Woman',.8),layer('characters/drowning_woman','Woman',1.0),hero('flying_arms_crossed',1.12)])],['DeskLamp','Paperweight'],'PATROLS THE SKIES!')
peace=[]
for i in range(2):
 ps=[H(.76,.43),poi('Victim','VICTIM',.24,.64,False,.08),poi('Officer','POLICE',.30,.43,False,.065)]
 ls=[background('street_day'),layer('characters/body_citizen_lying','Victim',.78),layer('characters/cop_shouting','Officer',.88,anchor=[50,40],mirror=False),hero('standing',1.08)]
 if i==1:
  ps.append(poi('Quote','SPEECH_BUBBLE',.30,.31,False,.075));ls.insert(-1,bubble('HE WAS INNOCENT!','Quote'))
 peace.append(panel('THE SCENE' if i==0 else 'THE ACCUSATION','Halcyon arrives at the scene of a tragic incident.','An officer confronts Halcyon beside a dead civilian.',ps,ls))
case('peace','KEEPING THE PEACE','The officer is blocking our hero. Fix the composition.','Light Halcyon.\nKeep the left-side\ncontext in shadow.',peace,['DeskLamp','Paperweight','Paperweight2'],'ARRIVES TO KEEP THE PEACE!')
case('rescue','THE RESCUE',"Focus on the rescue. We don't need speculation in the frame.",'Light the survivors.\nOn the second print,\nshape the shadows.',[
 panel('THE FIRE','Halcyon races to the scene of a devastating fire.','Halcyon stands outside a burning building with survivors.',[H(.74,.58),poi('Survivors','VICTIM',.40,.60,True,.10)],
 [background('street_night'),layer('props/burning_building',at=[145,45],scale=1.1),layer('characters/survivor_blanket_woman','Survivors',.82,offset=[-34,0]),layer('characters/survivor_blanket_man','Survivors',.82,offset=[35,0]),hero('dramatic',1.05)]),
 panel('THE WITNESS','Halcyon races to the scene of a devastating fire.','A witness points to Halcyon as the fire spreads behind him.',[H(.75,.43),poi('Witness','WITNESS',.23,.70,False,.075),poi('Fire','FIRE',.42,.44,False,.065)],
 [background('street_night'),layer('props/burning_building',at=[90,35],scale=.9),layer('characters/witness_man_blue','Witness',.95),
  drawing('Extended arm from Halcyon','<path d="M0 0L250 0" stroke="#b39d62" stroke-width="21"/>','Fire'),hero('standing',1.04),layer('effects/flame_small','Fire',.55)])],['DeskLamp','Paperweight','Paperweight2'],'RACES TO THE RESCUE!')
case('robbery','THE BANK','Great sequence. Make sure the getaway shot tells the same story.','The torch is precise.\nAim with Q/E or wheel.\nSpace switches it.',[
 panel('THE ROBBERY','Halcyon responds to a robbery at First City Savings.','Halcyon confronts an apparent robber outside First City Savings.',[H(.75,.60),poi('Robber','VICTIM',.29,.66,True,.075),poi('Bank','DAMAGE',.50,.31,True,.075)],
 [background('bank_front_day'),layer('characters/robber_hands_up','Robber',1.05),hero('attack',1.05,True)]),
 panel('THE GETAWAY','Halcyon takes to the skies in pursuit of the fleeing robbers.','Halcyon escapes First City Savings carrying stolen cash.',[H(.76,.32),poi('Bag','MONEY',.39,.40,False,.07),poi('Cash','MONEY',.28,.65,False,.065),poi('Guard','POLICE',.17,.73,False,.065),poi('Quote','SPEECH_BUBBLE',.18,.60,False,.065)],
 [background('rooftops_day'),drawing('Strap attached to Halcyon','<path d="M0 0Q140-25 280-50" fill="none" stroke="#685f46" stroke-width="11"/>','Bag'),layer('props/money_bag','Bag',.55),layer('props/cash_bill','Cash',.44,offset=[-20,-17]),layer('props/cash_bill','Cash',.40,offset=[25,19]),layer('characters/guard_pointing_shouting','Guard',.75,anchor=[50,45]),bubble('STOP!','Quote'),hero('flying',1.1)])],['DeskLamp','Torch','Paperweight','Paperweight2'],'IN PURSUIT OF THE ROBBERS!')
case('greatest','OUR GREATEST HERO','Make him a hero.','All the familiar tools.\nKeep Halcyon lit\nin every photograph.',[
 panel('THE ATTACK','Halcyon charges into danger.',"Halcyon's attack tears through the city.",[H(.75,.40),poi('Attack','FIRE',.45,.40,False,.06),poi('Damage','DAMAGE',.20,.57,False,.08)],
 [background('street_day'),layer('props/ruined_building','Damage',.6),drawing('Energy beam connecting hand and impact','<path d="M235 0L-195 75" stroke="#538d9e" stroke-width="21"/><path d="M235 0L-195 75" stroke="#b7d2c7" stroke-width="9"/>','Attack'),layer('effects/energy_blast','Attack',.40),hero('attack',1.05,True)]),
 panel('THEY RUN','Civilians escape as Halcyon holds the line.','Terrified civilians flee from Halcyon.',[H(.77,.42),poi('Fleeing','VICTIM',.26,.51,False,.10),poi('Injured','VICTIM',.27,.80,False,.08)],
 [background('ruined_city_day'),layer('characters/citizen_fleeing_a','Fleeing',.92,offset=[-37,0],mirror=True),layer('characters/citizen_fleeing_b','Fleeing',.9,offset=[40,10],mirror=True),layer('characters/body_citizen_lying','Injured',.75),hero('standing',1.05)]),
 panel('THE AFTERMATH',"First City's protector stands watch over the aftermath.",'Witnesses identify Halcyon as emergency crews arrive.',[H(.76,.45),poi('Witnesses','WITNESS',.28,.35,False,.09),poi('Victims','VICTIM',.24,.71,False,.075),poi('Police','POLICE',.41,.55,False,.065),poi('Damage','DAMAGE',.15,.52,False,.08)],
 [background('ruined_city_day'),layer('props/wrecked_car','Damage',.44),layer('characters/witness_woman_red','Witnesses',.76,offset=[-28,0]),layer('characters/witness_man_blue','Witnesses',.76,offset=[35,0]),layer('characters/body_citizen_lying','Victims',.72),layer('characters/cop_shouting','Police',.8),hero('dramatic',1.05)])],['DeskLamp','Torch','Torch2','Paperweight','Paperweight2','Paperweight3'],"OUR CITY'S GREATEST HERO!")


def main():
    manifest=[]
    for number,c in enumerate(CASES,1):
        path=ROOT/'data/levels'/c['id'];path.mkdir(parents=True,exist_ok=True)
        art=ROOT/'Assets/evidence'/c['id'];art.mkdir(parents=True,exist_ok=True)
        count=len(c['panels'])
        for i,p in enumerate(c['panels'],1):
            name=f'{i:02d}_panel'
            header=['[gd_resource type="Resource" script_class="PanelData" format=3]',
              '[ext_resource type="Script" path="res://scripts/data/panel_data.gd" id="panel"]',
              '[ext_resource type="Script" path="res://scripts/data/poi_data.gd" id="poi"]',
              f'[ext_resource type="Texture2D" path="res://Assets/evidence/{c["id"]}/{name}.svg" id="photo"]']
            for item in p['pois']:
                header += [f'[sub_resource type="Resource" id="{item["name"]}"]','script = ExtResource("poi")',
                  f'id = &"{c["id"]}_{i}_{item["name"].lower()}"',f'type = {TYPES[item["kind"]]}',
                  'description = '+q(item['name'].replace('_',' ')),f'desired = {0 if item["visible"] else 1}',
                  f'position_uv = Vector2({item["uv"][0]}, {item["uv"][1]})',f'radius_uv = {item["radius"]}','importance = 2.0']
            captions={'SPUN':p['spun'],'DAMNING':p['damning'],'MURKY':'The subject needs clearer lighting.','TAMPERED':'The print is scorched. Prepare a fresh copy.'}
            comments={'SPUN':['We don’t deserve Halcyon!','My son wants to be just like him!',"Another day saved by First City's greatest hero."][min(i-1,2)] if number==7 else p['spun']+' Great work, Captain!',
                      'DAMNING':p['damning'],'MURKY':f'Panel {i} is too dark to read.'}
            header += ['[resource]','script = ExtResource("panel")',f'id = &"{c["id"]}_{name}"','title = '+q(p['title']),'texture = ExtResource("photo")',
              'pois = Array[ExtResource("poi")](['+', '.join('SubResource('+q(x['name'])+')' for x in p['pois'])+'])',
              'rule_order = PackedInt32Array(1, 0, 2)','captions = '+dictionary(captions),
              'balloons = '+dictionary({'SPUN':'First City can count on me.','DAMNING':'','MURKY':'','TAMPERED':''}),
              'sound_effects = '+dictionary({'SPUN':['WHOOSH!','SAFE NOW!','STAND TALL!'][min(i-1,2)],'DAMNING':'','MURKY':'','TAMPERED':'FZZT!'}),
              'comments = '+dictionary(comments)]
            (path/(name+'.tres')).write_text('\n'.join(header)+'\n')
            layers=p['layers']
            backdrop=layers[0]
            shifts={'hero':0,'fans':(-15 if i==1 else -80),'lake':0,'peace':-170,'rescue':-95,'robbery':(-65 if i==1 else 0),'greatest':(-155 if i==1 else -180)}
            shift=shifts[c['id']]
            if shift:
                backdrop['at']=[0,shift]
                layers.insert(0,drawing('Continuous foreground', '<rect width="768" height="640" fill="#88877c"/>'))
            if c['id']=='hero':
                layers.insert(1,drawing('Rooftop ledge','<rect x="-115" y="176" width="245" height="30" fill="#939187" stroke="#343e43" stroke-width="5"/>','Hero'))
            manifest.append(dict(title=c['title']+' / '+p['title'],resource=f'data/levels/{c["id"]}/{name}.tres',size=[768,640],desaturation=.40,layers=p['layers']))
        # Normalize the reward to the panel count: every perfect page scores 100.
        (path/'reaction.tres').write_text('[gd_resource type="Resource" script_class="ReactionConfig" format=3]\n[ext_resource type="Script" path="res://scripts/data/reaction_config.gd" id="script"]\n[resource]\nscript = ExtResource("script")\nstate_weights = {"SPUN": '+str(50/count)+', "DAMNING": '+str(-50/count)+', "MURKY": -12.0, "TAMPERED": -25.0}\n')
        comments=['[gd_resource type="Resource" script_class="CommentTemplates" format=3]','[ext_resource type="Script" path="res://scripts/data/comment_templates.gd" id="script"]','[resource]','script = ExtResource("script")',
          'usernames = PackedStringArray("city_mum", "halcyon_fan", "beacon_reader", "first_city_kid", "square_watch", "morning_reader")',
          'fan_comments = PackedStringArray("We don’t deserve Halcyon!", "My son wants to be just like him!", "Another day saved by First City’s greatest hero.", "I feel safer knowing he’s out there.")',
          'skeptic_comments = PackedStringArray("Can we get a clearer photograph?", "The caption and the photo don’t match.")',
          'burned_comment = "Panel %d looks scorched. Is there a fresh copy?"','murky_group = "These photos need more light."',
          'fan_reply = "He always keeps First City safe."','twist = ""','twist_reply = ""','post_caption = '+q(c['perfect']+' #CaptainHalcyon #FirstCity')]
        (path/'comments.tres').write_text('\n'.join(comments)+'\n')
        layouts={1:['Rect2(0, 0.25, 3.65, 3.041667)'],2:['Rect2(0, -0.9, 2.35, 1.958333)','Rect2(0, 1.4, 2.35, 1.958333)'],3:['Rect2(-1.1, -0.9, 1.95, 1.625)','Rect2(1.1, -0.9, 1.95, 1.625)','Rect2(0, 1.4, 2.35, 1.958333)']}[count]
        level=['[gd_resource type="Resource" script_class="LevelData" format=3]','[ext_resource type="Script" path="res://scripts/data/level_data.gd" id="script"]',
          '[ext_resource type="Script" path="res://scripts/data/panel_data.gd" id="panel"]','[ext_resource type="Resource" path="res://data/levels/'+c['id']+'/comments.tres" id="comments"]',
          '[ext_resource type="Resource" path="res://data/levels/'+c['id']+'/reaction.tres" id="reaction"]']
        level += [f'[ext_resource type="Resource" path="res://data/levels/{c["id"]}/{i:02d}_panel.tres" id="p{i}"]' for i in range(1,count+1)]
        level += ['[resource]','script = ExtResource("script")','id = &'+q(c['id']),'title = '+q(c['title']),f'case_number = {number}','incident = '+q('First City / archive sequence '+str(number)),
          'panels = Array[ExtResource("panel")](['+', '.join(f'ExtResource("p{i}")' for i in range(1,count+1))+'])',
          'photo_layouts = Array[Rect2](['+', '.join(layouts)+'])',f'required_spun = {count}','ceiling_starts_on = false',
          'available_tools = PackedStringArray('+', '.join(q(t) for t in dict.fromkeys(['CeilingLight', *c['tools']]))+')',
          'tool_positions = {"DeskLamp": Vector3(-4.2, 0, -2.2), "Torch": Vector3(3.7, 0, 0.1), "Torch2": Vector3(3.7, 0, 2.1), "Paperweight": Vector3(-3.6, 0, 1.0), "Paperweight2": Vector3(-3.1, 0, 2.0), "Paperweight3": Vector3(-3.7, 0, 2.8)}',
          'tool_yaws = {"DeskLamp": 180.0, "Torch": 180.0, "Torch2": 180.0}',
          'tool_settings = {"Paperweight:scale": Vector3(1.5, 1.5, 1.5), "Paperweight2:scale": Vector3(1.5, 1.5, 1.5), "Paperweight3:scale": Vector3(1.5, 1.5, 1.5), "DeskLamp/GameplayLight:intensity": 1.8, "DeskLamp/GameplayLight:falloff": 0.8, "DeskLamp/Head/VisualLight:spot_angle": 52.0, "Torch/Beam/VisualLight:spot_angle": 16.0, "Torch/GameplayLight:intensity": 2.0, "Torch2/Beam/VisualLight:spot_angle": 16.0, "Torch2/GameplayLight:intensity": 2.0}',
          'subtitles = '+dictionary({'perfect':c['perfect'],'damning':'AN EVENTFUL DAY IN FIRST CITY','mixed':'HALCYON AT THE SCENE','murky':'A QUIET EDITION','tampered':'A PRINTING MISHAP'}),
          'editor_note = '+q(c['note']),'mechanic_hint = '+q(c['hint']),'target_rings_default = true',
          'comment_templates = ExtResource("comments")','reaction_config = ExtResource("reaction")','final_case = false']
        level_text='\n'.join(level)+'\n'
        if number>=3:level_text=level_text.replace('DeskLamp\": Vector3(-4.2, 0, -2.2)', 'DeskLamp\": Vector3(3.8, 0, 0.1)')
        if number==7:level_text=level_text.replace('spot_angle\": 52.0', 'spot_angle\": 20.0')
        (path/'level.tres').write_text(level_text)
    (ROOT/'data/art/evidence_compositions.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
    print('Authored 7 cases / 13 photos. Run compose_evidence_scenes.py next.')

if __name__=='__main__':main()
