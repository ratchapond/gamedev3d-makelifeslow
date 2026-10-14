extends Node3D
var world
var player
var audio
var ui
var playing=false
var modal=true
var tool=0
var target
var waypoint=Vector3.ZERO
var autosave=0.0
var footsteps=0.0
var smoke=false
var pointer_lost=0.0
var had_pointer_lock=false
var fallback_notice=false
var pointer_elapsed=0.0
var render_check=0.0
var gpu_info=""
var controller_move=Vector2.ZERO
var controller_look=Vector2.ZERO
var using_controller=false
var npc_near
var pointer_poll=0.0
var daylight_timer=0.0
var hud_timer=0.0
var trigger_held=false
var lantern_enabled=true
var quality_test=false
var web_pointer_locked=false
var scene_review=false
var visitors
func _ready():
 if OS.has_feature("web"):
  var bridge=Engine.get_singleton("JavaScriptBridge")
  if bridge:
   quality_test=bool(bridge.eval("new URLSearchParams(location.search).has('qualitytest')"))
   scene_review=bool(bridge.eval("new URLSearchParams(location.search).has('review')"))
 if quality_test or scene_review:Farm.save_enabled=false
 for pair in [["forward",KEY_W],["back",KEY_S],["left",KEY_A],["right",KEY_D],["sprint",KEY_SHIFT],["look_left",KEY_LEFT],["look_right",KEY_RIGHT],["look_up",KEY_UP],["look_down",KEY_DOWN]]:
  if not InputMap.has_action(pair[0]):InputMap.add_action(pair[0])
  var key=InputEventKey.new();key.physical_keycode=pair[1];InputMap.action_add_event(pair[0],key)
 if "--smoke" in OS.get_cmdline_user_args():Farm.save_enabled=false
 smoke="--smoke" in OS.get_cmdline_user_args()
 world=load("res://scripts/world.gd").new();add_child(world);world.build(self)
 player=load("res://scripts/player.gd").new();player.game=self;add_child(player);player.position=Vector3(2,1,10)
 audio=load("res://scripts/audio.gd").new();add_child(audio)
 ui=load("res://scripts/ui.gd").new();ui.game=self;add_child(ui)
 visitors=load("res://scripts/visitors.gd").new();visitors.game=self;add_child(visitors)
 Farm.changed.connect(on_change);Farm.notice.connect(func(t):ui.toast(t))
 ui.title_screen()
 apply_settings()
 gpu_info=read_gpu_info()
 if smoke or quality_test:start_game(false)
 else:
  player.visual.visible=false;player.position=Vector3(9,8,24);player.camera.global_position=Vector3(12,10,26);player.camera.look_at(Vector3(0,0,-8))
 if "--capture" in OS.get_cmdline_user_args():capture_later()
 if "--gallery" in OS.get_cmdline_user_args():gallery()
 if "--benchmark" in OS.get_cmdline_user_args():benchmark()
 if quality_test:web_quality_test()
 elif scene_review:
  var review=load("res://scripts/review_characters.gd").new();add_child(review);review.setup(self)
func web_quality_test():
 modal=true;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;AudioServer.set_bus_mute(0,true)
 player.position=Vector3(2,.1,10);player.yaw=-.35;player.pitch=-.12
 Farm.data.hour=10;world.update_daylight(10,player.position)
 Farm.settings.fps_limit=0;Farm.settings.resolution=1;Farm.settings.show_fps=true
 var results=[]
 for quality in [1,0,1,0]:
  Farm.settings.quality=quality;apply_settings()
  await get_tree().create_timer(2).timeout
  var start=Time.get_ticks_usec();var frames=0;var cpu=0.0
  while Time.get_ticks_usec()-start<3000000:
   await get_tree().process_frame;frames+=1;cpu+=Performance.get_monitor(Performance.TIME_PROCESS)*1000
  var result={"quality":quality,"fps":frames/((Time.get_ticks_usec()-start)/1000000.0),"cpu_ms":cpu/max(1,frames),"scale":get_viewport().scaling_3d_scale,"draw":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"gpu":gpu_info}
  results.append(result);print("WEB_QUALITY_AB ",JSON.stringify(result))
 ui.window(Lang.t("ผลเทียบคุณภาพภาพ"),Lang.t("กล้อง เวลาและความละเอียดเดียวกัน · ไม่บันทึกทับเซฟ"))
 for result in results:ui.body.add_child(ui.label((Lang.t("ภาพสูง") if result.quality>0 else Lang.t("ภาพต่ำ"))+" · %.1f FPS · CPU %.1f ms · Draw %d · Scale %.2f"%[result.fps,result.cpu_ms,result.draw,result.scale],20))
 ui.body.add_child(ui.label(gpu_info,14))
func read_gpu_info():
 if OS.has_feature("web"):
  var bridge=Engine.get_singleton("JavaScriptBridge")
  if bridge:
   return str(bridge.eval("(function(){try{var c=document.getElementById('canvas');var g=c.getContext('webgl2');var d=g.getExtension('WEBGL_debug_renderer_info');return d?g.getParameter(d.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER);}catch(e){return 'WebGL renderer unavailable';}})()"))
 return RenderingServer.get_video_adapter_name()
func benchmark():
 Farm.save_enabled=false;modal=true;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;AudioServer.set_bus_mute(0,true)
 await get_tree().create_timer(2.0).timeout
 var start=Time.get_ticks_usec();var frames=0;var cpu=0.0;var physics=0.0
 while Time.get_ticks_usec()-start<4000000:
  await get_tree().process_frame;frames+=1;cpu+=Performance.get_monitor(Performance.TIME_PROCESS)*1000;physics+=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000
 print("PERFORMANCE_REPORT ",JSON.stringify({"fps":frames/((Time.get_ticks_usec()-start)/1000000.0),"process_ms":cpu/max(1,frames),"physics_ms":physics/max(1,frames),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"gpu":gpu_info}))
 get_tree().quit()
func gallery():
 Farm.save_enabled=false
 await get_tree().create_timer(.5).timeout
 player.yaw=-.35;player.pitch=-.12
 await shot("farm")
 ui.market();await shot("market");ui.close()
 Farm.data.barn_level=2
 for sp in ["sheep","goat","pig","duck","cat","dog"]:Farm.add_animal(sp,0,false)
 for a in Farm.data.animals:a.age=5
 world.reset_actors()
 player.position=Vector3(18,.1,15);player.yaw=-.65;player.pitch=-.20;player.first_person=true
 await shot("animals")
 ui.settings_screen();await shot("settings");ui.close()
 player.position=Vector3(62,.1,-52);player.yaw=0;player.pitch=-.1;player.first_person=true
 await shot("village")
 player.position=Vector3(82,world.ground(Vector3(82,0,-44)),-44);player.yaw=.4;player.pitch=-.30
 await shot("bench")
 player.position=Vector3(-51,world.ground(Vector3(-51,0,40)),40);player.yaw=1.2;player.pitch=-.30
 await shot("brook")
 player.position=Vector3(9,.1,18);player.yaw=.75;player.pitch=-.26
 await shot("truck")
 Farm.data.farm_level=2
 for i in range(36):
  var keys=["carrot","tomato","pumpkin"];var k=keys[int(i/12)];Farm.data.plots[i]={"tilled":true,"crop":k,"growth":Farm.CROPS[k].days,"water":true}
 world.refresh();player.position=Vector3(0,.1,-6);player.yaw=.80;player.pitch=-.43;player.camera_distance=5.5;player.first_person=false
 await shot("crops")
 Farm.data.hour=22;world.update_daylight(22,player.position);await shot("night")
 Farm.data.hour=10;world.update_daylight(10,player.position);ui.title_screen();player.position=Vector3(9,8,24);player.camera.global_position=Vector3(12,10,26);player.camera.look_at(Vector3(0,0,-8));await shot("title")
 get_tree().quit()
func shot(name):
 await get_tree().create_timer(.7).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://"+name+"_preview.png")
func capture_later():
 await get_tree().create_timer(2.0).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://preview.png")
 get_tree().quit()
func start_game(continue_game):
 if continue_game:
  if not Farm.load_game():ui.toast(Lang.t("อ่านเซฟไม่สำเร็จ กรุณาเริ่มเกมใหม่หรือเก็บไฟล์เซฟไว้ก่อน"));return
 else:Farm.new_game()
 if player.seated:player.stand_from_bench()
 var p=Farm.data.player;player.position=Vector3(float(p[0]),max(.1,float(p[1])),float(p[2]));player.yaw=0;player.driving=false;player.car_speed=0;player.collision_layer=1;player.collision_mask=1
 had_pointer_lock=false;fallback_notice=false;pointer_elapsed=0;pointer_lost=0
 visitors.reset()
 var car=Farm.data.get("truck",[5,0,14,0]);world.truck.position=Vector3(car[0],car[1],car[2]);world.truck.rotation.y=car[3]
 world.reset_actors();playing=true;modal=false;ui.close();ui.hud.visible=true;audio.start();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 ui.toast(Lang.t("ยินดีต้อนรับ · 1–4 เปลี่ยนเครื่องมือ · E โต้ตอบ · V สลับมุมกล้อง"),6)
func on_change():
 world.refresh()
 ui.update_hud()
 if playing:save()
func _input(event):
 if event is InputEventJoypadButton or (event is InputEventJoypadMotion and abs(event.axis_value)>.22):using_controller=true
 elif event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length()>2):using_controller=false
 # Physical E also works on Thai keyboard layouts; handle before GUI focus.
 if event is InputEventKey and event.pressed and not event.echo and playing and not modal:
  if event.physical_keycode==KEY_E or (event.physical_keycode==0 and event.keycode==KEY_E):
   update_target();interact();get_viewport().set_input_as_handled();return
 if event is InputEventJoypadButton and event.pressed:
  if event.button_index==JOY_BUTTON_START:
   if playing:
    if modal:ui.close()
    else:ui.pause_screen()
   return
  if event.button_index==JOY_BUTTON_B and playing and modal:ui.close();get_viewport().set_input_as_handled();return
  if not playing or modal:return
  get_viewport().set_input_as_handled()
  match event.button_index:
   JOY_BUTTON_A:update_target();interact()
   JOY_BUTTON_X:use_tool()
   JOY_BUTTON_Y:ui.inventory()
   JOY_BUTTON_BACK:ui.map_screen()
   JOY_BUTTON_RIGHT_SHOULDER:tool=(tool+1)%4
   JOY_BUTTON_LEFT_SHOULDER:tool=(tool+3)%4
   JOY_BUTTON_RIGHT_STICK:player.first_person=not player.first_person
   JOY_BUTTON_DPAD_UP:lantern_enabled=not lantern_enabled
func poll_controller():
 controller_move=Vector2.ZERO;controller_look=Vector2.ZERO
 var devices=Input.get_connected_joypads()
 if devices.is_empty():return
 var id=devices[0]
 controller_move=Vector2(Input.get_joy_axis(id,JOY_AXIS_LEFT_X),Input.get_joy_axis(id,JOY_AXIS_LEFT_Y))
 controller_look=Vector2(Input.get_joy_axis(id,JOY_AXIS_RIGHT_X),Input.get_joy_axis(id,JOY_AXIS_RIGHT_Y))
 if controller_move.length()<.18:controller_move=Vector2.ZERO
 else:controller_move=controller_move.limit_length()
 if controller_look.length()<.18:controller_look=Vector2.ZERO
 var trigger=Input.get_joy_axis(id,JOY_AXIS_TRIGGER_RIGHT)>.65
 if trigger and not trigger_held and playing and not modal:use_tool()
 trigger_held=trigger
func update_npc():
 npc_near=null
 var distance=4.5
 for n in world.targets:
  if not is_instance_valid(n) or not n.get_meta("kind","") in ["market","livestock","upgrade"]:continue
  var d=n.global_position.distance_to(player.global_position)
  if d<distance:distance=d;npc_near=n
 if visitors.nearby() and visitors.actor.global_position.distance_to(player.global_position)<distance:npc_near=visitors.actor
 ui.npc_dialog.visible=npc_near!=null and not modal and not player.driving
 if npc_near:
  if npc_near.get_meta("kind","")=="visitor":
   var offer=visitors.events.state().active
   npc_near=null if offer.is_empty() else npc_near
   if offer.is_empty():ui.npc_dialog.visible=false;return
   ui.npc_text.text=Lang.t("ผู้มาเยือนอยากคุยด้วย")+(Lang.t(" · A คุย") if using_controller else Lang.t(" · E คุย"));return
  var greetings={"market":Lang.t("เมล็ดพร้อมแล้ว แวะเลือกของหรือขายผลผลิตได้เลยนะ"), "livestock":Lang.t("วันนี้จะพาเพื่อนตัวใหม่กลับฟาร์มไหม?"), "upgrade":Lang.t("ค่อย ๆ แต่งฟาร์มให้น่าอยู่กันเถอะ")}
  ui.npc_text.text=greetings[npc_near.get_meta("kind")]+(Lang.t("\nA · เปิดร้าน") if using_controller else Lang.t("\nE · เปิดร้าน"))
func _unhandled_input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:
   if not playing:return
   if modal:ui.close()
   else:ui.pause_screen()
  if not playing or modal:return
  match event.keycode:
   KEY_1,KEY_2,KEY_3,KEY_4:tool=int(event.keycode-KEY_1);ui.update_hud()
   KEY_I:ui.inventory()
   KEY_M:ui.map_screen()
   KEY_F5:save();ui.toast(Lang.t("บันทึกเกมแล้ว"))
   KEY_L:lantern_enabled=not lantern_enabled
   KEY_F3:Farm.settings.show_fps=not Farm.settings.show_fps
 if event is InputEventMouseButton and event.pressed and playing and not modal:
  if event.button_index==MOUSE_BUTTON_LEFT:use_tool()
  elif event.button_index==MOUSE_BUTTON_WHEEL_UP:tool=(tool+3)%4;ui.update_hud()
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:tool=(tool+1)%4;ui.update_hud()
func _process(dt):
 poll_controller()
 render_check+=dt
 if render_check>1.0:render_check=0;update_render_scale()
 if not playing:return
 if not modal:
  pointer_poll+=dt
  if OS.has_feature("web") and pointer_poll>.05:
   pointer_poll=0
   var bridge=Engine.get_singleton("JavaScriptBridge")
   var locked=bool(bridge.eval("document.pointerLockElement !== null")) if bridge else false
   if locked and not web_pointer_locked:player.reset_mouse_capture()
   web_pointer_locked=locked
   if locked:had_pointer_lock=true
   elif had_pointer_lock:ui.pause_screen();had_pointer_lock=false
  Farm.advance_time(dt/30.0)
  autosave+=dt
  if autosave>35:autosave=0;save()
  update_target()
  daylight_timer+=dt
  if daylight_timer>.25:daylight_timer=0;world.update_daylight(float(Farm.data.hour),player.global_position)
  world.lantern.position=player.global_position+Vector3(0,1.5,-.4)
  world.lantern_model.global_position=player.camera.global_position+player.camera.global_basis*Vector3(-.35,-.36,-.60) if player.first_person else player.global_position+Vector3(-.30,.9,0)
  update_npc()
  footsteps-=dt
  if player.velocity.length()>1 and footsteps<=0 and not player.driving:footsteps=.42;audio.play_sfx("step",-9)
 hud_timer+=dt
 if hud_timer>.1:hud_timer=0;ui.update_hud()
func update_target():
 target=null
 if player.seated:target=player.seat_bench;return
 if player.driving:target=world.truck;return
 var dir=player.interact_direction();var best=10.0
 for n in world.targets:
  if not is_instance_valid(n):continue
  var delta=n.global_position-player.global_position;delta.y=0;var dist=delta.length()
  var kind=n.get_meta("kind","")
  if kind=="visitor" and (n.departing or visitors.events.state().active.is_empty()):continue
  if kind=="plot" and int(n.get_meta("id"))>=Farm.max_plots():continue
  var reach=4.2 if kind in ["market","livestock","upgrade","truck","visitor"] else 2.8
  if dist>reach:continue
  var dot=dir.dot(delta.normalized())
  if dot<.15 and dist>.9:continue
  var score=dist+(1-dot)*2
  if score<best:best=score;target=n
func use_tool():
 if not target:return
 if target.get_meta("kind")=="plot":
  Farm.use_plot(int(target.get_meta("id")),tool);audio.play_sfx("water" if tool==1 else "harvest")
  player.use_animation()
 else:interact()
func interact():
 if player.seated:player.stand_from_bench();return
 if player.driving:
  player.driving=false;player.car_speed=0;player.collision_layer=1;player.collision_mask=1;world.truck.velocity=Vector3.ZERO;player.position=world.truck.position+Vector3(2.4,.3,0);world.update_vehicle_lights();return
 if not target and npc_near:target=npc_near
 if not target:ui.toast(Lang.t("เข้าใกล้สิ่งของหรือสัตว์ แล้วหันกล้องไปหา"));return
 match target.get_meta("kind"):
  "plot":use_tool()
  "bed":ui.confirm(Lang.t("พักผ่อนถึงเช้า?"),Lang.t("พืชที่รดน้ำและสัตว์ที่ให้อาหารจะเติบโต พร้อมบันทึกเกม"),func():ui.sleep_transition())
  "market":ui.market()
  "livestock":ui.livestock()
  "upgrade":ui.upgrades()
  "animal":ui.animal(int(target.get_meta("id")))
  "visitor":ui.visitor(int(target.get_meta("id")))
  "guide":ui.journal()
  "bench":player.sit_on_bench(target);ui.toast(Lang.t("นั่งพักชมวิว · หมุนกล้องได้ · E หรือ WASD ลุก"),5)
  "truck":player.driving=true;player.car_speed=0;player.collision_layer=0;player.collision_mask=0;world.update_vehicle_lights();ui.toast(Lang.t("W/S ขับรถ · A/D เลี้ยว · E ลงรถ"))
  "trough":
   for a in Farm.data.animals:Farm.feed_animal(int(a.id))
   audio.play_sfx("harvest")
func save():
 var saved_position=player.seat_exit_position if player.seated else player.position
 Farm.data.player=[saved_position.x,saved_position.y,saved_position.z];var car=world.truck;Farm.data.truck=[car.position.x,car.position.y,car.position.z,car.rotation.y]
 if Farm.save_enabled:Farm.save_game()
func apply_settings():
 if audio:audio.apply_settings()
 Engine.max_fps=int(Farm.settings.fps_limit)
 if player:player.camera.fov=float(Farm.settings.fov)
 DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if Farm.settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
 if world and world.sun:world.sun.shadow_enabled=int(Farm.settings.quality)>0
 get_viewport().msaa_3d=Viewport.MSAA_2X if int(Farm.settings.quality)>0 else Viewport.MSAA_DISABLED
 update_render_scale()
 if ui:ui.update_glass()
 Farm.save_settings()
func update_render_scale():
 var size=get_viewport().get_texture().get_size();var pixels=max(1,float(size.x)*size.y)
 var cap=int(Farm.settings.resolution)==1 or (int(Farm.settings.resolution)==0 and OS.has_feature("web"))
 var budget=960.0*540.0 if int(Farm.settings.quality)==0 and int(Farm.settings.resolution)==0 else 1280.0*720.0
 get_viewport().scaling_3d_scale=clamp(sqrt(budget/pixels),.35,1.0) if cap else 1.0
func _notification(what):
 if what==NOTIFICATION_WM_CLOSE_REQUEST and playing:save()
