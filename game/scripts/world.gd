extends Node3D
var game
var sun
var environment
var plots=[]
var targets=[]
var animals={}
var house
var truck
var truck_visual
var headlights=[]
var headlight_lenses=[]
var night_light_level=0.0
var mats={}
var rng=RandomNumberGenerator.new()
var deco
var terrain_material
var current_season=""
var plot_signatures={}
var plot_visuals
var crop_signature=""
var sky_material
var sun_disc
var moon_disc
var lantern
var lantern_model
var village_lights=[]
var clouds
var crop_visuals
var nature
var scenery
const ROAD_ROUTES=[
 {"points":[Vector3(0,0,12),Vector3(7,0,2),Vector3(8,0,-12),Vector3(22,0,-28),Vector3(55,0,-58)],"width":4.5},
 {"points":[Vector3(-3,0,12),Vector3(-26,0,35),Vector3(-49,0,53)],"width":2.0},
 {"points":[Vector3(40,0,-58),Vector3(82,0,-58)],"width":5.0}
]

func mat(hex):
 if mats.has(hex):return mats[hex]
 var m=StandardMaterial3D.new();m.albedo_color=Color(hex);m.roughness=.9
 if hex in ["66523a","947049"] and ResourceLoader.exists("res://assets/textures/soil.png"):
  m.albedo_texture=load("res://assets/textures/soil.png");m.albedo_color=Color("a9a395") if hex=="66523a" else Color.WHITE
 mats[hex]=m
 return m
func shape(parent,mesh,p,color,scale_v=Vector3.ONE):
 var o=MeshInstance3D.new();o.mesh=mesh;o.position=p;o.scale=scale_v;o.material_override=mat(color);parent.add_child(o)
 return o
func box(parent,p,size,color):
 var m=BoxMesh.new();m.size=size;return shape(parent,m,p,color)
func sphere(parent,p,size,color):
 var m=SphereMesh.new();m.radial_segments=20;m.rings=10;return shape(parent,m,p,color,size)
func cone(parent,p,r,h,color):
 var m=CylinderMesh.new();m.top_radius=0;m.bottom_radius=r;m.height=h;m.radial_segments=9;return shape(parent,m,p,color)
func cylinder(parent,p,r,h,color):
 var m=CylinderMesh.new();m.top_radius=r;m.bottom_radius=r;m.height=h;m.radial_segments=12;return shape(parent,m,p,color)
func label3(parent,text,p,size=30):
 var l=Label3D.new();l.set_meta("source_text",Lang.source(text));l.text=Lang.t(text);l.position=p;l.font_size=size;l.pixel_size=.008;l.outline_size=2;l.modulate=Color("fff5d9");l.billboard=BaseMaterial3D.BILLBOARD_DISABLED
 if ResourceLoader.exists("res://assets/fonts/NotoSansThai.ttf"):l.font=load("res://assets/fonts/NotoSansThai.ttf")
 parent.add_child(l);Lang.changed.connect(func():l.text=Lang.t(l.get_meta("source_text")));return l
func base_terrain_y(x,z):
 var edge=smoothstep(65.0,130.0,max(abs(x),abs(z)))
 return edge*(sin(x*.036)*4.0+cos(z*.037)*3.0+4.0)
func terrain_y(x,z):
 var brook_x=-62+sin(z*.04)*8
 var depression=(1.0-smoothstep(1.2,3.5,abs(x-brook_x)))*.48 if abs(z)<124 else 0.0
 var lake_distance=Vector2((x+58)/17.0,(z-57)/11.05).length()
 var lake_basin=.65*(1.0-smoothstep(.70,1.08,lake_distance))
 return base_terrain_y(x,z)-depression-lake_basin
func ground(p):
 # Use the same triangle interpolation as the physical terrain mesh.
 var x=clamp(floor((p.x+140)/2)*2-140,-140,138);var z=clamp(floor((p.z+140)/2)*2-140,-140,138)
 var u=clamp((p.x-x)/2,0,1);var v=clamp((p.z-z)/2,0,1)
 var a=terrain_y(x,z);var b=terrain_y(x+2,z);var c=terrain_y(x,z+2);var d=terrain_y(x+2,z+2)
 return a+(b-a)*u+(c-a)*v if u+v<=1 else d+(c-d)*(1-u)+(b-d)*(1-v)
func near_road(p,margin=3.5):
 var q=Vector2(p.x,p.z)
 for road in ROAD_ROUTES:
  var route=road.points
  for i in range(route.size()-1):
   if Geometry2D.get_closest_point_to_segment(q,Vector2(route[i].x,route[i].z),Vector2(route[i+1].x,route[i+1].z)).distance_to(q)<margin:return true
 return false
func road_clearance(p):
 # Distance to the road edge, including bends and the wider village street.
 var q=Vector2(p.x,p.z);var clearance=INF
 for road in ROAD_ROUTES:
  for i in range(road.points.size()-1):
   var a=road.points[i];var b=road.points[i+1]
   clearance=min(clearance,Geometry2D.get_closest_point_to_segment(q,Vector2(a.x,a.z),Vector2(b.x,b.z)).distance_to(q)-road.width*.5)
 return clearance
func build(g):
 game=g;rng.seed=673380
 nature=load("res://scripts/nature_assets.gd").new(self)
 environment=WorldEnvironment.new();add_child(environment)
 var e=Environment.new();environment.environment=e
 e.background_mode=Environment.BG_SKY;e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("c6dddb");e.ambient_light_energy=.30;e.tonemap_mode=Environment.TONE_MAPPER_LINEAR
 e.fog_enabled=true;e.fog_sky_affect=.15;e.fog_density=.0014;e.fog_light_color=Color("bcd7d3")
 var sky=Sky.new();var sm=ShaderMaterial.new();sm.shader=load("res://assets/environment/photo_sky.gdshader");sm.set_shader_parameter("panorama",load("res://assets/environment/sky_day.jpg"));sky_material=sm;sky.sky_material=sm;sky.radiance_size=Sky.RADIANCE_SIZE_128;e.sky=sky
 sun=DirectionalLight3D.new();sun.light_color=Color("fff0d5");sun.light_energy=.65;sun.rotation_degrees=Vector3(-48,-30,0);sun.shadow_enabled=true;sun.directional_shadow_max_distance=35;add_child(sun)
 terrain()
 scenery=load("res://scripts/lush_scenery.gd").new(self)
 scenery.mountains()
 trees()
 grass()
 scenery.decorate()
 village()
 farm_buildings()
 create_plots()
 create_truck()
 refresh()
 batch_static(house)
 batch_static(self)
 setup_lights()
func batch_static(parent):
 var groups={}
 for o in parent.find_children("*","MeshInstance3D",true,false):
  if o.skin or o.material_override==terrain_material or o.get_meta("dynamic",false):continue
  var ancestor=o.get_parent();var skip=false
  while ancestor and ancestor!=parent:
   if ancestor.get_meta("dynamic",false) or ancestor==house or ancestor==truck or ancestor.get_meta("kind","") in ["plot","animal","market","livestock","upgrade"]:skip=true;break
   ancestor=ancestor.get_parent()
  if skip:continue
  var transform=parent.global_transform.affine_inverse()*o.global_transform
  for surface in range(o.mesh.get_surface_count()):
   var material=o.material_override if o.material_override else o.mesh.surface_get_material(surface)
   if not material:continue
   var key=str(material.get_instance_id())+":"+str(o.cast_shadow)
   if not groups.has(key):
    var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);groups[key]={"st":st,"material":material,"shadow":o.cast_shadow}
   groups[key].st.append_from(o.mesh,surface,transform)
  o.queue_free()
 for group in groups.values():
  var mesh=MeshInstance3D.new();mesh.mesh=group.st.commit();mesh.material_override=group.material;mesh.cast_shadow=group.shadow;parent.add_child(mesh)
func terrain():
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var n=140;var step=2.0
 for ix in range(n):
  for iz in range(n):
   var x=-140+ix*step;var z=-140+iz*step
   var corners=[Vector3(x,terrain_y(x,z),z),Vector3(x+step,terrain_y(x+step,z),z),Vector3(x,terrain_y(x,z+step),z+step),Vector3(x+step,terrain_y(x+step,z+step),z+step)]
   for j in [0,1,2,1,3,2]:
    var v=corners[j];var shade=.98+.012*sin(v.x*.07)*cos(v.z*.08)
    var normal=Vector3(terrain_y(v.x-.2,v.z)-terrain_y(v.x+.2,v.z),.4,terrain_y(v.x,v.z-.2)-terrain_y(v.x,v.z+.2)).normalized()
    st.set_uv(Vector2(v.x/8.0,v.z/8.0));st.set_normal(normal);st.set_color(Color(.42*shade,.57*shade,.30*shade));st.add_vertex(v)
 var mesh=st.commit();var m=ShaderMaterial.new();m.shader=load("res://assets/environment/meadow_ground.gdshader");m.set_shader_parameter("grass_texture",load("res://assets/environment/ground_grass.jpg"));terrain_material=m
 var o=MeshInstance3D.new();o.mesh=mesh;o.material_override=m;o.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(o)
 var body=StaticBody3D.new();var collision=CollisionShape3D.new();collision.shape=mesh.create_trimesh_shape();collision.shape.backface_collision=true;body.add_child(collision);add_child(body)
 for i in [0,1]:path(ROAD_ROUTES[i].points,ROAD_ROUTES[i].width)
 # Quiet lake and stream: opaque water keeps the browser render cost low.
 var water=ShaderMaterial.new();water.shader=load("res://assets/environment/lake.gdshader")
 var pond=CylinderMesh.new();pond.top_radius=17;pond.bottom_radius=17;pond.height=.08;pond.radial_segments=48
 var lake=MeshInstance3D.new();lake.mesh=pond;lake.material_override=water;lake.position=Vector3(-58,-.14,57);lake.scale.z=.65;add_child(lake)
 var brook=[]
 for z in range(-120,121,2):brook.append(Vector3(-62+sin(z*.04)*8,0,z))
 var left_bank=[];var right_bank=[]
 for i in range(brook.size()):
  var direction=brook[min(i+1,brook.size()-1)]-brook[max(0,i-1)]
  var side=Vector3(direction.z,0,-direction.x).normalized()*2.9
  left_bank.append(brook[i]-side);right_bank.append(brook[i]+side)
 ribbon(left_bank,1.3,"a9a77a",.012);ribbon(right_bank,1.3,"a9a77a",.012)
 var water_strip=ribbon(brook,4.1,"78b3bd",-.17)
 var wm=ShaderMaterial.new();wm.shader=load("res://assets/water.gdshader");water_strip.material_override=wm;water_strip.set_meta("dynamic",true)
 # Wooden bridge over the brook.
 box(self,Vector3(-56,.30,34),Vector3(12,.35,3),"a88c66")
 var bridge_body=StaticBody3D.new();var bridge_shape=CollisionShape3D.new();var bridge_box=BoxShape3D.new();bridge_box.size=Vector3(12,.35,3);bridge_shape.shape=bridge_box;bridge_body.position=Vector3(-56,.30,34);bridge_body.add_child(bridge_shape);add_child(bridge_body)
 for side in [-1,1]:
  var ramp_st=SurfaceTool.new();ramp_st.begin(Mesh.PRIMITIVE_TRIANGLES)
  var x0=-56+side*6;var x1=x0+side*2.5
  var corners=[Vector3(x0,.475,32.5),Vector3(x0,.475,35.5),Vector3(x1,ground(Vector3(x1,0,32.5))+.025,32.5),Vector3(x1,ground(Vector3(x1,0,35.5))+.025,35.5)]
  for j in [0,1,2,1,3,2]:ramp_st.add_vertex(corners[j])
  ramp_st.generate_normals();var ramp=shape(self,ramp_st.commit(),Vector3.ZERO,"a88c66");ramp.material_override=mat("a88c66").duplicate();ramp.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
  var rb=StaticBody3D.new();var rc=CollisionShape3D.new();rc.shape=ramp.mesh.create_trimesh_shape();rc.shape.backface_collision=true;rb.add_child(rc);add_child(rb)
 for side in [-1,1]:box(self,Vector3(-56,1.0,34+side*1.4),Vector3(12,.12,.12),"705d45")
 for i in range(12):
  var p=Vector3(rng.randf_range(-125,125),0,rng.randf_range(-125,125))
  if abs(p.x)<40 and abs(p.z)<40:continue
  p.y=ground(p);sphere(self,p+Vector3(0,.4,0),Vector3(1.3,.8,1.0)*rng.randf_range(.5,1.8),"8b9685")
func ribbon(points,width,color,lift):
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var sections=[]
 for i in range(points.size()):
  var direction=points[min(i+1,points.size()-1)]-points[max(0,i-1)]
  var side=Vector3(direction.z,0,-direction.x).normalized()*width*.5
  sections.append([points[i]-side,points[i]+side])
 for i in range(points.size()-1):
  var corners=[sections[i][0],sections[i][1],sections[i+1][0],sections[i+1][1]]
  for j in [0,2,1,1,2,3]:
   var v=corners[j];v.y=(base_terrain_y(v.x,v.z) if color=="78b3bd" else ground(v))+lift;st.set_uv(Vector2(v.x,v.z)*.15);st.add_vertex(v)
 st.generate_normals();var o=shape(self,st.commit(),Vector3.ZERO,color);o.material_override=mat(color).duplicate();o.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED;return o
func path(points,width):
 var samples=[]
 for i in range(points.size()-1):
  var steps=int(ceil(points[i].distance_to(points[i+1])/2))
  for j in range(steps):samples.append(points[i].lerp(points[i+1],float(j)/steps))
 samples.append(points[-1]);ribbon(samples,width,"bdad88",.025)
func mountains():
 # Two peaks share the northern horizon; the other map edges stay open.
 for i in range(2):
  var h=115.0 if i==0 else 150.0;var p=Vector3(-100+i*185,-5,-350-i*45)
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);var rings=[]
  for ring in range(6):
   var verts=[]
   for j in range(20):
    var a=float(j)/20*TAU;var t=float(ring)/5;var radius=(1-t)*135*(.9+rng.randf()*.15)
    verts.append(p+Vector3(sin(a)*radius+t*18,t*h+sin(j*1.7)*h*.025,cos(a)*radius))
   rings.append(verts)
  for r in range(5):
   for j in range(20):
    for idx in [[r,j],[r+1,j],[r,(j+1)%20],[r,(j+1)%20],[r+1,j],[r+1,(j+1)%20]]:
     var v=rings[idx[0]][idx[1]];st.set_color(Color("cbd7dc") if v.y>h*.68 else Color("a0b2c0") if v.y>h*.32 else Color("728c9d"));st.add_vertex(v)
  st.generate_normals();var o=MeshInstance3D.new();o.mesh=st.commit();var m=StandardMaterial3D.new();m.vertex_color_use_as_albedo=true;m.roughness=1;m.cull_mode=BaseMaterial3D.CULL_DISABLED;o.material_override=m;o.set_meta("mountain",true);add_child(o)
func trees():
 # Forest clusters leave the farm, market, roads and lake shore clear.
 var positions=[]
 var zones=[Vector2(-103,-67),Vector2(107,-5),Vector2(76,101),Vector2(-98,104),Vector2(7,-119)]
 for i in range(140):
  var zone=zones[i%zones.size()];var a=rng.randf()*TAU;var r=sqrt(rng.randf())*32
  var p=Vector3(zone.x+cos(a)*r,0,zone.y+sin(a)*r)
  if abs(p.x)>137 or abs(p.z)>137 or near_road(p,6) or abs(p.x+62)<10:continue
  if p.distance_to(Vector3(-58,0,57))<23:continue
  p.y=ground(p);positions.append(p)
  var body=StaticBody3D.new();var c=CollisionShape3D.new();var trunk=CylinderShape3D.new();trunk.radius=.30;trunk.height=3.6;c.shape=trunk;c.position.y=1.8;body.position=p;body.set_meta("tree",true);body.add_child(c);add_child(body)
 # A handful of shade trees close to home, all away from walking routes.
 for p in [Vector3(-22,0,9),Vector3(-25,0,-30),Vector3(39,0,30),Vector3(85,0,-43),Vector3(-27,0,-3),Vector3(-29,0,-14),Vector3(-31,0,-24),Vector3(-24,0,-40),Vector3(-15,0,-43),Vector3(-4,0,-46),Vector3(38,0,-27),Vector3(45,0,-18)]:
  shade_tree(p)
 for i in positions.size():
  var keys=["CommonTree_1","CommonTree_3","Pine_1"]
  nature.place(keys[i%3],positions[i],6.8+float(i%5)*.5,float(i)*1.17)
 flowers()
 nature.flush(self)
func flowers():
 var centers=[Vector3(-20,0,8),Vector3(-24,0,-28),Vector3(42,0,-47),Vector3(81,0,-48),Vector3(-39,0,62),Vector3(-17,0,-14)]
 for i in range(64):
  var p=centers[i%centers.size()]+Vector3(rng.randf_range(-2.8,2.8),0,rng.randf_range(-2.3,2.3));p.y=ground(p)
  if near_road(p,3):continue
  var key=["Flower_3_Group","Flower_4_Group","Fern_1","Clover_1"][i%4]
  var height=.28+rng.randf()*.25;var angle=rng.randf()*TAU
  # Thin both flower colours equally without shifting later random placements.
  if i%8 in [4,5]:continue
  nature.place(key,p,height,angle)
 for p in [Vector3(-16,0,8),Vector3(-18,0,-7),Vector3(-18,0,-24),Vector3(3,0,-26),Vector3(33,0,-44),Vector3(86,0,-42)]:
  p.y=ground(p);nature.place("Bush_Common_Flowers",p,1.05,rng.randf()*TAU,true)
func chalet(p,size,color,title):
 var n=Node3D.new();add_child(n);n.position=p;n.position.y=ground(p)
 box(n,Vector3(0,.04,0),Vector3(size.x+.4,.08,size.z+.4),"b4ad97")
 # Open front doorway; solid side and back walls.
 box(n,Vector3(-size.x*.5,size.y*.5,0),Vector3(.2,size.y,size.z),color)
 box(n,Vector3(size.x*.5,size.y*.5,0),Vector3(.2,size.y,size.z),color)
 box(n,Vector3(0,size.y*.5,-size.z*.5),Vector3(size.x,size.y,.2),color)
 for s in [-1,1]:box(n,Vector3(s*(size.x*.25+.6),size.y*.5,size.z*.5),Vector3(size.x*.5-1.2,size.y,.2),color)
 box(n,Vector3(0,size.y-.22,size.z*.5),Vector3(2.4,.44,.2),color)
 for s in [-1,1]:
  var span=size.x*.5+.5;var ridge=size.y+size.x*.5*tan(.4)
  var roof=box(n,Vector3(s*span*.5,ridge-span*.5*tan(.4),0),Vector3(span/cos(.4),.20,size.z+1),"75584c");roof.rotation.z=s*-.40
  box(n,Vector3(s*(size.x*.5-.65),1.7,size.z*.5+.13),Vector3(.75,.8,.05),"93c6c2")
  box(n,Vector3(s*(size.x*.5-.65),1.25,size.z*.5+.22),Vector3(1,.15,.36),"72583f")
  sphere(n,Vector3(s*(size.x*.5-.65),1.39,size.z*.5+.22),Vector3(.7,.2,.25),"c68b91")
  sphere(n,Vector3(s*(size.x*.5-.65),1.40,size.z*.5+.20),Vector3(.55,.18,.25),"699255")
  box(n,Vector3(s*(size.x*.5-.65),1.7,size.z*.5+.17),Vector3(.055,.82,.06),"e0cfaa")
  box(n,Vector3(s*(size.x*.5-.65),1.7,size.z*.5+.17),Vector3(.78,.055,.06),"e0cfaa")
 for h in [.3,1.0,2.5]:
  for s in [-1,1]:box(n,Vector3(s*(size.x*.25+.6),h,size.z*.5+.12),Vector3(size.x*.5-1.2,.09,.08),"98714f")
 for side in [-1,1]:
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for v in [Vector3(-size.x*.5,size.y-.04,side*size.z*.5),Vector3(0,size.y+size.x*.5*tan(.4),side*size.z*.5),Vector3(size.x*.5,size.y-.04,side*size.z*.5)]:st.add_vertex(v)
  st.generate_normals();var gable=shape(n,st.commit(),Vector3.ZERO,"98714f");gable.material_override=mat("98714f").duplicate();gable.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
 box(n,Vector3(-size.x*.5+.45,size.y+1.3,-size.z*.2),Vector3(.45,1.6,.45),"a3a18d")
 label3(n,title,Vector3(0,size.y+.6,size.z*.5+.15),26)
 # Collision walls correspond to the open doorway.
 for o in n.get_children():
  if o is MeshInstance3D and o.mesh is BoxMesh and o.position.y>0.3:
   if o.position.y>size.y and o.mesh.size.z<size.z:continue
   if o.mesh.size.y<.3 and o.position.y<size.y:continue
   var body=StaticBody3D.new();var c=CollisionShape3D.new();var sh=BoxShape3D.new();sh.size=o.mesh.size;c.shape=sh;body.position=o.position;body.rotation=o.rotation;body.add_child(c);n.add_child(body)
 return n
func target(p,kind,title,id=-1):
 var n=Node3D.new();n.position=p;add_child(n);n.set_meta("kind",kind);n.set_meta("title",Lang.source(title));n.set_meta("id",id);targets.append(n);return n
func npc(asset,p,kind,title):
 var n=target(p,kind,title);n.position.y=ground(p);var model=load("res://assets/models/"+asset+".glb").instantiate();n.add_child(model)
 var life=load("res://scripts/character_life.gd").new();model.add_child(life);life.setup(model,game,true,410+int(p.x))
 for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.visibility_range_end=45;mesh.visibility_range_end_margin=3
 var ap=model.find_child("AnimationPlayer",true,false)
 if ap:
  for anim in ap.get_animation_list():
   if "Idle" in anim:ap.get_animation(anim).loop_mode=Animation.LOOP_LINEAR;ap.play(anim);break
 label3(n,{"market":Lang.t("ร้านเมล็ด / ตลาด"),"livestock":Lang.t("ร้านสัตว์"),"upgrade":Lang.t("ช่าง")}[kind],Vector3(0,2.1,0),28)
 var body=StaticBody3D.new();var c=CollisionShape3D.new();var sh=CapsuleShape3D.new();sh.radius=.25;sh.height=1.6;c.shape=sh;c.position.y=.8;body.add_child(c);n.add_child(body)
func village():
 chalet(Vector3(48,0,-67),Vector3(7,3.2,5),"b89170",Lang.t("เมล็ด & ตลาด"))
 chalet(Vector3(62,0,-67),Vector3(7,3.2,5),"bba98c",Lang.t("สัตว์ & อาหาร"))
 chalet(Vector3(76,0,-67),Vector3(7,3.2,5),"aa8870",Lang.t("ช่างประจำหมู่บ้าน"))
 npc("seed",Vector3(46.2,0,-63),"market",Lang.t("คุยกับคนขายเมล็ด / ขายผลผลิต"))
 npc("livestock",Vector3(60.2,0,-63),"livestock",Lang.t("คุยกับคนขายสัตว์"))
 npc("carpenter",Vector3(74.2,0,-63),"upgrade",Lang.t("คุยกับช่าง / อัปเกรด"))
 path(ROAD_ROUTES[2].points,ROAD_ROUTES[2].width)
 for p in [Vector3(39,0,-47),Vector3(81,0,-47)]:bench(p,PI)
 # Parking bays sit beside the village lane, outside shop entrances.
 for x in [61,66]:
  box(self,Vector3(x,.025,-51),Vector3(3.7,.05,5),"c5b991")
  for side in [-1,1]:box(self,Vector3(x+side*1.7,.065,-51),Vector3(.08,.025,4.5),"eee0bd")
func farm_buildings():
 house=chalet(Vector3(-7,0,4),Vector3(7,3,6),"b99b77",Lang.t("บ้านของเรา"))
 box(house,Vector3(-1.5,.45,-.8),Vector3(1.4,.6,2.4),"80664e")
 box(house,Vector3(-1.5,.8,-.8),Vector3(1.25,.15,2.2),"dfd1b0")
 box(house,Vector3(-1.5,.95,-1.55),Vector3(1,.15,.5),"f3e5c6")
 target(Vector3(-8.5,.8,3.2),"bed",Lang.t("นอน · ข้ามวันและบันทึกเกม"))
 chalet(Vector3(24,0,-5),Vector3(9,3,6),"aa8562",Lang.t("คอกสัตว์"))
 target(Vector3(24,0,0),"trough",Lang.t("ให้อาหารสัตว์ทุกตัว"))
 box(self,Vector3(24,.45,.4),Vector3(3,.7,.9),"947956")
 box(self,Vector3(24,.8,.4),Vector3(2.7,.06,.6),"c8ba73")
 for z in [-2,22]:
  for x in range(12,37,3):box(self,Vector3(x,.65,z),Vector3(.12,1.3,.12),"d0b788")
  for y in [.45,.95]:box(self,Vector3(24,y,z),Vector3(24,.10,.10),"d0b788")
 for x in [12,36]:
  for z in range(-2,23,3):box(self,Vector3(x,.65,z),Vector3(.12,1.3,.12),"d0b788")
  for y in [.45,.95]:
   if x==12:
    box(self,Vector3(x,y,2),Vector3(.10,.10,8),"d0b788");box(self,Vector3(x,y,16),Vector3(.10,.10,12),"d0b788")
   else:box(self,Vector3(x,y,10),Vector3(.10,.10,24),"d0b788")
 for section in [[Vector3(24,.6,-2),Vector3(24,1.2,.14)],[Vector3(24,.6,22),Vector3(24,1.2,.14)],[Vector3(36,.6,10),Vector3(.14,1.2,24)],[Vector3(12,.6,2),Vector3(.14,1.2,8)],[Vector3(12,.6,16),Vector3(.14,1.2,12)]]:
  var fence=StaticBody3D.new();var c=CollisionShape3D.new();var sh=BoxShape3D.new();sh.size=section[1];c.shape=sh;fence.position=section[0];fence.add_child(c);add_child(fence)
 target(Vector3(0,0,10),"guide",Lang.t("สมุดชาวสวน · เป้าหมายและแผนที่"))
 box(self,Vector3(0,.8,10),Vector3(.12,1.6,.12),"9e835c");box(self,Vector3(0,1.5,10),Vector3(1.5,.65,.10),"705a3e")
 label3(self,Lang.t("สวนของเรา"),Vector3(0,1.55,10.08),20)
func create_plots():
 for i in range(36):
  var p=Vector3(-12+(i%6)*2.8,0,-9-int(i/6)*2.8)
  var n=target(p,"plot",Lang.t("แปลงปลูก"),i);plots.append(n)
func refresh():
 if current_season!=Farm.season():
  current_season=Farm.season()
  terrain_material.set_shader_parameter("season_tint",Color("d9e5dd") if current_season==Lang.t("ฤดูหนาว") else Color("d4bb82") if current_season==Lang.t("ใบไม้ร่วง") else Color.WHITE)
 var plot_changed=false
 for i in range(plots.size()):
  var n=plots[i]
  var p=Farm.data.plots[i]
  var signature=JSON.stringify(p)+str(i<Farm.max_plots())
  if plot_signatures.get(i,"")==signature:continue
  plot_signatures[i]=signature;plot_changed=true
  for c in n.get_children():c.queue_free()
  if i>=Farm.max_plots():continue
  rounded_plot(n,"b5aa7c" if not p.tilled else "66523a" if p.water else "947049",true)
 if plot_changed:batch_plot_visuals()
 var crops_key=JSON.stringify(Farm.data.plots)+str(Farm.max_plots())
 if crop_signature!=crops_key:crop_signature=crops_key;make_crops()
 house.scale=Vector3.ONE*(1.0+int(Farm.data.home_level)*.08)
 # Add/remove animals and swap their young/adult mesh only when needed.
 var ids=[]
 for a in Farm.data.animals:
  var id=int(a.id);ids.append(id)
  if not animals.has(id):
   var node=load("res://scripts/animal.gd").new();node.game=game;node.record_id=id;add_child(node);animals[id]=node;targets.append(node)
  animals[id].refresh()
 for id in animals.keys():
   if not id in ids:targets.erase(animals[id]);animals[id].queue_free();animals.erase(id)
func reset_actors():
 for n in animals.values():targets.erase(n);n.queue_free()
 animals.clear();refresh()
func grass():
 # Smooth meadow instead of thousands of individual grass blades.
 box(self,Vector3(-46,.20,57),Vector3(10,.22,2),"a18560")
 bench(Vector3(-38,0,66),PI/2)
func bench(p,angle=0.0):
 var holder=Node3D.new();holder.position=p;holder.position.y=ground(p);holder.rotation.y=angle;holder.set_meta("bench",true);holder.set_meta("kind","bench");holder.set_meta("title","นั่งพักชมวิว");add_child(holder);targets.append(holder)
 box(holder,Vector3(0,.55,0),Vector3(2,.16,.65),"a48761")
 box(holder,Vector3(0,.95,.27),Vector3(2,.55,.13),"b79a71")
 for x in [-.75,.75]:box(holder,Vector3(x,.26,0),Vector3(.12,.52,.5),"80644b")
 var body=StaticBody3D.new();var c=CollisionShape3D.new();var sh=BoxShape3D.new();sh.size=Vector3(2,1.2,.7);c.shape=sh;c.position.y=.6;body.add_child(c);holder.add_child(body)
func crop_part(groups,key,mesh,p,scale_v,color,rotation=0.0):
 if not groups.has(key):groups[key]={"mesh":mesh,"color":color,"transforms":[]}
 groups[key].transforms.append(Transform3D(Basis(Vector3.FORWARD,rotation).scaled(scale_v),p))
var crop_models
func make_crops():
 if crop_models==null:crop_models=load("res://scripts/crop_models.gd").new()
 if crop_visuals:crop_visuals.queue_free()
 crop_visuals=Node3D.new();add_child(crop_visuals)
 var groups={}
 for i in range(Farm.max_plots()):
  var record=Farm.data.plots[i]
  if record.crop=="":continue
  var stage=clamp(int(record.growth),0,int(Farm.CROPS[record.crop].days))
  var parts=crop_models.get_model(record.crop,stage)
  var offsets=[]
  if record.crop=="carrot":
   for x in [-.72,-.24,.24,.72]:
    for z in [-.72,-.24,.24,.72]:offsets.append(Vector3(x,.13,z))
  elif record.crop=="tomato":
   for x in [-.55,.55]:
    for z in [-.55,.55]:offsets.append(Vector3(x,.13,z))
  else:offsets.append(Vector3(0,.13,0))
  for offset in offsets:
   var pose=Transform3D(Basis(Vector3.UP,float(i)*.73+offset.x*.3),plots[i].position+offset)
   for j in parts.size():
    var key=record.crop+":"+str(stage)+":"+str(j)
    if not groups.has(key):groups[key]={"mesh":parts[j],"poses":[]}
    groups[key].poses.append(pose)
 for group in groups.values():
  var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=group.mesh;mm.instance_count=group.poses.size()
  for i in group.poses.size():mm.set_instance_transform(i,group.poses[i])
  var inst=MultiMeshInstance3D.new();inst.multimesh=mm;inst.visibility_range_end=100;crop_visuals.add_child(inst)
func drive_blocked(p):
 for area in [[Vector3(-7,0,4),Vector2(4.5,4.0)],[Vector3(24,0,-5),Vector2(5.5,4.0)],[Vector3(48,0,-67),Vector2(4.5,3.5)],[Vector3(62,0,-67),Vector2(4.5,3.5)],[Vector3(76,0,-67),Vector2(4.5,3.5)]]:
  if abs(p.x-area[0].x)<area[1].x and abs(p.z-area[0].z)<area[1].y:return true
 return false
func soft_box(parent,p,size,color,radius=.12):
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);var edge=[]
 var r=min(radius,min(size.x,size.z)*.45)
 for corner in range(4):
  var center=[Vector2(size.x*.5-r,size.z*.5-r),Vector2(-size.x*.5+r,size.z*.5-r),Vector2(-size.x*.5+r,-size.z*.5+r),Vector2(size.x*.5-r,-size.z*.5+r)][corner]
  for j in range(6):
   var a=(corner*90+j*18)*PI/180;edge.append(center+Vector2(cos(a),sin(a))*r)
 for i in range(edge.size()):
  var a=edge[i];var b=edge[(i+1)%edge.size()];var lo=Vector3(a.x,-size.y*.5,a.y);var hi=Vector3(a.x,size.y*.5,a.y);var lb=Vector3(b.x,-size.y*.5,b.y);var hb=Vector3(b.x,size.y*.5,b.y)
  for v in [lo,hi,lb,lb,hi,hb,Vector3(0,size.y*.5,0),hb,hi,Vector3(0,-size.y*.5,0),lo,lb]:st.add_vertex(v)
 st.generate_normals();var o=shape(parent,st.commit(),p,color);o.material_override=mat(color).duplicate();o.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED;return o
func create_truck():
 truck=CharacterBody3D.new();truck.position=Vector3(5,0,14);truck.floor_snap_length=.6;add_child(truck);truck.set_meta("kind","truck");truck.set_meta("title","ขึ้นรถ / ลงรถ · E");targets.append(truck)
 var collision=CollisionShape3D.new();var sh=BoxShape3D.new();sh.size=Vector3(1.8,1.6,3.2);collision.shape=sh;collision.position.y=.8;truck.add_child(collision)
 truck_visual=Node3D.new();truck_visual.set_meta("dynamic",true);truck.add_child(truck_visual)
 soft_box(truck_visual,Vector3(0,.68,0),Vector3(1.72,.5,3.16),"679b8d",.24)
 soft_box(truck_visual,Vector3(0,1.12,-1.03),Vector3(1.68,.34,1.03),"8ab7a3",.23)
 soft_box(truck_visual,Vector3(0,1.42,-.28),Vector3(1.54,.74,1.10),"294b50",.18)
 soft_box(truck_visual,Vector3(0,1.81,-.28),Vector3(1.65,.13,1.23),"dfd8bd",.20)
 for x in [-.79,.79]:
  soft_box(truck_visual,Vector3(x,1.01,-.28),Vector3(.07,.49,1.09),"8ab7a3",.03)
  for z in [-.79,.23]:box(truck_visual,Vector3(x,1.47,z),Vector3(.07,.62,.07),"b7d4bc")
  box(truck_visual,Vector3(x*1.07,1.12,-.19),Vector3(.025,.035,.18),"e5d7b5")
  soft_box(truck_visual,Vector3(x*1.14,1.43,-.72),Vector3(.16,.16,.21),"dfd8bd",.05)
  soft_box(truck_visual,Vector3(x,1.04,1.03),Vector3(.12,.48,1.13),"8ab7a3",.05)
 soft_box(truck_visual,Vector3(0,1.04,1.57),Vector3(1.7,.48,.12),"8ab7a3",.05)
 soft_box(truck_visual,Vector3(0,.96,1.03),Vector3(1.40,.07,1.04),"756b50",.06)
 for x in [-.88,.88]:
  for z in [-1.08,1.07]:
   var wheel=cylinder(truck_visual,Vector3(x,.38,z),.38,.24,"353f3c");wheel.rotation.z=PI/2
   var rim=cylinder(truck_visual,Vector3(x*1.14,.38,z),.22,.035,"d5d2b9");rim.rotation.z=PI/2
   var hub=cylinder(truck_visual,Vector3(x*1.17,.38,z),.08,.04,"718b7e");hub.rotation.z=PI/2
 for z in [-1.61,1.64]:soft_box(truck_visual,Vector3(0,.61,z),Vector3(1.76,.15,.16),"ded6bd",.06)
 soft_box(truck_visual,Vector3(0,.90,-1.596),Vector3(.73,.22,.03),"344b48",.015)
 for x in [-.59,.59]:
  soft_box(truck_visual,Vector3(x,.96,-1.595),Vector3(.29,.22,.045),"fff0c3",.06)
  soft_box(truck_visual,Vector3(x,.96,1.64),Vector3(.18,.24,.04),"c87766",.03)
 batch_static(truck_visual)
 # Separate lenses keep their glow independent of the shared truck materials.
 for x in [-.58,.58]:
  var lamp=SpotLight3D.new();lamp.position=Vector3(x,.96,-1.66);lamp.rotation.x=-.12
  lamp.light_color=Color("fff0c9");lamp.spot_range=24;lamp.spot_angle=28;lamp.spot_attenuation=1.4;lamp.light_energy=2.8;lamp.shadow_enabled=false;lamp.visible=false;truck_visual.add_child(lamp);headlights.append(lamp)
  var lens=soft_box(truck_visual,Vector3(x,.96,-1.63),Vector3(.25,.18,.025),"fff0c3",.04)
  var lens_material=StandardMaterial3D.new();lens_material.albedo_color=Color("fff0c3");lens_material.roughness=.3;lens_material.emission=Color("ffe3ac");lens.material_override=lens_material;headlight_lenses.append(lens)
func update_vehicle_lights():
 var driving=game.playing and game.player!=null and game.player.driving
 lantern.visible=night_light_level>.005 and game.lantern_enabled and not driving
 lantern_model.visible=lantern.visible
 for lamp in headlights:
  lamp.visible=driving and night_light_level>.005;lamp.light_energy=2.8*night_light_level
 for lens in headlight_lenses:
  lens.material_override.emission_enabled=driving and night_light_level>.005
  lens.material_override.emission_energy_multiplier=1.8*night_light_level
func align_truck():
 var front=truck.to_global(Vector3(0,0,-1.08));var back=truck.to_global(Vector3(0,0,1.07))
 var left=truck.to_global(Vector3(-.88,0,0));var right=truck.to_global(Vector3(.88,0,0))
 truck_visual.rotation.x=clamp(atan2(ground(front)-ground(back),2.15),-.35,.35)
 truck_visual.rotation.z=clamp(atan2(ground(right)-ground(left),1.76),-.35,.35)
 truck_visual.position.y=clamp(ground(truck.position)-truck.position.y,-.3,.3)

func rounded_plot(n,color,unlocked):
 # A rounded outline is built from short straight rails and quarter-circle corners.
 var soil=CylinderMesh.new();soil.top_radius=1;soil.bottom_radius=1;soil.height=.10;soil.radial_segments=32
 # Rounded-square mesh with a subtly uneven soil top.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);var edge=[]
 for corner in range(4):
  var center=[Vector2(.97,.97),Vector2(-.97,.97),Vector2(-.97,-.97),Vector2(.97,-.97)][corner]
  for j in range(7):
   var a=(corner*90+j*15)*PI/180;edge.append(Vector3(center.x+cos(a)*.21,.12,center.y+sin(a)*.21))
 for i in range(edge.size()):
  for v in [Vector3(0,.12,0),edge[i],edge[(i+1)%edge.size()]]:st.set_uv(Vector2(v.x,v.z)*.42+Vector2.ONE*.5);st.set_normal(Vector3.UP);st.add_vertex(v)
 shape(n,st.commit(),Vector3.ZERO,color)
 if not unlocked:return
 var rail=SurfaceTool.new();rail.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(edge.size()):
  var a=edge[i];var b=edge[(i+1)%edge.size()];var outer_a=Vector3(a.x*1.075,.24,a.z*1.075);var outer_b=Vector3(b.x*1.075,.24,b.z*1.075)
  var inner_a=Vector3(a.x,.24,a.z);var inner_b=Vector3(b.x,.24,b.z)
  for v in [inner_a,outer_a,outer_b,inner_a,outer_b,inner_b]:rail.set_normal(Vector3.UP);rail.add_vertex(v)
  var bottom_a=Vector3(outer_a.x,.04,outer_a.z);var bottom_b=Vector3(outer_b.x,.04,outer_b.z)
  var normal=Vector3((a+b).x,0,(a+b).z).normalized()
  for v in [outer_a,outer_b,bottom_a,outer_b,bottom_b,bottom_a]:rail.set_normal(normal);rail.add_vertex(v)
 shape(n,rail.commit(),Vector3.ZERO,"96afa0")
 for j in range(12):
  var a=j*2.39;var r=.25+float(j%4)*.2;sphere(n,Vector3(sin(a)*r,.125,cos(a)*r),Vector3(.035,.015,.027),"a58a65")
 batch_static(n)
func setup_lights():
 sun_disc=sphere(self,Vector3(0,140,-270),Vector3.ONE*13,"fff0c2");sun_disc.set_meta("dynamic",true)
 var glow=mat("fff0c2").duplicate();glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;sun_disc.material_override=glow;sun_disc.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 moon_disc=sphere(self,Vector3(120,140,-240),Vector3.ONE*9,"e2e9dd");moon_disc.set_meta("dynamic",true);var moonmat=glow.duplicate();moonmat.albedo_color=Color("e2e9dd");moon_disc.material_override=moonmat
 lantern=OmniLight3D.new();lantern.omni_range=8;lantern.light_color=Color("ffd59c");lantern.light_energy=1.4;lantern.shadow_enabled=false;add_child(lantern)
 lantern_model=Node3D.new();lantern_model.set_meta("dynamic",true);add_child(lantern_model)
 cylinder(lantern_model,Vector3.ZERO,.09,.19,"dfc38a")
 for y in [-.12,.12]:cylinder(lantern_model,Vector3(0,y,0),.11,.035,"79664d")
 for x in [-.075,.075]:box(lantern_model,Vector3(x,0,0),Vector3(.015,.23,.015),"79664d")
 var glass=sphere(lantern_model,Vector3.ZERO,Vector3(.14,.19,.14),"ffe3a7");glass.material_override=glow
 for p in [Vector3(-7,2.2,7.4),Vector3(24,2.1,-1.6),Vector3(48,2.3,-63.4),Vector3(62,2.3,-63.4),Vector3(76,2.3,-63.4)]:
  var lamp=OmniLight3D.new();lamp.position=p;lamp.omni_range=6;lamp.light_color=Color("ffcb82");lamp.light_energy=1.1;lamp.shadow_enabled=false;add_child(lamp);village_lights.append(lamp)
  var bulb=sphere(self,p,Vector3(.16,.24,.16),"ffe3a7");bulb.material_override=glow
func update_daylight(hour,player_position):
 var daylight=clamp(sin((float(hour)-6)/12*PI),0.0,1.0)
 sun.shadow_enabled=int(Farm.settings.quality)>0 and daylight>.015;sun.light_energy=.025+daylight*.55;sun.rotation_degrees=Vector3(-max(8,daylight*65),-30,0)
 var e=environment.environment;e.ambient_light_energy=.045+daylight*.37;e.fog_light_color=Color("18293f").lerp(Color("bbcfdf"),daylight)
 var sky_day=smoothstep(4.8,8.0,float(hour))*(1.0-smoothstep(16.8,20.0,float(hour)))
 var twilight=sin(sky_day*PI)*.45
 sky_material.set_shader_parameter("day_amount",sky_day)
 sky_material.set_shader_parameter("dusk_amount",twilight*2.0)
 e.ambient_light_energy=.035+sky_day*.15+daylight*.12
 sun.light_color=Color("efb17f").lerp(Color("fff0d5"),smoothstep(.02,.6,daylight))
 sun_disc.visible=false
 moon_disc.visible=sky_day<.90
 var night_light=1.0-smoothstep(.12,.70,sky_day)
 night_light_level=night_light
 lantern.light_energy=1.4*night_light
 lantern.position=player_position+Vector3(0,1.5,-.4)
 update_vehicle_lights()
 for lamp in village_lights:lamp.light_energy=1.1*night_light;lamp.visible=night_light>.005 and lamp.position.distance_to(player_position)<20
 if mats.has("93c6c2"):
  mats["93c6c2"].emission_enabled=night_light>.005;mats["93c6c2"].emission=Color("bd8b50");mats["93c6c2"].emission_energy_multiplier=.5*night_light


func shade_tree(p):
 p.y=ground(p)
 nature.place("CommonTree_3",p,8.3,rng.randf()*TAU,true)
 for offset in [Vector3(1.7,0,.9),Vector3(-1.3,0,-1.2)]:
  var q=p+offset;q.y=ground(q);nature.place("Bush_Common",q,.85,rng.randf()*TAU)
 var body=StaticBody3D.new();var c=CollisionShape3D.new();var trunk=CylinderShape3D.new();trunk.radius=.3;trunk.height=3.8;c.shape=trunk;c.position.y=1.9;body.position=p;body.set_meta("tree",true);body.add_child(c);add_child(body)

func batch_plot_visuals():
 if plot_visuals:plot_visuals.queue_free()
 plot_visuals=Node3D.new();plot_visuals.set_meta("dynamic",true);add_child(plot_visuals)
 var groups={}
 for n in plots:
  for o in n.find_children("*","MeshInstance3D",true,false):
   if o.is_queued_for_deletion():continue
   var material=o.material_override;var key=str(material.get_instance_id())
   if not groups.has(key):
    var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);groups[key]={"st":st,"material":material}
   for surface in range(o.mesh.get_surface_count()):groups[key].st.append_from(o.mesh,surface,o.global_transform)
   o.visible=false
 for group in groups.values():
  var mesh=MeshInstance3D.new();mesh.mesh=group.st.commit();mesh.material_override=group.material;plot_visuals.add_child(mesh)
