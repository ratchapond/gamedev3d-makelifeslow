extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func verify(value,message):
 checks+=1
 if not value:failures+=1;push_error("SLOW_LIFE: "+message)
func run():
 var farm=root.get_node("Farm");farm.save_enabled=false
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.start_game(false)
 await process_frame
 var benches=[]
 for n in g.world.targets:
  if n.get_meta("kind","")=="bench":benches.append(n)
 verify(benches.size()==3,"All existing benches become seats")
 var names=["player","seed","carpenter","livestock"]
 for species in ["cow","chicken","duck","goat","sheep","pig","cat","dog"]:
  for stage in ["young","adult"]:names.append(species+"_"+stage)
 for name in names:
  var model=load("res://assets/models/"+name+".glb").instantiate();root.add_child(model)
  var ap=model.find_child("AnimationPlayer",true,false)
  verify(ap!=null and ap.has_animation("Idle") and ap.has_animation("Walk"),name+" keeps gameplay clips")
  var has_blink=false
  for mesh in model.find_children("*","MeshInstance3D",true,false):
   for i in mesh.mesh.get_blend_shape_count():
    if mesh.mesh.get_blend_shape_name(i)=="Blink":has_blink=true
  verify(has_blink,name+" has an actual Blink morph")
  model.queue_free()
 var old_money=farm.data.money
 g.target=benches[0];g.interact()
 verify(g.player.seated and not g.player.first_person,"E sits in third-person")
 verify(g.player.ap.current_animation=="Sit","Seat uses authored skeletal animation")
 verify(g.player.collision_mask==0,"Seat avoids fighting bench collision")
 g.player._physics_process(.016)
 verify(not g.player.hand_tool.visible,"Held tool is stowed while resting")
 g.save();var p=farm.data.player
 verify(Vector3(p[0],p[1],p[2]).is_equal_approx(g.player.seat_exit_position),"Save restores a safe standing position")
 g.ui.update_hud();verify(g.ui.prompt.text.contains("ลุก"),"Seat has a stand-up hint")
 g.interact();verify(not g.player.seated and g.player.collision_mask==1,"E restores walking and collision")
 g.player.sit_on_bench(benches[0]);Input.action_press("forward");g.player._physics_process(.016);Input.action_release("forward")
 verify(not g.player.seated,"WASD stands up")
 g.player.sit_on_bench(benches[0]);g.start_game(false)
 verify(not g.player.seated and g.player.visual.position.is_zero_approx(),"Starting a game clears seated pose")
 var animal=g.world.animals.values()[0];animal.wander=0;animal.resting=false;animal._process(.1)
 verify(animal.resting and animal.pause_remaining>0,"Livestock pause between destinations")
 var before=animal.position;animal._process(.1)
 verify(animal.position.distance_to(before)<.001,"Grazing does not slide over the ground")
 var life=g.player.visual.find_children("*","Node",true,false).filter(func(n):return n.get_script() and n.get_script().resource_path.ends_with("character_life.gd"))
 verify(not life.is_empty(),"Player gets a life controller")
 if not life.is_empty():
  g.modal=false;life[0].blinking=true;life[0].blink_clock=.075;life[0]._process(.008)
  verify(not life[0].eyes.is_empty(),"Life controller resolves the imported morph")
  if not life[0].eyes.is_empty():verify(life[0].eyes[0].mesh.get_blend_shape_value(life[0].eyes[0].index)>.8,"Blink deforms the actual model")
  for i in range(100):life[0]._process(.016)
  var head=life[0].skeleton.get_bone_pose_rotation(life[0].head)
  verify(is_finite(head.x) and abs(head.length()-1.0)<.001,"Additive gaze stays normalized")
 verify(farm.data.money==old_money,"Cosmetic interactions preserve economy")
 print("SLOW_LIFE_TESTS ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
