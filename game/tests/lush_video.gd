extends SceneTree
func _initialize():call_deferred("run")
func run():
 var farm=root.get_node("Farm");farm.save_enabled=false
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.start_game(false);g.modal=true;g.ui.toast_time=0
 g.player.set_physics_process(false);g.player.visual.visible=false;g.ui.hud.visible=false;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 farm.data.hour=10
 for frame in range(180):
  var t=float(frame)/180
  var eye=Vector3(-65+t*2.0,3.1,75-t*2.0)
  g.player.position=eye;g.player.camera.global_position=eye;g.player.camera.look_at(Vector3(-77,5.5,57));g.world.update_daylight(10,eye)
  await process_frame
 g.queue_free();await process_frame;await process_frame
 quit()
