extends SceneTree
func _initialize():call_deferred("run")
func run():
 var farm=root.get_node("Farm");farm.save_enabled=false
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.start_game(false);g.modal=true
 g.player.position=Vector3(2,.1,10);g.player.yaw=-.35;g.player.pitch=-.12
 farm.data.hour=10;g.world.update_daylight(10,g.player.position)
 farm.settings.fps_limit=0;farm.settings.fullscreen=false;farm.settings.resolution=1
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 for quality in [1,0,1,0]:
  farm.settings.quality=quality;g.apply_settings()
  await create_timer(2).timeout
  var start=Time.get_ticks_usec();var frames=0;var cpu=0.0
  while Time.get_ticks_usec()-start<3000000:
   await process_frame;frames+=1;cpu+=Performance.get_monitor(Performance.TIME_PROCESS)*1000
  print("QUALITY_AB ",JSON.stringify({"quality":quality,"fps":frames/((Time.get_ticks_usec()-start)/1000000.0),"cpu_ms":cpu/max(1,frames),"scale":root.scaling_3d_scale,"draw":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"gpu":g.gpu_info}))
 quit()
