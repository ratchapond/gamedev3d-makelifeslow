extends CanvasLayer
var game
var root
var hud
var stats
var prompt
var tool_line
var toast_label
var toast_time=0.0
var overlay
var body
var title_label
var map
var nav
var npc_dialog
var npc_text
var help
var theme
var menu_repeat=0.0
var active_milking
const TOOLS=["จอบ","บัวรดน้ำ","เมล็ดพันธุ์","ตะกร้า"]

func _ready():
 theme=Theme.new();theme.default_font_size=17
 if ResourceLoader.exists("res://assets/fonts/NotoSansThai.ttf"):theme.default_font=load("res://assets/fonts/NotoSansThai.ttf")
 theme.set_color("font_color","Label",Color("f2ead5"));theme.set_color("font_color","Button",Color("f4ead4"));theme.set_color("font_hover_color","Button",Color("ffffff"))
 for state in ["normal","hover","pressed","focus","disabled"]:
  theme.set_stylebox(state,"Button",style("55745f" if state in ["hover","focus"] else "324c40" if state=="normal" else "253b30",10))
 theme.set_stylebox("panel","PanelContainer",style("20362e45",22))
 root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.theme=theme;root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
 hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(hud);hud.visible=false
 var stat_panel=PanelContainer.new();stat_panel.position=Vector2(24,22);stat_panel.size=Vector2(290,93);stat_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(stat_panel);glass(stat_panel)
 stats=Label.new();stats.text="";stat_panel.add_child(stats)
 map=load("res://scripts/minimap.gd").new();map.game=game;map.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);map.position=Vector2(-192,22);map.size=Vector2(168,168);map.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(map)
 nav=Label.new();nav.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);nav.position=Vector2(-255,194);nav.size=Vector2(230,40);nav.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;nav.add_theme_font_size_override("font_size",15);hud.add_child(nav)
 var cross=Label.new();cross.text="+";cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER);cross.position=Vector2(-8,-16);cross.add_theme_color_override("font_color",Color("fff0c5"));cross.add_theme_font_size_override("font_size",25);hud.add_child(cross)
 prompt=Label.new();prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);prompt.position=Vector2(-350,-142);prompt.size=Vector2(700,40);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(prompt)
 tool_line=HBoxContainer.new();tool_line.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);tool_line.position=Vector2(-290,-85);tool_line.size=Vector2(580,58);tool_line.add_theme_constant_override("separation",8);hud.add_child(tool_line)
 for i in range(4):
  var b=button(str(i+1)+"  "+TOOLS[i],func():game.tool=i;update_hud());b.custom_minimum_size=Vector2(139,48);b.focus_mode=Control.FOCUS_NONE;tool_line.add_child(b)
 help=Label.new();help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);help.position=Vector2(24,-34);help.text=Lang.t("WASD เดิน  •  Shift วิ่ง  •  V FPS/TPS  •  I กระเป๋า  •  M แผนที่  •  Esc เมนู");help.add_theme_font_size_override("font_size",13);help.add_theme_color_override("font_color",Color("e2ead4"));hud.add_child(help)
 toast_label=Label.new();toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);toast_label.position=Vector2(-370,115);toast_label.size=Vector2(740,50);toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast_label.add_theme_font_size_override("font_size",19);toast_label.add_theme_color_override("font_outline_color",Color("23372e"));toast_label.add_theme_constant_override("outline_size",6);root.add_child(toast_label);toast_label.z_index=10
 npc_dialog=PanelContainer.new();npc_dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);npc_dialog.position=Vector2(-280,-255);npc_dialog.size=Vector2(560,95);npc_dialog.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(npc_dialog);glass(npc_dialog);npc_text=label("",18);npc_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;npc_dialog.add_child(npc_text);npc_dialog.visible=false

func style(color,radius):
 var s=StyleBoxFlat.new();s.bg_color=Color(color);s.corner_radius_top_left=radius;s.corner_radius_top_right=radius;s.corner_radius_bottom_left=radius;s.corner_radius_bottom_right=radius;s.border_width_left=1;s.border_width_right=1;s.border_width_top=1;s.border_width_bottom=1;s.border_color=Color(1,1,.92,.18);s.shadow_color=Color(0,.025,.015,.2);s.shadow_size=5;s.content_margin_left=18;s.content_margin_right=18;s.content_margin_top=12;s.content_margin_bottom=12;return s
func button(text,callback):
 var b=Button.new();b.text=Lang.t(text);b.custom_minimum_size.y=43;b.pressed.connect(callback);return b
func label(text,size=17):
 var l=Label.new();l.text=Lang.t(text);l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;return l
func toast(text,duration=3.5):toast_label.text=Lang.t(text);toast_time=duration
func _process(dt):
 toast_time=max(0,toast_time-dt);toast_label.visible=toast_time>0;toast_label.position=Vector2(-370,16 if game.modal else 115)
 menu_repeat=max(0.0,menu_repeat-dt)
 if game.using_controller and overlay and not overlay.is_queued_for_deletion():
  ensure_focus()
  var sticks=Input.get_connected_joypads()
  if not sticks.is_empty() and menu_repeat<=0:
   var v=Vector2(Input.get_joy_axis(sticks[0],JOY_AXIS_LEFT_X),Input.get_joy_axis(sticks[0],JOY_AXIS_LEFT_Y))
   if abs(v.y)>.55:navigate_menu(1 if v.y>0 else -1);menu_repeat=.20
   elif abs(v.x)>.55:adjust_control(1 if v.x>0 else -1);menu_repeat=.16
func glass(panel):
 var bg=ColorRect.new();bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;bg.show_behind_parent=true
 var material=ShaderMaterial.new();material.shader=load("res://assets/glass.gdshader");bg.material=material;panel.add_child(bg)
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 bg.resized.connect(func():material.set_shader_parameter("panel_size",bg.size))
 material.set_shader_parameter("blur_pixels",1.8 if int(Farm.settings.quality)>0 else 0.0)
 bg.set_meta("glass",true)
func update_glass():
 for bg in root.find_children("*","ColorRect",true,false):
  if bg.get_meta("glass",false):bg.material.set_shader_parameter("blur_pixels",1.8 if int(Farm.settings.quality)>0 else 0.0)
func menu_controls():
 var controls=[]
 if not overlay:return controls
 for c in overlay.find_children("*","Control",true,false):
  if not c.is_visible_in_tree() or c.is_queued_for_deletion():continue
  if c is BaseButton and not c.disabled:controls.append(c)
  elif c is HSlider or c is SpinBox:controls.append(c)
 return controls
func focused_control():
 var c=get_viewport().gui_get_focus_owner()
 while c and not (c is BaseButton or c is HSlider or c is SpinBox):c=c.get_parent()
 return c if c and overlay and overlay.is_ancestor_of(c) else null
func ensure_focus():
 if focused_control():return
 var controls=menu_controls()
 if not controls.is_empty():controls[0].grab_focus()
func navigate_menu(direction):
 var controls=menu_controls()
 if controls.is_empty():return
 var index=controls.find(focused_control());controls[posmod(index+direction,controls.size())].grab_focus()
func adjust_control(direction):
 var c=focused_control()
 if c is OptionButton:
  c.select(posmod(c.selected+direction,c.item_count));c.item_selected.emit(c.selected)
 elif c is Range:c.value=clamp(c.value+direction*(c.step if c is SpinBox else (c.max_value-c.min_value)/20.0),c.min_value,c.max_value)
func activate_control():
 var c=focused_control()
 if c is OptionButton:adjust_control(1)
 elif c is BaseButton:
  if c.toggle_mode:c.button_pressed=not c.button_pressed
  c.pressed.emit()
func _input(event):
 if not overlay or overlay.is_queued_for_deletion() or not game.modal:return
 if event is InputEventJoypadMotion and abs(event.axis_value)>.22:game.using_controller=true;ensure_focus()
 if event is InputEventKey or event is InputEventMouseButton:game.using_controller=false
 if not event is InputEventJoypadButton or not event.pressed:return
 game.using_controller=true;ensure_focus()
 match event.button_index:
  JOY_BUTTON_DPAD_DOWN:navigate_menu(1)
  JOY_BUTTON_DPAD_UP:navigate_menu(-1)
  JOY_BUTTON_DPAD_LEFT:adjust_control(-1)
  JOY_BUTTON_DPAD_RIGHT:adjust_control(1)
  JOY_BUTTON_A:activate_control()
  JOY_BUTTON_B,JOY_BUTTON_START:
   if game.playing:close()
  _:return
 menu_repeat=.22;get_viewport().set_input_as_handled()
func update_hud():
 if Farm.data.is_empty():return
 stats.text=Lang.t("วันที่ %d · %02d:%02d · %s\n฿ %d   |   แปลง %d   |   สัตว์ %d/%d")%[Farm.data.day,int(Farm.data.hour),int(fmod(float(Farm.data.hour),1)*60),Farm.season(),Farm.data.money,Farm.max_plots(),Farm.barn_count(),Farm.capacity()]
 if Farm.settings.show_fps:stats.text+="  ·  %d FPS"%Engine.get_frames_per_second()
 if Farm.settings.show_fps:stats.text+="\nFrame %.1f ms · Physics %.1f ms · Draw %d"%[Performance.get_monitor(Performance.TIME_PROCESS)*1000,Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
 help.text=Lang.t("L เดิน · R มอง · A คุย · X ใช้ · LB/RB เครื่องมือ · Y กระเป๋า · ↑ ตะเกียง · Start พัก") if game.using_controller else Lang.t("WASD เดิน · Shift วิ่ง · V FPS/TPS · I กระเป๋า · M แผนที่ · L ตะเกียง · Esc พัก")
 if game.target and is_instance_valid(game.target):
  prompt.text=(("X / A · " if game.using_controller else Lang.t("คลิก / E · "))+Lang.t(TOOLS[game.tool]) if game.target.get_meta("kind")=="plot" else ("A · " if game.using_controller else "E · ")+Lang.t(game.target.get_meta("title")))
  if game.target.get_meta("kind")=="plot":
   var p=Farm.data.plots[int(game.target.get_meta("id"))]
   if p.crop!="":prompt.text+=" · "+Lang.t(Farm.CROPS[p.crop].title)+" · "+(Lang.t("พร้อมเก็บ") if p.growth>=Farm.CROPS[p.crop].days else Lang.t("กำลังเติบโต"))+" · "+(Lang.t("รดแล้ว") if p.water else Lang.t("ยังไม่รดน้ำ"))
 else:prompt.text=""
 if game.player.seated:prompt.text=Lang.t("ลุกจากม้านั่ง · E หรือ WASD")
 for i in range(4):
  tool_line.get_child(i).modulate=Color("ffe5a1") if game.tool==i else Color.WHITE
  tool_line.get_child(i).text=str(i+1)+"  "+Lang.t(TOOLS[i])
 tool_line.get_child(2).text="3  "+Lang.t(Farm.CROPS[Farm.data.selected_seed].title)+" (%d)"%int(Farm.data.seeds.get(Farm.data.selected_seed,0))
 if game.waypoint!=Vector3.ZERO:
  var delta=game.waypoint-game.player.position;var angle=atan2(delta.x,-delta.z)+game.player.yaw;var idx=posmod(int(round(angle/TAU*8)),8)
  nav.text=["↑","↗","→","↘","↓","↙","←","↖"][idx]+Lang.t(" เป้าหมาย · %dm")%int(delta.length())
 elif game.visitors and is_instance_valid(game.visitors.actor) and not game.visitors.actor.departing:
  nav.text=Lang.t("ผู้มาเยือน · %dm")%int(game.visitors.actor.global_position.distance_to(game.player.global_position))
 else:nav.text=Lang.t("M เปิดแผนที่")

func close():
 active_milking=null
 if overlay:overlay.visible=false;overlay.queue_free();overlay=null
 game.modal=not game.playing
 if game.playing:game.player.reset_mouse_capture();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 else:title_screen()
func window(title,subtitle=""):
 active_milking=null
 if overlay:overlay.visible=false;overlay.queue_free()
 game.modal=true;npc_dialog.visible=false;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(overlay)
 var veil=ColorRect.new();veil.color=Color(0.06,.11,.09,.66);veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(veil)
 var panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER);panel.position=Vector2(-420,-290);panel.size=Vector2(840,580);overlay.add_child(panel);glass(panel);menu_repeat=.25
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",12);panel.add_child(column)
 var heading=HBoxContainer.new();column.add_child(heading);title_label=label(title,28);heading.add_child(title_label);var exit=button(Lang.t("ปิด · Esc") if game.playing else Lang.t("กลับหน้าหลัก"),close);heading.add_child(exit);exit.visible=title!="Make Life Slower"
 if subtitle!="":column.add_child(label(subtitle,15))
 var sc=ScrollContainer.new();sc.follow_focus=true;sc.size_flags_vertical=Control.SIZE_EXPAND_FILL;sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(sc)
 body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);sc.add_child(body)
 column.add_child(label(Lang.t("จอย: D-pad / ก้าน เลือก · ซ้าย/ขวา ปรับค่า · A ยืนยัน · B กลับ"),13))
func row(title,description,action,callback):
 var p=PanelContainer.new();p.add_theme_stylebox_override("panel",style("31493b7a",14));body.add_child(p)
 var h=HBoxContainer.new();h.add_theme_constant_override("separation",15);p.add_child(h)
 var v=VBoxContainer.new();v.size_flags_horizontal=Control.SIZE_EXPAND_FILL;h.add_child(v);v.add_child(label(title,20));v.add_child(label(description,14))
 var icon_key=""
 for key in Farm.SPECIES:
  if Lang.t(title).begins_with(Lang.t(Farm.SPECIES[key].title)):icon_key=key;break
 for key in Farm.CROPS:
  if Lang.t(title).begins_with(Lang.t(Farm.CROPS[key].title)):icon_key=key;break
 if icon_key=="":
  for key in Farm.GOODS:
   if Lang.t(title).begins_with(Lang.t(Farm.GOODS[key][0])):icon_key=key;break
 if icon_key=="":
  for pair in [[Lang.t("พื้นที่เพาะปลูก"),"farm"],[Lang.t("อุปกรณ์รดน้ำ"),"tool"],[Lang.t("บ้านสวน"),"home"],[Lang.t("คอกสัตว์"),"barn"],[Lang.t("อาหารสัตว์"),"feed"]]:
   if title.begins_with(pair[0]):icon_key=pair[1]
 if icon_key!="" and ResourceLoader.exists("res://assets/icons/"+icon_key+".png"):
  var picture=TextureRect.new();picture.texture=load("res://assets/icons/"+icon_key+".png");picture.custom_minimum_size=Vector2(76,76);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;h.add_child(picture);h.move_child(picture,0)
 if action!="":var b=button(action,callback);b.custom_minimum_size.x=155;h.add_child(b)

func title_screen():
 game.playing=false;hud.visible=false;game.player.visual.visible=false;game.player.position=Vector3(9,8,24);game.player.camera.global_position=Vector3(12,10,26);game.player.camera.look_at(Vector3(0,0,-8));game.world.update_daylight(10,game.player.position);game.modal=true;npc_dialog.visible=false;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if overlay:overlay.visible=false;overlay.queue_free()
 overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(overlay)
 var wash=ColorRect.new();wash.color=Color(.06,.15,.12,.35);wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(wash)
 var column=VBoxContainer.new();column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT);column.position=Vector2(80,-290);column.size=Vector2(460,490);column.add_theme_constant_override("separation",18);overlay.add_child(column)
 var mark=label("ALPINE FARM",18);mark.add_theme_color_override("font_color",Color("f3dfa6"));column.add_child(mark)
 var logo=label("Make Life\nSlower",70);logo.add_theme_color_override("font_color",Color("fff4d9"));logo.add_theme_color_override("font_outline_color",Color("294537"));logo.add_theme_constant_override("outline_size",3);column.add_child(logo);var ornament=TextureRect.new();ornament.texture=load("res://assets/icons/title_sprout.svg");ornament.custom_minimum_size=Vector2(440,40);ornament.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;ornament.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;column.add_child(ornament)
 column.add_child(label(Lang.t("ชีวิตเล็ก ๆ ในหุบเขาแห่งนี้"),20))
 var b=button(Lang.t("เล่นต่อ"),func():game.start_game(true));b.disabled=not Farm.has_save();column.add_child(b)
 column.add_child(button(Lang.t("เริ่มชีวิตใหม่"),func():
  if Farm.has_save():confirm(Lang.t("เริ่มเกมใหม่?"),Lang.t("เซฟเดิมจะถูกแทนที่เมื่อเล่นและบันทึก"),func():game.start_game(false))
  else:game.start_game(false)))
 column.add_child(button(Lang.t("ตั้งค่า"),settings_screen))
 var links=HBoxContainer.new();column.add_child(links);links.add_child(button(Lang.t("วิธีเล่น"),controls));links.add_child(button(Lang.t("ผู้จัดทำ"),credits))
 b.grab_focus.call_deferred()
 var foot=label(Lang.t("ปลูก • เลี้ยง • เก็บเกี่ยว • เติบโตไปทีละนิด"),15);foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);foot.position=Vector2(-430,-55);foot.size=Vector2(400,30);overlay.add_child(foot)
func pause_screen():
 window(Lang.t("พักสักครู่"),Lang.t("เกมหยุดเวลาเมื่อเปิดเมนู"))
 body.add_child(button(Lang.t("กลับไปฟาร์ม"),close));body.add_child(button(Lang.t("บันทึกเกม"),func():game.save();game.audio.play_sfx("save");toast(Lang.t("บันทึกเกมแล้ว"))))
 body.add_child(button(Lang.t("ตั้งค่า"),settings_screen));body.add_child(button(Lang.t("สมุดชาวสวน"),journal));body.add_child(button(Lang.t("วิธีเล่น"),controls));body.add_child(button(Lang.t("กลับหน้าหลัก"),func():game.save();title_screen()))
func controls():
 window(Lang.t("วิธีเล่น"))
 body.add_child(label(Lang.t("WASD เดิน · Shift วิ่ง · เมาส์มองรอบตัว\nEsc ปล่อยเมาส์ / พักเกม · จอย Xbox: L เดิน R มอง A คุย X ใช้ Y กระเป๋า\nV สลับ FPS / TPS · E โต้ตอบ\nเลข 1–4 หรือลูกกลิ้ง สลับเครื่องมือ · คลิกซ้ายใช้งาน\nI กระเป๋า / เลือกเมล็ด · M แผนที่ · F5 บันทึก\nL เปิด / ปิดตะเกียง · Esc พัก / ตั้งค่า\n\nปลูก: จอบ → เมล็ด → รดน้ำ → นอน → เก็บเกี่ยว\nสัตว์: ให้อาหารทุกวัน → โต → เก็บผลผลิต\nรถ: E ขึ้นรถ → W/S ขับ A/D เลี้ยว → E ลงรถ\nนำผลผลิตไปตลาด ซื้อสัตว์ที่ร้านสัตว์ และอัปเกรดที่ร้านช่าง"),20))
func credits():
 window(Lang.t("ผู้จัดทำ"))
 body.add_child(label("Make Life Slower · Alpine Farm",22))
 var members=GridContainer.new();members.columns=2;members.add_theme_constant_override("h_separation",35);members.add_theme_constant_override("v_separation",16);body.add_child(members)
 members.add_child(label(Lang.t("รหัสนักศึกษา"),20));members.add_child(label(Lang.t("ชื่อ"),20))
 for member in [["673380530-5","รัชชานนท์ คงอม"],["673380304-4","กรวิชญ์ ภู่ชัยภูมิ"],["673380315-9","ทรงพล บุญเที่ยง"],["673380519-3","ชุณหกาญจน์ วิไลสอน"]]:
  members.add_child(label(member[0],20));members.add_child(label(member[1],20))
 body.add_child(label(Lang.t("Make Life Slower · Alpine Farm\nโมเดล ฉาก เพลงและเสียงสังเคราะห์จัดทำสำหรับเดโมนี้\nฟอนต์: Noto Sans Thai · SIL Open Font License\nเอนจิน: Godot 4.7.2 · MIT License"),20))
 body.add_child(label(Engine.get_license_text(),13))
func inventory():
 window(Lang.t("กระเป๋าชาวสวน"),Lang.t("พื้นที่ %d/%d · เมล็ดพันธุ์เลือกจากที่นี่ · ผลผลิตนำไปขายที่ตลาด")%[Farm.bag_count(),Farm.bag_capacity()])
 for k in Farm.CROPS:
  row(Farm.CROPS[k].title+Lang.t(" · %d เมล็ด")%int(Farm.data.seeds.get(k,0)),{"carrot":Lang.t("โตไว · เก็บเกี่ยวได้บ่อย"),"tomato":Lang.t("เติบโตปานกลาง · ผลสดราคาดี"),"pumpkin":Lang.t("โตช้า · ผลใหญ่ มูลค่าสูง")}[k],Lang.t("เลือกปลูก"),func():Farm.data.selected_seed=k;game.tool=2;Farm.commit();inventory())
 for k in Farm.data.bag:row(Farm.good_title(k)+" × "+str(Farm.qty(k)),Lang.t("ราคาฐาน ฿%d ต่อชิ้น")%Farm.price(k),"",func():pass)
func market():
 window(Lang.t("เมล็ดพันธุ์ & ตลาด"),Lang.t("เงิน ฿%d · ผลผลิตเก็บนานราคาจะลดลงเล็กน้อย")%Farm.data.money)
 for k in Farm.CROPS:row(Farm.CROPS[k].title,Lang.t("5 เมล็ด · ")+{"carrot":Lang.t("โตไว"),"tomato":Lang.t("โตปานกลาง"),"pumpkin":Lang.t("โตช้า")}[k]+Lang.t(" · ขายฐาน ฿%d")%Farm.CROPS[k].price,Lang.t("ซื้อ ฿%d")%(Farm.CROPS[k].seed*5),func():Farm.buy_seed(k);game.audio.play_sfx("buy");market())
 body.add_child(button(Lang.t("ขายผลผลิตในกระเป๋าทั้งหมด"),func():Farm.sell_all();game.audio.play_sfx("buy");market()))
 for k in Farm.data.bag:
  if k=="feed":continue
  row(Farm.good_title(k)+" × "+str(Farm.qty(k)),Lang.t("ราคาฐาน ฿%d / ชิ้น")%Farm.price(k),Lang.t("เลือกจำนวน"),func():sale_picker(k))
func livestock():
 window(Lang.t("ร้านสัตว์ & อาหาร"),Lang.t("ซื้อวัยเด็ก โตเมื่อผ่านวันที่ให้อาหาร · สายพันธุ์พิเศษให้ผลผลิตเพิ่มและขายได้ราคาดีขึ้น"))
 row(Lang.t("อาหารสัตว์ 5 ถุง"),Lang.t("ให้อาหาร 1 ถุง / ตัว / วัน"),Lang.t("ซื้อ ฿30"),func():Farm.buy_feed();livestock())
 for k in Farm.SPECIES:
  var s=Farm.SPECIES[k];var product=Farm.good_title(s.yield) if s.yield!="" else Lang.t("ขายสัตว์ / เนื้อ") if s.meat>0 else Lang.t("เพื่อนเดินตาม")
  row(s.title,Lang.t("โต %d วัน · %s")%[s.days,product],Lang.t("ซื้อ ฿%d")%s.cost,func():Farm.add_animal(k,0);livestock())
  if not k in ["cat","dog"]:row(s.title+Lang.t(" ★ สายพันธุ์พิเศษ"),Lang.t("ผลผลิต 2 เท่า / มูลค่าสูงขึ้น"),Lang.t("ซื้อ ฿%d")%(s.cost*2),func():Farm.add_animal(k,1);livestock())
 body.add_child(label(Lang.t("สัตว์ในฟาร์ม"),22))
 for a in Farm.data.animals:
  var id=int(a.id);row(Farm.SPECIES[a.species].title,Lang.t("อายุ %d วัน")%a.age,Lang.t("ดูแล / ขาย"),func():animal(id))
func animal(id):
 var a=Farm.animal_by_id(id)
 if a.is_empty():close();return
 var s=Farm.SPECIES[a.species]
 window(s.title+(" ★" if int(a.breed)>0 else ""),Lang.t("%s · อายุ %d วัน · ความสนิท %d%%")%[Lang.t("โตเต็มวัย") if Farm.mature(a) else Lang.t("วัยเด็ก"),a.age,a.bond])
 row(Lang.t("อาหารวันนี้"),Lang.t("ให้อาหารเพื่อเติบโตและสร้างผลผลิตในวันถัดไป"),Lang.t("ให้อาหาร") if not a.fed else Lang.t("กินแล้ววันนี้"),func():
  Farm.feed_animal(id)
  var actor=game.world.animals.get(id)
  if is_instance_valid(actor):actor.eat_time=2.5
  game.audio.play_sfx(a.species);animal(id))
 if s.yield!="":row(Lang.t("ผลผลิตพร้อมเก็บ · %d")%a.product,Farm.good_title(s.yield),Lang.t("รีดนม") if a.species in ["cow","goat"] else Lang.t("เก็บผลผลิต"),func():
  if a.species in ["cow","goat"]:start_milking(id)
  else:Farm.collect_animal(id);game.audio.play_sfx("harvest");animal(id))
 if not a.species in ["dog","cat"]:
  body.add_child(button(Lang.t("ขายสัตว์ทั้งตัว"),func():confirm(Lang.t("ขาย")+s.title+Lang.t("ตัวนี้?"),Lang.t("สัตว์จะออกจากฟาร์มและรับเงินตามวัยกับสายพันธุ์"),func():Farm.sell_animal(id);close())))
  if Farm.mature(a):body.add_child(button(Lang.t("ส่งแปรรูปเป็นเนื้อ"),func():confirm(Lang.t("ส่งแปรรูปเป็นเนื้อ?"),Lang.t("สัตว์จะออกจากฟาร์มและรับเนื้อ %d ชิ้นเข้ากระเป๋า ไม่มีภาพการเชือด")%s.meat,func():Farm.process_meat(id);close())))
func start_milking(id):
 var a=Farm.animal_by_id(id)
 if a.is_empty() or not a.species in ["cow","goat"]:return
 if not Farm.mature(a) or int(a.product)<=0:
  toast(Lang.t("ยังไม่มีผลผลิต ให้อาหารแล้วรอวันถัดไป"));return
 if Farm.bag_count()>=Farm.bag_capacity():
  toast(Lang.t("กระเป๋าเต็ม ขายของหรืออัปเกรดบ้านก่อน"));return
 window(Lang.t("เวลารีดนม"),Lang.t("กดค้างที่มือจับ แล้วลากลง–ขึ้น 4 รอบ · ไม่ต้องรีบ · ปิดเพื่อยกเลิกได้"))
 var mini=load("res://scripts/milking_game.gd").new();body.add_child(mini);active_milking=mini
 mini.completed.connect(func():finish_milking(id,mini))
 var keys=HBoxContainer.new();body.add_child(keys)
 keys.add_child(button(Lang.t("ลากลง"),func():mini.move_handle(1.0)))
 keys.add_child(button(Lang.t("ยกขึ้น"),func():mini.move_handle(0.0)))
 keys.add_child(label(Lang.t("ใช้เมาส์ สัมผัส หรือปุ่มลูกศรได้"),15))
 mini.grab_focus()
func finish_milking(id,mini):
 if active_milking!=mini or not is_instance_valid(mini) or mini.is_queued_for_deletion() or not mini.finished:return
 active_milking=null
 var a=Farm.animal_by_id(id)
 if a.is_empty() or not a.species in ["cow","goat"]:animal(id);return
 var before=int(a.product);Farm.collect_animal(id)
 var collected=before-int(a.product)
 if collected>0:game.audio.play_sfx("harvest")
 body.add_child(label(Lang.t("เก็บนมแล้ว · %d ชิ้น")%collected,21))
 body.add_child(button(Lang.t("กลับไปดูแลสัตว์"),func():animal(id)))
func upgrades():
 window(Lang.t("ช่างประจำหมู่บ้าน"),Lang.t("ขยายสวนทีละนิด แล้วสร้างบ้านที่อยากกลับมา"))
 var names={"farm":[Lang.t("พื้นที่เพาะปลูก"),Lang.t("ปลดล็อกแปลงเพิ่ม 12 แปลงและเพิ่มผลเก็บเกี่ยว")],"tool":[Lang.t("อุปกรณ์รดน้ำ"),Lang.t("รดแปลงข้างเคียงได้พร้อมกัน")],"home":[Lang.t("บ้านสวน"),Lang.t("ขยายบ้านและพื้นที่เก็บของ")],"barn":[Lang.t("คอกสัตว์"),Lang.t("เพิ่มพื้นที่เลี้ยงอีก 5 ตัว")]}
 for k in names:
  var level=int(Farm.data[k+"_level"]);var cost=(level+1)*{"farm":180,"tool":150,"home":250,"barn":200}[k]
  row(names[k][0]+Lang.t(" · ระดับ %d/2")%level,names[k][1],Lang.t("เต็มแล้ว") if level>=2 else Lang.t("อัปเกรด ฿%d")%cost,func():Farm.upgrade(k);game.audio.play_sfx("buy");upgrades())
func visitor(id):
 var events=game.visitors.events;var offer=events.state().active
 if offer.is_empty() or int(offer.id)!=int(id):toast(Lang.t("คุยกับผู้มาเยือนคนนี้เรียบร้อยแล้ว"));return
 var person=events.PEOPLE[int(offer.person)]
 window(Lang.t(person.name),events.greeting(offer))
 body.add_child(label(Lang.t("สิ่งที่ขอ")+" · "+events.describe_bundle(offer.cost),21))
 if offer.kind=="kindness":body.add_child(label(Lang.t("ช่วยเท่าที่สบายใจได้เลย"),18))
 elif not offer.reward.is_empty():body.add_child(label(Lang.t("สิ่งที่จะได้รับ")+" · "+events.describe_bundle(offer.reward),21))
 var action={"trade":"ตกลงแลกของ","gift":"รับของฝาก","loan":"ให้ยืม ฿50","kindness":"ช่วย ฿40","repayment":"รับเงินคืน"}[offer.kind]
 body.add_child(button(Lang.t(action),func():resolve_visit(id,true,person.name)))
 body.add_child(button(Lang.t("ไว้คราวหน้า"),func():resolve_visit(id,false,person.name)))
func resolve_visit(id,accept,person_name):
 var result=game.visitors.events.resolve(id,accept)
 if not result.ok:toast(result.message);return
 window(Lang.t(person_name));body.add_child(label(result.message,21))
 if result.received!="":body.add_child(label(Lang.t("ได้รับ")+" · "+result.received,21));game.audio.play_sfx("harvest")
 body.add_child(button(Lang.t("ไว้เจอกันใหม่"),close))
func journal():
 window(Lang.t("สมุดชาวสวน"),Lang.t("ไม่มีการแพ้หรือเวลาบังคับ · ค่อย ๆ สร้างฟาร์มตามจังหวะของคุณ"))
 if game.visitors:
  for debt in game.visitors.events.state().pending:
   body.add_child(label(Lang.t("เงินที่เพื่อนบ้านจะนำมาคืน")+" · "+Lang.t(game.visitors.events.PEOPLE[int(debt.person)].name)+" · ฿%d · "%int(debt.amount)+Lang.t("วันที่ %d")%int(debt.due_day),17))
 var qs=[[Lang.t("เก็บผัก 4 แปลง"),"harvest",4,100],[Lang.t("เก็บผลผลิตสัตว์ 4 ชิ้น"),"animal_products",4,120],[Lang.t("ขายของรวม ฿500"),"sold",500,150],[Lang.t("อัปเกรดฟาร์ม 3 ครั้ง"),"upgrades",3,180]]
 for i in range(qs.size()):
  var q=qs[i];var got=str(i) in Farm.data.quests;var progress=int(Farm.data.stats[q[1]])
  row(q[0],Lang.t("%d / %d · รางวัล ฿%d")%[min(progress,q[2]),q[2],q[3]],Lang.t("รับแล้ว") if got else Lang.t("รับรางวัล"),func():
   if progress>=q[2] and not got:Farm.data.quests.append(str(i));Farm.data.money+=q[3];Farm.commit(Lang.t("รับรางวัลแล้ว"));journal()
   else:toast(Lang.t("ทำเป้าหมายให้ครบก่อน")))
 body.add_child(button(Lang.t("เปิดแผนที่"),map_screen))
func map_screen():
 window(Lang.t("แผนที่หุบเขา"),Lang.t("เลือกสถานที่เพื่อแสดงระยะทางบนหน้าจอ"))
 var m=load("res://scripts/minimap.gd").new();m.game=game;m.custom_minimum_size=Vector2(360,300);body.add_child(m)
 for dest in [[Lang.t("บ้านและแปลงปลูก"),Vector3(-7,0,4)],[Lang.t("คอกสัตว์"),Vector3(24,0,5)],[Lang.t("ตลาดและร้านค้า"),Vector3(55,0,-58)],[Lang.t("ทะเลสาบ / จุดชมวิว"),Vector3(-49,0,53)]]:
  body.add_child(button(dest[0],func():game.waypoint=dest[1];close()))
func confirm(title,text,callback):
 window(title,text);body.add_child(button(Lang.t("ยืนยัน"),callback));body.add_child(button(Lang.t("ยกเลิก"),close))
func sleep_transition():
 close();game.modal=true
 var fade=ColorRect.new();fade.color=Color(0,0,0,0);fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(fade)
 var tw=create_tween();tw.tween_property(fade,"color:a",1.0,.25);await tw.finished
 Farm.next_day();game.world.update_daylight(Farm.data.hour,game.player.global_position);game.audio.play_sfx("save")
 var back=create_tween();back.tween_property(fade,"color:a",0.0,.55);await back.finished
 fade.queue_free();game.modal=false;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func settings_screen():
 window(Lang.t("ตั้งค่า"),Lang.t("เสียง · การควบคุม · ภาพ"))
 body.add_child(label(Lang.t("ภาษา")))
 var language=OptionButton.new();language.add_item("ไทย");language.add_item("English");language.selected=1 if Lang.language=="en" else 0;body.add_child(language)
 language.item_selected.connect(func(v):
  Farm.settings.language="en" if v==1 else "th";Lang.set_language(Farm.settings.language);Farm.save_settings();update_hud();settings_screen())
 for pair in [[Lang.t("เสียงทั้งหมด"),"master"],[Lang.t("เพลง"),"music"],[Lang.t("เสียงเอฟเฟกต์ / สัตว์"),"sfx"],[Lang.t("เสียงธรรมชาติ"),"ambient"]]:
  body.add_child(label(pair[0]));var slider=HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=.01;slider.value=Farm.settings[pair[1]];body.add_child(slider);slider.value_changed.connect(func(v):Farm.settings[pair[1]]=v;game.apply_settings())
 body.add_child(label(Lang.t("ความไวเมาส์")));var sens=HSlider.new();sens.min_value=.001;sens.max_value=.006;sens.step=.0001;sens.value=Farm.settings.sensitivity;body.add_child(sens);sens.value_changed.connect(func(v):Farm.settings.sensitivity=v;game.apply_settings())
 var q=OptionButton.new();q.add_item(Lang.t("ภาพเบา · ปิดเงา"));q.add_item(Lang.t("ภาพสวย · เงาและขอบเรียบ"));q.selected=int(Farm.settings.quality);body.add_child(q);q.item_selected.connect(func(v):Farm.settings.quality=v;game.apply_settings())
 var res=OptionButton.new();res.add_item(Lang.t("ความละเอียด 3D อัตโนมัติ (แนะนำสำหรับเว็บ)"));res.add_item(Lang.t("ความละเอียด 3D เบา · ประมาณ 720p"));res.add_item(Lang.t("ความละเอียด 3D เต็มจอ"));res.selected=int(Farm.settings.resolution);body.add_child(res);res.item_selected.connect(func(v):Farm.settings.resolution=v;game.apply_settings())
 var fs=CheckButton.new();fs.text=Lang.t("เต็มจอ");fs.button_pressed=Farm.settings.fullscreen;body.add_child(fs);fs.toggled.connect(func(v):Farm.settings.fullscreen=v;game.apply_settings())
 body.add_child(label(Lang.t("ระยะมองกล้อง (FOV)")));var fov=HSlider.new();fov.min_value=55;fov.max_value=90;fov.step=1;fov.value=Farm.settings.fov;body.add_child(fov);fov.value_changed.connect(func(v):Farm.settings.fov=v;game.apply_settings())
 var inv=CheckButton.new();inv.text=Lang.t("กลับแกนเมาส์แนวตั้ง");inv.button_pressed=Farm.settings.invert_y;body.add_child(inv);inv.toggled.connect(func(v):Farm.settings.invert_y=v;game.apply_settings())
 var limit=OptionButton.new();limit.add_item(Lang.t("จำกัด 30 FPS"));limit.add_item(Lang.t("จำกัด 60 FPS"));limit.selected=0 if int(Farm.settings.fps_limit)==30 else 1;body.add_child(limit);limit.item_selected.connect(func(v):Farm.settings.fps_limit=30 if v==0 else 60;game.apply_settings())
 var fps=CheckButton.new();fps.text=Lang.t("แสดงจำนวน FPS");fps.button_pressed=Farm.settings.show_fps;body.add_child(fps);fps.toggled.connect(func(v):Farm.settings.show_fps=v;game.apply_settings())
 body.add_child(label(Lang.t("ตัวประมวลผลภาพ: ")+game.gpu_info,13))

func sale_picker(k):
 window(Lang.t("ขาย ")+Farm.good_title(k),Lang.t("เลือกจำนวนที่จะขาย · เก็บส่วนที่เหลือไว้ในกระเป๋า"))
 var amount=SpinBox.new();amount.focus_mode=Control.FOCUS_ALL;amount.min_value=1;amount.max_value=Farm.qty(k);amount.step=1;amount.value=1;amount.custom_minimum_size=Vector2(240,55);body.add_child(amount)
 var total=label(Lang.t("รับเงิน ฿%d")%Farm.sale_value(k,1),28);body.add_child(total)
 amount.value_changed.connect(func(v):total.text=Lang.t("รับเงิน ฿%d")%Farm.sale_value(k,int(v)))
 body.add_child(button(Lang.t("ขายจำนวนที่เลือก"),func():Farm.sell_good(k,int(amount.value));game.audio.play_sfx("buy");market()))
 body.add_child(button(Lang.t("กลับตลาด"),market))



