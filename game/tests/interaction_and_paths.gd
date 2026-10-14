extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func verify(value,message):
 checks+=1
 if not value:failures+=1;push_error("INTERACTION_PATHS: "+message)
func drag(widget,value):
 var motion=InputEventMouseMotion.new();motion.position=Vector2(widget.rail().position.x,widget.rail().position.y+value*widget.rail().size.y)
 widget._gui_input(motion)
func run():
 var farm=root.get_node("Farm");farm.save_enabled=false
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.start_game(false)
 await process_frame
 g.modal=true
 # Audit the transformed mesh bounds of every actual shrub/flower instance.
 var shrub_count=0;var foliage_count=0;var overlaps=0
 for node in g.world.get_children():
  if not node is MultiMeshInstance3D:continue
  var key=str(node.get_meta("nature_asset",""))
  if not (key.begins_with("Bush_") or key.begins_with("Flower_") or key.begins_with("Fern_") or key.begins_with("Clover_")):continue
  var mm=node.multimesh;var bounds=mm.mesh.get_aabb()
  for i in mm.instance_count:
   foliage_count+=1
   if key.begins_with("Bush_"):shrub_count+=1
   var transform=node.transform*mm.get_instance_transform(i)
   for corner in range(8):
    if g.world.road_clearance(transform*bounds.get_endpoint(corner))<.449:overlaps+=1
 verify(shrub_count>20 and foliage_count>100,"Roadside scenery is retained")
 verify(overlaps==0,"All placed shrub and flower mesh bounds leave a 45 cm road verge")
 var nature=g.world.nature
 verify(not nature.place("Bush_Common_Flowers",Vector3(38,0,-42),1.05,.8),"Reported bush in the middle of the farm road is rejected")
 verify(nature.place("Bush_Common_Flowers",Vector3(33,0,-44),1.05,.8),"Moved flowering bush fits beside the road")
 verify(not nature.place("Bush_Common",Vector3(62,0,-55),1.5,1.2),"Bush crown cannot intrude onto the wider village road")
 verify(not nature.place("Bush_Common",Vector3(-26,0,35),.85,2.1),"Lake path bend stays open")
 var cow=farm.animal_by_id(2);cow.age=3;cow.product=2;g.world.refresh()
 var actor=g.world.animals[2];actor.position=Vector3(20,0,8);actor.resting=true;actor.pause_remaining=100
 g.player.position=Vector3(20,0,10);g.player.yaw=0
 g.target=g.world.animals[1];g.modal=false
 # Feed a real layout-mismatched key through Godot's event dispatch.
 var key=InputEventKey.new();key.keycode=0x0e33;key.physical_keycode=KEY_E;key.pressed=true
 Input.parse_input_event(key);await process_frame
 verify(g.modal and g.ui.title_label.text=="วัว","Physical E on a Thai layout opens the animal in front, replacing a stale target")
 var old_overlay=g.ui.overlay;key.echo=true;Input.parse_input_event(key);await process_frame
 verify(g.ui.overlay==old_overlay,"Held E does not toggle or rebuild animal care")
 g.ui.start_milking(2);await process_frame
 var mini=g.ui.active_milking
 verify(is_instance_valid(mini),"Cow care starts the milking minigame")
 verify(farm.qty("milk")==0 and cow.product==2,"Opening the game grants no milk")
 mini.move_handle(.04);mini.move_handle(.09)
 verify(mini.rounds==0,"Small mouse jitter cannot count as a full gesture")
 mini.move_handle(1);mini.move_handle(0);g.ui.close()
 verify(farm.qty("milk")==0 and cow.product==2,"Cancel preserves all milk on the cow")
 # Late signals from a closed UI must never award anything.
 mini.finished=true;mini.completed.emit()
 verify(farm.qty("milk")==0,"A cancelled session cannot reward a late completion")
 g.ui.start_milking(2);await process_frame;mini=g.ui.active_milking
 var press=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.position=mini.knob();mini._gui_input(press)
 drag(mini,1);drag(mini,0)
 verify(mini.rounds==1 and farm.qty("milk")==0,"Actual held mouse down/up counts once without early reward")
 for i in range(3):drag(mini,1);drag(mini,0)
 verify(mini.finished and farm.qty("milk")==2 and cow.product==0,"Four gestures collect existing milk exactly once")
 mini.move_handle(1);mini.move_handle(0);mini.completed.emit()
 verify(farm.qty("milk")==2,"Finished gestures and duplicate signals cannot duplicate rewards")
 g.ui.start_milking(2)
 verify(g.ui.active_milking==null,"Empty cows cannot start another reward session")
 cow.product=4;cow.breed=1;farm.data.bag={};farm.add_good("feed",farm.bag_capacity()-1)
 g.ui.start_milking(2);await process_frame;mini=g.ui.active_milking
 for i in range(4):mini.move_handle(1);mini.move_handle(0)
 verify(farm.qty("milk_premium")==1 and cow.product==3,"Premium milk and partial bag capacity preserve the remaining product")
 g.ui.start_milking(2)
 verify(g.ui.active_milking==null,"Full bags cannot start a session")
 farm.data.bag={};g.ui.start_milking(2);await process_frame;mini=g.ui.active_milking
 var touch=InputEventScreenTouch.new();touch.index=3;touch.pressed=true;touch.position=mini.knob();mini._gui_input(touch)
 var motion=InputEventScreenDrag.new();motion.index=4;motion.position=mini.rail().end;mini._gui_input(motion)
 verify(not mini.returning,"Unrelated touch fingers cannot move the handle")
 motion.index=3;mini._gui_input(motion)
 verify(mini.returning,"The captured touch finger can drag down")
 mini._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 verify(mini.touch_id==-1 and not mini.dragging,"Leaving the window releases a held gesture")
 g.ui.close()
 print("INTERACTION_PATHS_TESTS ",checks," checks, ",failures," failures; ",shrub_count," shrub instances, ",foliage_count," foliage instances audited")
 quit(1 if failures else 0)
