extends CharacterBody3D
var game
var record_id=0
var person=0
var route=PackedVector3Array()
var waypoint=0
var departing=false
var waiting=false
var model
var ap
var last_position=Vector3.ZERO
var stuck=0.0
func _ready():
 set_meta("kind","visitor");set_meta("id",record_id);set_meta("dynamic",true)
 set_meta("title",Lang.t("คุยกับผู้มาเยือน")+" · "+Lang.t(game.visitors.events.PEOPLE[person].name))
 collision_layer=0;collision_mask=1;floor_snap_length=.6
 var shape=CollisionShape3D.new();shape.position.y=.85;var capsule=CapsuleShape3D.new();capsule.height=1.7;capsule.radius=.28;shape.shape=capsule;add_child(shape)
 model=load("res://assets/models/"+game.visitors.events.PEOPLE[person].asset+".glb").instantiate();add_child(model)
 ap=model.find_child("AnimationPlayer",true,false)
 var life=load("res://scripts/character_life.gd").new();model.add_child(life);life.setup(model,game,true,8000+record_id)
 for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.visibility_range_end=80
 game.world.soft_box(model,Vector3(.33,.92,-.03),Vector3(.27,.35,.18),"a47d53",.05)
 game.world.label3(self,Lang.t(game.visitors.events.PEOPLE[person].name),Vector3(0,2.1,0),23)
 play("Idle")
func play(clip):
 if not ap:return
 for key in ap.get_animation_list():
  if clip in key:
   if ap.current_animation!=key:ap.get_animation(key).loop_mode=Animation.LOOP_LINEAR;ap.play(key,.18)
   return
func follow(points):route=points;waypoint=0;waiting=false;stuck=0.0
func _physics_process(dt):
 if not game.playing or game.modal:velocity=Vector3.ZERO;play("Idle");return
 var to_player=game.player.global_position-global_position;to_player.y=0
 if not departing and to_player.length()<2.6:waypoint=route.size()
 if waypoint<route.size():
  var delta=route[waypoint]-global_position;delta.y=0
  if delta.length()<.45:waypoint+=1
  else:
   var direction=delta.normalized();rotation.y=lerp_angle(rotation.y,atan2(direction.x,direction.z),min(1.0,dt*5))
   velocity.x=direction.x*1.9;velocity.z=direction.z*1.9;velocity.y-=9.8*dt;move_and_slide();play("Walk")
   if global_position.distance_to(last_position)<dt*.15:stuck+=dt
   else:stuck=0.0
   last_position=global_position
   if stuck>3:waiting=true;waypoint=route.size();play("Idle")
   return
 waiting=true;velocity=Vector3.ZERO;play("Idle")
 if not departing:
  var delta=game.player.global_position-global_position
  rotation.y=lerp_angle(rotation.y,atan2(delta.x,delta.z),min(1.0,dt*3))
