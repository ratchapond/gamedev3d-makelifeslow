extends Control
signal completed
const ROUNDS=4
var rounds=0
var handle=0.0
var returning=false
var dragging=false
var touch_id=-1
var finished=false

func _ready():
 custom_minimum_size=Vector2(0,265)
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 focus_mode=Control.FOCUS_ALL
 focus_exited.connect(func():dragging=false;touch_id=-1)
func rail():return Rect2(size.x*.76,48,0,150)
func knob():return Vector2(rail().position.x,rail().position.y+handle*rail().size.y)
func move_handle(value):
 if finished:return
 handle=clamp(value,0.0,1.0)
 if not returning and handle>=.9:returning=true
 elif returning and handle<=.1:
  returning=false;rounds+=1
  if rounds>=ROUNDS:
   finished=true;dragging=false;touch_id=-1;completed.emit()
 queue_redraw()
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  dragging=false;touch_id=-1
func _gui_input(event):
 if finished:return
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:
   dragging=event.position.distance_to(knob())<36
   if dragging:grab_focus();accept_event()
  else:dragging=false
 elif event is InputEventMouseMotion and dragging:
  move_handle((event.position.y-rail().position.y)/rail().size.y);accept_event()
 elif event is InputEventScreenTouch:
  if event.pressed and touch_id<0 and event.position.distance_to(knob())<40:
   touch_id=event.index;grab_focus();accept_event()
  elif not event.pressed and event.index==touch_id:touch_id=-1
 elif event is InputEventScreenDrag and event.index==touch_id:
  move_handle((event.position.y-rail().position.y)/rail().size.y);accept_event()
 elif event is InputEventKey and event.pressed and not event.echo:
  if event.keycode in [KEY_DOWN,KEY_UP]:move_handle(1.0 if event.keycode==KEY_DOWN else 0.0);accept_event()
func oval(center,radius,color):
 var points=PackedVector2Array()
 for i in range(40):
  var a=TAU*i/40.0;points.append(center+Vector2(cos(a)*radius.x,sin(a)*radius.y))
 draw_colored_polygon(points,color)
func text_at(point,text,font_size,color=Color("f5eedc")):
 draw_string(get_theme_default_font(),point,Lang.t(text),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _draw():
 var bg=StyleBoxFlat.new();bg.bg_color=Color("223e35");bg.set_corner_radius_all(18)
 draw_style_box(bg,Rect2(Vector2.ZERO,size))
 var c=Vector2(size.x*.30,102)
 # A little illustrated cow and a pail that fills with each full gesture.
 for x in [-43,33]:draw_line(c+Vector2(x,24),c+Vector2(x,77),Color("e6dfcc"),13,true)
 oval(c,Vector2(83,44),Color("f2ead8"))
 oval(c+Vector2(-32,-9),Vector2(26,25),Color("547263"))
 oval(c+Vector2(40,3),Vector2(21,30),Color("547263"))
 oval(c+Vector2(-77,-30),Vector2(24,34),Color("f2ead8"))
 oval(c+Vector2(-103,-42),Vector2(16,8),Color("d9c3af"))
 oval(c+Vector2(-75,-4),Vector2(27,14),Color("dca8a0"))
 draw_circle(c+Vector2(-88,-35),3,Color("253e32"))
 draw_line(c+Vector2(80,-5),c+Vector2(95,35),Color("c8bc9e"),5,true)
 oval(c+Vector2(0,39),Vector2(23,13),Color("dca8a0"))
 for x in [-9,9]:draw_line(c+Vector2(x,43),c+Vector2(x,57+handle*8),Color("e3b8ad"),6,true)
 var pail=Rect2(c+Vector2(-29,85),Vector2(58,46))
 draw_style_box(bg,pail.grow(3));draw_rect(pail,Color("8ca99c"))
 var fill=float(rounds)/ROUNDS
 if returning and not finished:fill=min(1.0,fill+.1)
 if fill>0:draw_rect(Rect2(pail.position+Vector2(4,42*(1-fill)),Vector2(50,42*fill)),Color("fff7de"))
 draw_arc(pail.position+Vector2(29,8),25,PI,TAU,24,Color("c4d5c5"),3,true)
 if returning and not finished:draw_line(c+Vector2(0,59),pail.position+Vector2(29,9),Color("fff7de"),3,true)
 var r=rail();draw_line(r.position,r.position+Vector2(0,r.size.y),Color("547465"),12,true)
 for y in [r.position.y,r.end.y]:draw_circle(Vector2(r.position.x,y),8,Color("c1bd8c"))
 draw_circle(knob(),25,Color("ead499"));draw_circle(knob(),17,Color("f9ebc8"))
 var direction=-1.0 if returning else 1.0;var tip=knob()+Vector2(0,direction*9);var ink=Color("314d40")
 draw_line(knob()-Vector2(0,direction*9),tip,ink,3,true)
 draw_polyline(PackedVector2Array([tip+Vector2(-6,-direction*6),tip,tip+Vector2(6,-direction*6)]),ink,3,true)
 text_at(Vector2(20,30),"ค่อย ๆ เติมนมให้เต็มถัง",18)
 text_at(Vector2(size.x*.60,234),Lang.t("รอบ %d / 4")%rounds,19)
 var bar=Rect2(20,size.y-18,size.x-40,6)
 draw_rect(bar,Color("547465"));bar.size.x*=float(rounds)/ROUNDS;draw_rect(bar,Color("ead499"))
