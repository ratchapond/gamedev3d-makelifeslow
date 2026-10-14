extends SceneTree
var g
var f
var count=0
var failures=0
func _initialize():call_deferred("run")
func verify(v,msg):
 count+=1
 if not v:failures+=1;push_error("INTEGRATION FAILED: "+msg)
func click(text):
 for b in g.ui.overlay.find_children("*","Button",true,false):
  if b.text==text:b.pressed.emit();return true
 return false
func run():
 f=root.get_node("Farm");f.save_enabled=false
 g=load("res://main.tscn").instantiate();root.add_child(g);g.start_game(false)
 await process_frame
 verify(g.world.plots.size()==36 and g.world.animals.size()==2,"world contains plots and starter animals")
 for animal in g.world.animals.values():
  animal.rotation.y=.7
  var face=(animal.model.global_basis*Vector3.LEFT).normalized();var travel=animal.global_basis.z.normalized()
  verify(face.dot(travel)>.99,"animal mesh faces travel direction")
 for sign in g.world.find_children("*","Label3D",true,false):verify(sign.billboard==BaseMaterial3D.BILLBOARD_DISABLED,"world sign stays fixed")
 var calf=g.world.animals[2];calf.position=Vector3(20,0,10);calf.rotation.y=PI;calf.destination=Vector3(30,0,10);calf.wander=100
 var valid=true
 for i in range(20):
  var previous=calf.position;calf._process(.1);var delta=calf.position-previous;delta.y=0
  if delta.length()>.001 and delta.normalized().dot(calf.global_basis.z.normalized())<.99:valid=false
 verify(valid,"animal moves along face direction while turning")
 var road_clear=true
 for node in g.world.get_children():
  if node is Node3D and node.get_meta("tree",false) and g.world.near_road(node.position):road_clear=false
 verify(road_clear,"trees do not block travel roads")
 g.target=g.world.plots[0];g.tool=0;g.interact();g.tool=2;g.interact();g.tool=1;g.interact()
 verify(f.data.plots[0].crop=="carrot" and f.data.plots[0].water,"target interaction farm loop")
 g.ui.market();var money=f.data.money;var seeds=f.data.seeds.carrot
 verify(click("ซื้อ ฿60"),"shop buy button found")
 verify(f.data.money==money-60 and f.data.seeds.carrot==seeds+5,"shop closure buys correct crop")
 g.ui.close();f.add_good("tomato",5);var before_sale=f.data.money;g.ui.sale_picker("tomato");
 for spin in g.ui.overlay.find_children("*","SpinBox",true,false):spin.value=2
 verify(click("ขายจำนวนที่เลือก"),"quantity sale confirmation button")
 verify(f.qty("tomato")==3 and f.data.money==before_sale+104,"sale leaves unselected produce in bag")
 g.ui.close();g.ui.inventory();g.ui.upgrades();g.ui.journal();g.ui.map_screen();g.ui.settings_screen();g.ui.animal(1);g.ui.credits();g.ui.pause_screen();g.ui.close()
 verify(not g.modal,"closing panels resumes game")
 var event=InputEventKey.new();event.keycode=KEY_V;event.pressed=true;g.player._unhandled_input(event)
 verify(g.player.first_person,"FPS toggle")
 g.target=g.world.truck;g.interact();verify(g.player.driving,"enter vehicle")
 var car_start=g.world.truck.position;Input.action_press("forward")
 for i in range(60):await physics_frame
 Input.action_release("forward");verify(g.world.truck.position.distance_to(car_start)>1,"vehicle physics moves under controls")
 verify(abs(g.player.car_speed)>9.6,"vehicle accelerates beyond triple walking speed")
 g.interact();verify(not g.player.driving,"exit vehicle")
 g.player.position=Vector3(2,1,10)
 for i in range(60):await physics_frame
 verify(g.player.position.y>-.1 and g.player.position.y<.2,"terrain collision holds player at ground")
 var initial=g.player.position
 Input.action_press("forward")
 for i in range(20):await physics_frame
 Input.action_release("forward")
 verify(g.player.position.distance_to(initial)>.5,"WASD input moves character")
 var heading=g.player.yaw;Input.action_press("look_right")
 for i in range(10):await physics_frame
 Input.action_release("look_right");verify(abs(g.player.yaw-heading)>.1,"keyboard look fallback")
 g.world.update_daylight(22,g.player.position);verify(g.world.lantern.visible and g.world.sun.light_energy<.06,"night is dark and lantern lights player")
 g.world.update_daylight(12,g.player.position);verify(not g.world.lantern.visible and g.world.sky_material.get_shader_parameter("day_amount")>.99,"daylight shows photo sky without lantern")
 var route=[Vector3(0,.8,12),Vector3(7,.8,2),Vector3(8,.8,-12),Vector3(22,.8,-28),Vector3(55,.8,-58)]
 var clear_route=true
 for i in range(route.size()-1):
  var ray=PhysicsRayQueryParameters3D.create(route[i],route[i+1]);ray.exclude=[g.player.get_rid(),g.world.truck.get_rid()]
  if not g.world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():clear_route=false
 verify(clear_route,"farm to market road has no walls, fences, benches or trees across it")
 var joy=InputEventJoypadButton.new();joy.button_index=JOY_BUTTON_RIGHT_SHOULDER;joy.pressed=true;var previous_tool=g.tool;g._input(joy);verify(g.using_controller and g.tool==(previous_tool+1)%4,"Xbox input selects tools and changes hints")
 var key=InputEventKey.new();key.keycode=KEY_W;g._input(key);verify(not g.using_controller,"keyboard input automatically restores keyboard hints")
 g.player.position=Vector3(46.2,0,-60);g.update_npc();verify(g.ui.npc_dialog.visible,"nearby NPC greeting appears")
 g.player.position=Vector3.ZERO;g.update_npc();verify(not g.ui.npc_dialog.visible,"NPC greeting hides when walking away")
 # Exercise the same GUI event path as an Xbox controller, including reopened panels.
 g.ui.settings_screen();g.using_controller=true
 await process_frame
 var slider=g.ui.overlay.find_children("*","HSlider",true,false)[0];slider.grab_focus();var old_volume=slider.value
 joy.button_index=JOY_BUTTON_DPAD_LEFT;Input.parse_input_event(joy);await process_frame
 verify(slider.value<old_volume,"Xbox adjusts a settings slider through GUI input")
 var options=g.ui.overlay.find_children("*","OptionButton",true,false)[1];options.grab_focus();var old_quality=options.selected
 joy.button_index=JOY_BUTTON_DPAD_RIGHT;Input.parse_input_event(joy);await process_frame
 verify(options.selected!=old_quality,"Xbox changes quality in settings")
 g.ui.market();await process_frame
 verify(g.ui.focused_control()!=null,"new panel replaces stale focus")
 for b in g.ui.overlay.find_children("*","Button",true,false):
  if b.text=="ซื้อ ฿60":b.grab_focus();break
 var old_seeds=f.data.seeds.carrot
 joy.button_index=JOY_BUTTON_A;Input.parse_input_event(joy);await process_frame
 verify(f.data.seeds.carrot==old_seeds+5,"Xbox A buys chosen shop item")
 f.add_good("tomato",4);g.ui.sale_picker("tomato");await process_frame
 var amount=g.ui.overlay.find_children("*","SpinBox",true,false)[0];amount.grab_focus()
 joy.button_index=JOY_BUTTON_DPAD_RIGHT;Input.parse_input_event(joy);await process_frame
 verify(amount.value==2,"Xbox changes sale quantity")
 joy.button_index=JOY_BUTTON_B;Input.parse_input_event(joy);await process_frame
 verify(not g.modal,"Xbox B closes menu without using a gameplay action")
 for p in [Vector3(83,0,-48),Vector3(100,0,93),Vector3(-125,0,-90)]:
  var ray=PhysicsRayQueryParameters3D.create(p+Vector3.UP*30,p+Vector3.DOWN*20)
  var hit=g.world.get_world_3d().direct_space_state.intersect_ray(ray)
  verify(not hit.is_empty() and abs(hit.position.y-g.world.ground(p))<.01,"terrain height agrees with collision away from props")
 for node in g.world.get_children():
  if node is Node3D and node.get_meta("bench",false):verify(abs(node.position.y-g.world.ground(node.position))<.01,"bench feet follow terrain")
 f.add_animal("cat",0,false);f.add_animal("dog",0,false);g.world.refresh();await process_frame
 var pets=[]
 for node in g.world.animals.values():
  if f.animal_by_id(node.record_id).species in ["cat","dog"]:pets.append(node);node.position=Vector3(3,0,10)
 for i in range(100):
  for pet in pets:pet._process(.05)
 verify(pets[0].position.distance_to(pets[1].position)>1.0,"cat and dog follow separate slots without overlapping")
 var bridge_ray=PhysicsRayQueryParameters3D.create(Vector3(-56,4,34),Vector3(-56,-2,34))
 var bridge_hit=g.world.get_world_3d().direct_space_state.intersect_ray(bridge_ray)
 verify(not bridge_hit.is_empty() and abs(bridge_hit.position.y-.475)<.01,"bridge collision matches visible deck")
 g.player.mouse_rearm_until=0;g.player.mouse_capture_pending=false;var old_yaw=g.player.yaw
 g.player.apply_mouse_look(Vector2(10,0),false)
 verify(g.player.yaw==old_yaw,"unlocked mouse does not rotate camera")
 g.player.apply_mouse_look(Vector2(2000,1000),true)
 verify(g.player.yaw==old_yaw,"pointer recentering spike does not rotate camera")
 g.player.apply_mouse_look(Vector2(20,10),true)
 verify(abs(wrapf(g.player.yaw-old_yaw,-PI,PI)+20*f.settings.sensitivity)<.0001,"screen-pixel mouse movement uses consistent sensitivity")
 g.player.first_person=false;g.player.pitch=.62;g.player.driving=false;g.player._physics_process(.016)
 verify(g.player.camera.position.y>.35,"third-person look-up keeps camera above ground")
 verify(g.player.camera.rotation.x<=.18001,"third-person upward view angle stays within a safe orbit")
 f.data.hour=23.99;var day_before=f.data.day;f.advance_time(.03)
 verify(f.data.day==day_before+1 and abs(f.data.hour-.02)<.0001,"natural midnight retains time remainder instead of jumping to morning")
 g.world.update_daylight(5,Vector3.ZERO);var early=g.world.environment.environment.ambient_light_energy
 g.world.update_daylight(6.2,Vector3.ZERO);var dawn=g.world.environment.environment.ambient_light_energy
 g.world.update_daylight(8,Vector3.ZERO);var morning=g.world.environment.environment.ambient_light_energy
 verify(early<dawn and dawn<morning,"dawn brightens gradually before and after sunrise")
 if failures==0:print("INTEGRATION_TESTS_PASSED ",count)
 else:print("INTEGRATION_TESTS_FAILED ",failures)
 g.queue_free();g=null
 for i in range(3):await process_frame
 quit(0 if failures==0 else 1)
