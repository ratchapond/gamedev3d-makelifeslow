extends SceneTree
func _initialize():call_deferred("run")
func run():
 var farm=root.get_node("Farm");farm.save_enabled=false;root.get_node("Lang").set_language("th")
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.start_game(false);g.modal=true;g.ui.toast_time=0
 farm.data.farm_level=2
 for i in range(36):
  var crop=["carrot","tomato","pumpkin"][int(i/12)]
  farm.data.plots[i]={"tilled":true,"crop":crop,"growth":farm.CROPS[crop].days,"water":true}
 g.world.refresh();g.player.set_physics_process(false);g.player.visual.visible=false;g.ui.hud.visible=false
 var views=[
  ["farm",Vector3(-26,9,22),Vector3(-7,1,-5),10.0],
  ["garden",Vector3(-16,3,-3),Vector3(-5,.5,-17),10.0],
  ["valley",Vector3(5,2.6,13),Vector3(0,13,-140),10.0],
  ["sunset",Vector3(-26,9,22),Vector3(-7,1,-5),17.3],
  ["waterfall",Vector3(-65,3.1,75),Vector3(-77,5.5,57),10.0],
  ["meadow",Vector3(-18,1.8,12),Vector3(-22,2,-22),10.0]]
 for view in views:
  farm.data.hour=view[3];g.player.position=view[1];g.player.camera.global_position=view[1];g.player.camera.look_at(view[2]);g.world.update_daylight(view[3],view[1])
  await create_timer(.5).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://art_"+view[0]+"_preview.png")
 print("ART_REVIEW_RENDERED")
 quit()
