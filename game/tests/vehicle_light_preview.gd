extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.get_node("Farm").save_enabled=false
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.start_game(false)
 g.modal=true;g.player.driving=true;g.player.yaw=0;g.player.pitch=-.2
 root.get_node("Farm").data.hour=22
 g.ui.toast_time=0
 g.world.update_daylight(22,g.player.position)
 await create_timer(.4).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://vehicle_night_preview.png")
 quit()
