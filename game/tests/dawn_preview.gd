extends SceneTree
func _initialize():call_deferred("run")
func run():
 var farm=root.get_node("Farm");farm.save_enabled=false
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.start_game(false);g.modal=true;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 g.player.position=Vector3(4,.1,14);g.player.yaw=-.35;g.player.pitch=-.12
 for hour in [4.8,5.6,6.4,7.2]:
  farm.data.hour=hour;g.world.update_daylight(hour,g.player.position)
  await create_timer(.2).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://dawn_"+str(hour).replace(".","_")+"_preview.png")
 quit()
