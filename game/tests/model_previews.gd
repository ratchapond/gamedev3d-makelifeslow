extends SceneTree
func _initialize():call_deferred("run")
func run():
 var output=ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir()+"/Model_Previews"
 DirAccess.make_dir_recursive_absolute(output)
 var viewport=SubViewport.new();viewport.size=Vector2i(800,800);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_2X;root.add_child(viewport)
 var stage=Node3D.new();viewport.add_child(stage)
 var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;stage.add_child(camera)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-30,0);light.light_energy=1.15;stage.add_child(light)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("d8e2dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("fff0d5");env.environment.ambient_light_energy=.65;stage.add_child(env)
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/manifest.json"))
 for item in manifest:
  var key=str(item.asset);var model=load("res://assets/models/"+key+".glb").instantiate();stage.add_child(model)
  var bounds=AABB();var first=true
  for mesh in model.find_children("*","MeshInstance3D",true,false):
   var b=mesh.global_transform*mesh.get_aabb()
   if first:bounds=b;first=false
   else:bounds=bounds.merge(b)
  var center=bounds.get_center();camera.size=max(bounds.size.y,(bounds.size.x+bounds.size.z)*.8)*1.30
  for view in ["Preview","Side"]:
   camera.position=center+(Vector3(-3,1.5,4) if view=="Preview" else Vector3(0,.6,5));camera.look_at(center)
   await create_timer(.06).timeout;await RenderingServer.frame_post_draw
   viewport.get_texture().get_image().save_png(output+"/"+key+"_"+view+".png")
  stage.remove_child(model);model.queue_free()
 print("MODEL_PREVIEWS_COMPLETE ",output);quit()
