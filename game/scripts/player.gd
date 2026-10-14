extends CharacterBody3D
var game
var yaw=0.0
var pitch=-.15
var first_person=false
var camera
var visual
var ap
var speed=0.0
var driving=false
var action_time=0.0
var hand_tool
var shown_tool=-1
var attachment
var body_tool
var look_drag=false
var car_speed=0.0
var camera_distance=4.5
var mouse_rearm_until=0
var mouse_capture_pending=false
var seated=false
var seat_bench
var seat_exit_position=Vector3.ZERO
func reset_mouse_capture():
 mouse_rearm_until=Time.get_ticks_msec()+80;mouse_capture_pending=true;look_drag=false
func apply_mouse_look(delta,locked,dragging=false):
 if not locked and not dragging:return
 if Time.get_ticks_msec()<mouse_rearm_until or not delta.is_finite():return
 if mouse_capture_pending:mouse_capture_pending=false;return
 # Ignore re-centering spikes; ordinary movement uses unscaled screen pixels.
 if delta.length()>900:return
 yaw=wrapf(yaw-delta.x*float(Farm.settings.sensitivity),-PI,PI)
 pitch=clamp(pitch-delta.y*float(Farm.settings.sensitivity)*(-1 if Farm.settings.invert_y else 1),-1.05,.62)
func _ready():
 var c=CollisionShape3D.new();var cap=CapsuleShape3D.new();cap.radius=.3;cap.height=1.65;c.shape=cap;c.position.y=.85;add_child(c)
 visual=load("res://assets/models/player.glb").instantiate();add_child(visual);ap=visual.find_child("AnimationPlayer",true,false)
 visual.rotation.y=PI
 var skeletons=visual.find_children("*","Skeleton3D",true,false)
 if not skeletons.is_empty():
  attachment=BoneAttachment3D.new();attachment.bone_name="HandR";skeletons[0].add_child(attachment)
 var life=load("res://scripts/character_life.gd").new();visual.add_child(life);life.setup(visual,game,true,721)
 camera=Camera3D.new();camera.fov=70;camera.far=900;add_child(camera);camera.current=true
func tool_visual():
 if shown_tool==game.tool:return
 shown_tool=game.tool
 if hand_tool:hand_tool.queue_free()
 hand_tool=Node3D.new();camera.add_child(hand_tool);hand_tool.position=Vector3(.38,-.40,-.65)
 match game.tool:
  0:
   game.world.box(hand_tool,Vector3(0,.08,0),Vector3(.035,.70,.035),"98734f")
   game.world.box(hand_tool,Vector3(0,.40,-.08),Vector3(.20,.025,.16),"778c87")
  1:
   game.world.cylinder(hand_tool,Vector3.ZERO,.13,.23,"78a09c")
   var spout=game.world.box(hand_tool,Vector3(-.17,.02,0),Vector3(.25,.05,.05),"78a09c");spout.rotation.z=.35
   game.world.box(hand_tool,Vector3(.15,.08,0),Vector3(.035,.25,.035),"78a09c")
  2:
   game.world.box(hand_tool,Vector3.ZERO,Vector3(.20,.25,.07),"dfc79b")
   game.world.sphere(hand_tool,Vector3(0,0,-.045),Vector3(.07,.10,.01),"7fa169")
  3:
   game.world.box(hand_tool,Vector3.ZERO,Vector3(.30,.19,.20),"aa8b5d")
   for x in [-.14,.14]:game.world.box(hand_tool,Vector3(x,.16,0),Vector3(.025,.17,.03),"c0a174")
   game.world.box(hand_tool,Vector3(0,.24,0),Vector3(.30,.025,.03),"c0a174")
 if attachment:
  if body_tool:body_tool.queue_free()
  body_tool=hand_tool.duplicate();body_tool.position=Vector3.ZERO;body_tool.rotation=Vector3.ZERO;body_tool.scale=Vector3.ONE*.7;attachment.add_child(body_tool)
func use_animation():
 action_time=.7
 if ap:
  for a in ap.get_animation_list():
   if "Use" in a:ap.play(a,.1);break
func _unhandled_input(event):
 if not game.playing or game.modal:return
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:look_drag=event.pressed
 if event is InputEventMouseMotion:
  var locked=Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and (not OS.has_feature("web") or game.web_pointer_locked)
  apply_mouse_look(event.screen_relative,locked,look_drag)
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_V and not seated:first_person=not first_person
func _physics_process(dt):
 if not game or not game.playing:return
 tool_visual();hand_tool.visible=first_person and not driving;hand_tool.rotation.x=-sin(action_time*6)*.22
 if body_tool:body_tool.visible=not first_person and not driving
 var front=Vector3(-sin(yaw),0,-cos(yaw));var right=Vector3(cos(yaw),0,-sin(yaw))
 var input=Vector2.ZERO
 if not game.modal:input=Input.get_vector("left","right","back","forward")
 if not game.modal and game.controller_move.length()>.12:input=Vector2(game.controller_move.x,-game.controller_move.y)
 if not game.modal:
  yaw-=(Input.get_axis("look_left","look_right")+game.controller_look.x)*dt*1.8
  pitch=clamp(pitch+(Input.get_axis("look_down","look_up")-game.controller_look.y)*dt*1.3,-1.05,.62)
 camera.rotation=Vector3(pitch if first_person or driving else min(pitch,.18),yaw,0)
 if seated:
  velocity=Vector3.ZERO;visual.visible=true;hand_tool.visible=false
  if body_tool:body_tool.visible=false
  camera.position=Vector3(0,1.25,0)-Vector3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))*3.8
  if input.length()>.1:stand_from_bench()
  return
 if driving:
  var car=game.world.truck
  if not game.modal:
   car_speed=move_toward(car_speed,input.y*(16.0 if input.y>=0 else 7.0),dt*(10.0 if abs(input.y)>.05 else 14.0))
   car.rotation.y-=input.x*dt*1.35*clamp(abs(car_speed)/4.0,0,1)*sign(car_speed)
   var dir=Vector3(-sin(car.rotation.y),0,-cos(car.rotation.y));car.velocity.x=dir.x*car_speed;car.velocity.z=dir.z*car_speed
   if not car.is_on_floor():car.velocity.y-=18*dt
   else:car.velocity.y=0
   car.move_and_slide();car.position.x=clamp(car.position.x,-132,132);car.position.z=clamp(car.position.z,-132,132)
  game.world.align_truck()
  position=car.position+Vector3(0,.3,0);visual.visible=false
  camera.position=Vector3(0,3.6,0)-front*6.5
  return
 var dir=(front*input.y+right*input.x)
 speed=5.4 if (Input.is_action_pressed("sprint") or (game.using_controller and Input.is_joy_button_pressed(0,JOY_BUTTON_LEFT_STICK))) else 3.2
 velocity.x=dir.x*speed;velocity.z=dir.z*speed
 if not is_on_floor():velocity.y-=18*dt
 else:velocity.y=0
 move_and_slide();position.x=clamp(position.x,-136,136);position.z=clamp(position.z,-136,136)
 if position.y<-3:position.y=game.world.ground(position)+1
 visual.visible=not first_person
 if dir.length()>.1:visual.rotation.y=lerp_angle(visual.rotation.y,atan2(dir.x,dir.z),dt*9)
 action_time=max(0,action_time-dt)
 if ap and action_time<=0:
  var wanted="Walk" if dir.length()>.1 else "Idle"
  for a in ap.get_animation_list():
   if wanted in a and ap.current_animation!=a:ap.get_animation(a).loop_mode=Animation.LOOP_LINEAR;ap.play(a,.18);break
 var focus=Vector3(0,1.5,0)
 var orbit_pitch=min(pitch,.18)
 camera.position=focus if first_person else focus-Vector3(-sin(yaw)*cos(orbit_pitch),sin(orbit_pitch),-cos(yaw)*cos(orbit_pitch))*camera_distance+right*.6
 # Camera collision prevents going through house walls in third-person.
 if not first_person:
  var from=global_position+focus;var to=global_position+camera.position
  var query=PhysicsRayQueryParameters3D.create(from,to);query.exclude=[get_rid()]
  var hit=get_world_3d().direct_space_state.intersect_ray(query)
  if not hit.is_empty():camera.global_position=hit.position+(from-hit.position).normalized()*.15
func interact_direction():return Vector3(-sin(yaw),0,-cos(yaw))

func sit_on_bench(bench):
 if driving or seated:return
 seated=true;seat_bench=bench;first_person=false;collision_mask=0;velocity=Vector3.ZERO
 seat_exit_position=bench.to_global(Vector3(0,0,-1.0));seat_exit_position.y=game.world.ground(seat_exit_position)+.1
 global_position=bench.to_global(Vector3(0,0,-.08));visual.position.y=-.12
 visual.rotation.y=bench.global_rotation.y+PI;yaw=bench.global_rotation.y;pitch=-.12
 if ap:
  for anim in ap.get_animation_list():
   if "Sit" in anim:ap.get_animation(anim).loop_mode=Animation.LOOP_LINEAR;ap.play(anim,.3);break

func stand_from_bench():
 if not seated:return
 seated=false;collision_mask=1;global_position=seat_exit_position;visual.position=Vector3.ZERO;seat_bench=null
 if ap:
  for anim in ap.get_animation_list():
   if "Idle" in anim:ap.play(anim,.25);break
