extends RefCounted
var world
var nature
var rng=RandomNumberGenerator.new()
var noise=FastNoiseLite.new()
var grass_count=0
func _init(owner):
 world=owner;nature=load("res://scripts/nature_assets.gd").new(owner);rng.seed=14102026
 noise.seed=9302;noise.frequency=.012;noise.fractal_octaves=3
func occupied(p):
 if world.near_road(p,2.8):return true
 if p.x>-14 and p.x<5 and p.z>-26 and p.z<-7:return true
 for building in [[Vector2(-7,4),Vector2(5,4.5)],[Vector2(24,-5),Vector2(6,4.5)],[Vector2(48,-67),Vector2(5,4.5)],[Vector2(62,-67),Vector2(5,4.5)],[Vector2(76,-67),Vector2(5,4.5)]]:
  if abs(p.x-building[0].x)<building[1].x and abs(p.z-building[0].y)<building[1].y:return true
 if Vector2((p.x+58)/17.5,(p.z-57)/12).length()<1.05:return true
 if abs(p.x-(-62+sin(p.z*.04)*8))<3.3:return true
 return false
func decorate():
 grass_fields()
 # Flower beds and shrub clusters soften otherwise empty stretches.
 for i in range(100):
  var center=[Vector3(-20,0,5),Vector3(-25,0,-25),Vector3(43,0,-42),Vector3(-41,0,60),Vector3(35,0,30)][i%5]
  var p=center+Vector3(rng.randf_range(-8,8),0,rng.randf_range(-6,6))
  if occupied(p):continue
  p.y=world.ground(p)
  var key=["Flower_3_Group","Flower_4_Group","Clover_1","Fern_1"][i%4]
  var height=rng.randf_range(.22,.46);var angle=rng.randf()*TAU
  if i%8 in [4,5]:continue
  nature.place(key,p,height,angle)
 for i in range(18):
  var p=Vector3(rng.randf_range(-38,45),0,rng.randf_range(-48,35))
  if occupied(p) or Vector2(p.x,p.z).length()<12:continue
  p.y=world.ground(p);nature.place("Bush_Common_Flowers" if i%3==0 else "Bush_Common",p,rng.randf_range(.6,1.0),rng.randf()*TAU)
 for i in range(46):
  var a=float(i)/46*TAU;var p=Vector3(-58+cos(a)*18.4,0,57+sin(a)*12.1)
  if world.near_road(p,3.2):continue
  p.y=world.ground(p)
  nature.place("Rock_Medium_"+str(i%3+1),p,rng.randf_range(.35,1.25),rng.randf()*TAU)
  nature.place("Fern_1",p+Vector3(.8,0,.4),.5,rng.randf()*TAU)
 waterfall()
 nature.flush(world)
func grass_fields():
 var groups={}
 for i in range(8000):
  var p=Vector3(rng.randf_range(-132,132),0,rng.randf_range(-132,132))
  if i<6000:p=Vector3(rng.randf_range(-40,48),0,rng.randf_range(-50,36))
  if occupied(p):continue
  # Short tufts only along shoulders, shorelines and sparse woodland edges.
  var shore=Vector2((p.x+58)/17.5,(p.z-57)/12).length()
  var road_edge=world.near_road(p,4.8)
  var woodland=p.z < -42 or p.x < -32 or p.x > 38
  if not road_edge and not (shore>1.05 and shore<1.35) and not woodland:continue
  if not road_edge and shore>1.35 and rng.randf()>.3:continue
  p.y=world.ground(p)+.004
  var key="Grass_Common_Short"
  var prefab=nature.prefab(key);var height=rng.randf_range(.08,.15)
  var scale_v=height/prefab.height
  var placement=Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_v),p+Vector3(0,-prefab.bottom*scale_v,0))
  for j in prefab.items.size():
   var batch=key+":"+str(j)+":"+str(int(floor(p.x/28)))+":"+str(int(floor(p.z/28)))
   if not groups.has(batch):groups[batch]={"mesh":prefab.items[j].mesh,"transforms":[],"colors":[]}
   groups[batch].transforms.append(placement*prefab.items[j].transform);groups[batch].colors.append(Color(rng.randf(),0,0,rng.randf()))
  grass_count+=1
 var grass_material=ShaderMaterial.new();grass_material.shader=load("res://assets/environment/grass_wind.gdshader");grass_material.set_shader_parameter("leaf_texture",load("res://assets/environment/nature/Grass.png"))
 for group in groups.values():
  var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_custom_data=true;mm.mesh=group.mesh;mm.instance_count=group.transforms.size()
  for i in group.transforms.size():mm.set_instance_transform(i,group.transforms[i]);mm.set_instance_custom_data(i,group.colors[i])
  var node=MultiMeshInstance3D.new();node.multimesh=mm;node.material_override=grass_material;node.visibility_range_end=90;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.set_meta("grass",true);world.add_child(node)
func mountain_y(x,z,center,height):
 var q=Vector2((x-center.x)/135.0,(z-center.z)/115.0)
 var radial=exp(-q.length_squared()*2.8)
 var ridges=abs(noise.get_noise_2d(x,z))
 var side=exp(-pow((q.x-.45)*2.7,2)-pow((q.y+.13)*2.2,2))*.27
 return max(0.0,height*(radial*(.81+ridges*.24)+side)-7.0)
func mountains():
 # Distant scenery only: the playable map bounds remain unchanged.
 for i in range(2):
  var center=Vector3(-110+i*195,0,-315-i*45);var height=100.0+i*28.0
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for ix in range(70):
   for iz in range(62):
    var corners=[Vector2(ix,iz),Vector2(ix+1,iz),Vector2(ix,iz+1),Vector2(ix+1,iz+1)]
    for j in [0,1,2,1,3,2]:
     var x=center.x-180+corners[j].x*5.15;var z=center.z-155+corners[j].y*5.0
     var h=mountain_y(x,z,center,height)
     var normal=Vector3(mountain_y(x-1,z,center,height)-mountain_y(x+1,z,center,height),2,mountain_y(x,z-1,center,height)-mountain_y(x,z+1,center,height)).normalized()
     var rock=smoothstep(.26,.65,1-normal.y);var snow=smoothstep(height*.68,height*.88,h+noise.get_noise_2d(x*2,z*2)*8)
     var color=Color("6b8471").lerp(Color("879496"),rock).lerp(Color("d7e1dc"),snow)
     st.set_color(color);st.set_normal(normal);st.add_vertex(Vector3(x,h-2,z))
  var node=MeshInstance3D.new();node.mesh=st.commit();var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.vertex_color_is_srgb=true;material.roughness=1;node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.set_meta("mountain",true);world.add_child(node)
func waterfall():
 var center=Vector3(-86,0,57)
 # A supported stone ledge links the upper basin to the falling water.
 var cliff=SurfaceTool.new();cliff.begin(Mesh.PRIMITIVE_TRIANGLES)
 for iz in range(20):
  for iy in range(10):
   var vertices=[]
   for q in [Vector2(iz,iy),Vector2(iz+1,iy),Vector2(iz,iy+1),Vector2(iz+1,iy+1)]:
    var z=49+q.x*.8;var y=q.y*1.1
    var x=min(-75.35,-76.2+noise.get_noise_2d(z*11,y*11)*1.8+sin(z*1.3+y*.6)*.35)
    vertices.append(Vector3(x,y,z))
   for j in [0,2,1,1,2,3]:
    var v=vertices[j];var patch=clamp(noise.get_noise_2d(v.z*8,v.y*8)*.8+.5,0,1)
    cliff.set_color(Color("738572").lerp(Color("9ca690"),patch));cliff.set_uv(Vector2(v.z,v.y)*.22);cliff.add_vertex(v)
 cliff.generate_normals();var face=MeshInstance3D.new();face.mesh=cliff.commit();var rock_material=StandardMaterial3D.new();rock_material.albedo_texture=load("res://assets/environment/cliff_rock.jpg");rock_material.albedo_color=Color("a6b9ac");rock_material.normal_enabled=true;rock_material.normal_texture=load("res://assets/environment/cliff_normal.jpg");rock_material.normal_scale=.6;rock_material.roughness=1;rock_material.diffuse_mode=BaseMaterial3D.DIFFUSE_LAMBERT_WRAP;rock_material.cull_mode=BaseMaterial3D.CULL_DISABLED;face.material_override=rock_material;world.add_child(face)
 var ledge_top=world.soft_box(world,Vector3(-82,10.65,57),Vector3(14,.7,16),"697868",1.15)
 for z in [50.0,57.0,64.0]:nature.place("Rock_Medium_2",Vector3(-75.8,10.9,z),.7,0.0)
 for i in range(14):
  var p=Vector3(-82+rng.randf_range(-4,3),11.0,57+(-5.6 if i%2==0 else 5.6))
  nature.place("Rock_Medium_"+str(i%3+1),p,rng.randf_range(.5,1.3),rng.randf()*TAU)
  nature.place("Fern_1",p+Vector3(.5,.1,.1),.65,rng.randf()*TAU)
 for i in range(14):
  var p=center+Vector3(rng.randf_range(-5,-1),0,rng.randf_range(-10,10));p.y=world.ground(p)-.4
  nature.place("Rock_Medium_"+str(i%3+1),p,rng.randf_range(7,13),rng.randf()*TAU,true)
 var pool_mesh=PlaneMesh.new();pool_mesh.size=Vector2(10,9)
 var pool=MeshInstance3D.new();pool.mesh=pool_mesh;pool.position=Vector3(-80,11.02,57);var pool_material=ShaderMaterial.new();pool_material.shader=load("res://assets/environment/lake.gdshader");pool.material_override=pool_material;pool.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;pool.set_meta("dynamic",true);world.add_child(pool)
 # Broad upper ledge and two narrower streams descend into the lake.
 for offset in [-2.0,2.0]:
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for y in range(24):
   var t=float(y)/24;var t2=float(y+1)/24
   var top=Vector3(-74.8+t*1.4,11.1*(1-t)-.10,57+offset)
   var bottom=Vector3(-74.8+t2*1.4,11.1*(1-t2)-.10,57+offset)
   for j in [0,1,2,1,3,2]:
    var verts=[top+Vector3(0,0,-1.5),top+Vector3(0,0,1.5),bottom+Vector3(0,0,-1.65),bottom+Vector3(0,0,1.65)]
    st.set_uv([Vector2(0,t),Vector2(1,t),Vector2(0,t2),Vector2(1,t2)][j]);st.set_normal(Vector3.RIGHT);st.add_vertex(verts[j])
  var sheet=MeshInstance3D.new();sheet.mesh=st.commit();var material=ShaderMaterial.new();material.shader=load("res://assets/environment/waterfall.gdshader");sheet.material_override=material;sheet.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;sheet.set_meta("dynamic",true);world.add_child(sheet)
 var blocker=StaticBody3D.new();var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(20,13,22);collision.shape=shape;blocker.position=center+Vector3(-1,6,0);blocker.add_child(collision);world.add_child(blocker)
 for i in range(24):
  var p=Vector3(-73+rng.randf_range(-.4,1.8),-.06+rng.randf()*.10,57+rng.randf_range(-4.5,4.5))
  var foam=world.sphere(world,p,Vector3(.5,.12,.36)*rng.randf_range(.5,1.4),"cde9df");foam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var spray=CPUParticles3D.new();spray.position=Vector3(-73.5,.15,57);spray.amount=64;spray.lifetime=1.4;spray.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;spray.emission_box_extents=Vector3(.3,.05,3.7);spray.direction=Vector3(1,1,0);spray.spread=45;spray.gravity=Vector3(0,-2.6,0);spray.initial_velocity_min=1.0;spray.initial_velocity_max=2.2;spray.scale_amount_min=.05;spray.scale_amount_max=.14;spray.color=Color("dbeee9");var droplet=SphereMesh.new();droplet.radial_segments=8;droplet.rings=4;droplet.material=world.mat("dbeee9");spray.mesh=droplet;spray.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;spray.set_meta("dynamic",true);world.add_child(spray)
 for i in range(8):
  var p=center+Vector3(rng.randf_range(-6,6),0,(-1 if i%2==0 else 1)*rng.randf_range(17,21))
  p.y=world.ground(p);nature.place("CommonTree_4",p,rng.randf_range(7,10),rng.randf()*TAU,true)
