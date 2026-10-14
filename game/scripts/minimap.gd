extends Control
var game
func _process(_dt):queue_redraw()
func _draw():
 if not game or not game.player:return
 var rect=Rect2(Vector2.ZERO,size);draw_style_box(style(),rect)
 var factor=size.x/290.0;var c=size*.5
 draw_line(c+Vector2(-62,-130)*factor,c+Vector2(-62,130)*factor,Color("7bafbb"),5)
 for p in [[Vector2(-7,4),Color("e2bb80")],[Vector2(24,10),Color("d5c09a")],[Vector2(62,-62),Color("d78969")],[Vector2(-58,57),Color("7bafbb")]]:draw_circle(c+p[0]*factor,5,p[1])
 for a in Farm.data.animals:draw_circle(c+Vector2(a.x,a.z)*factor,1.8,Color("efe8cb"))
 if game.visitors and is_instance_valid(game.visitors.actor):
  var visitor=game.visitors.actor
  if not visitor.departing:draw_circle(c+Vector2(visitor.position.x,visitor.position.z)*factor,4,Color("82d8d1"))
 var pos=c+Vector2(game.player.position.x,game.player.position.z)*factor;draw_circle(pos,4,Color("fff3c9"));draw_line(pos,pos+Vector2(-sin(game.player.yaw),-cos(game.player.yaw))*11,Color("fff3c9"),2)
 if game.waypoint!=Vector3.ZERO:draw_circle(c+Vector2(game.waypoint.x,game.waypoint.z)*factor,5,Color("f6db74"),false,2)
func style():
 var s=StyleBoxFlat.new();s.bg_color=Color("263a30cc");s.corner_radius_top_left=14;s.corner_radius_top_right=14;s.corner_radius_bottom_left=14;s.corner_radius_bottom_right=14;return s
