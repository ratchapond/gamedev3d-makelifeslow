extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func verify(value,message):
 checks+=1
 if not value:failures+=1;push_error(message)
func run():
 var farm=root.get_node("Farm");farm.save_enabled=false
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.start_game(false)
 await process_frame
 g.modal=true;g.lantern_enabled=true;g.world.update_daylight(22,g.player.position)
 verify(g.world.lantern.visible and g.world.lantern_model.visible,"Lantern visible on foot at night")
 verify(not g.world.headlights[0].visible,"Parked truck lights off")
 g.player.driving=true;g.world.update_vehicle_lights()
 verify(not g.world.lantern.visible and not g.world.lantern_model.visible,"Lantern stowed in truck")
 verify(g.lantern_enabled,"Lantern preference preserved")
 for lamp in g.world.headlights:
  verify(lamp.visible and lamp.light_energy>0,"Night driving headlights on")
  verify(lamp.get_parent()==g.world.truck_visual and not lamp.shadow_enabled,"Lights follow truck without extra shadow rendering")
 g.world.truck.rotation.y=PI/2
 var face=(-g.world.headlights[0].global_basis.z).normalized()
 verify(face.dot(-g.world.truck.global_basis.z)>.98,"Headlights point towards truck front when turning")
 g.world.update_daylight(12,g.player.position)
 verify(not g.world.headlights[0].visible,"Day driving lights off")
 g.world.update_daylight(22,g.player.position);g.player.driving=false;g.world.update_vehicle_lights()
 verify(not g.world.headlights[0].visible and g.world.lantern.visible,"Leaving truck restores lantern and switches headlights off")
 g.lantern_enabled=false;g.player.driving=true;g.world.update_vehicle_lights();g.player.driving=false;g.world.update_vehicle_lights()
 verify(not g.world.lantern.visible,"Disabled lantern remains disabled after driving")
 g.player.driving=true;g.world.update_vehicle_lights();g.ui.title_screen()
 verify(not g.world.headlights[0].visible,"Title menu turns off headlights")
 print("VEHICLE_LIGHT_TESTS ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
