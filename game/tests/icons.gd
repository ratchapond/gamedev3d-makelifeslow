extends SceneTree
var stage
func _initialize():call_deferred("run")
func run():
 var viewport=SubViewport.new();viewport.size=Vector2i(192,192);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 stage=Node3D.new();viewport.add_child(stage)
 var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.8;camera.position=Vector3(-3,2.0,4);stage.add_child(camera);camera.look_at(Vector3(0,.8,0))
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=1.3;stage.add_child(light)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("fff0d5");env.environment.ambient_light_energy=.65;stage.add_child(env)
 DirAccess.make_dir_recursive_absolute("res://assets/icons")
 for kind in ["cow","chicken","sheep","goat","pig","duck","dog","cat"]:
  var animal=load("res://assets/models/"+kind+"_young.glb").instantiate();stage.add_child(animal)
  var bounds=AABB();var first=true
  for mesh in animal.find_children("*","MeshInstance3D",true,false):
   var b=mesh.global_transform*mesh.get_aabb()
   if first:bounds=b;first=false
   else:bounds=bounds.merge(b)
  var center=bounds.get_center();camera.size=max(bounds.size.y*1.35,(bounds.size.x+bounds.size.z)*.85)*1.18
  camera.position=center+Vector3(-3,1.8,4);camera.look_at(center)
  await create_timer(.2).timeout
  await RenderingServer.frame_post_draw
  viewport.get_texture().get_image().save_png("res://assets/icons/"+kind+".png")
  stage.remove_child(animal);animal.queue_free()
 quit()
