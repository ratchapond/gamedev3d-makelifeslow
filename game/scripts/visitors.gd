extends Node
var game
var events
var actor
var timer=0.0
var plan_timer=0.0
var last_goal=Vector3.INF
func _ready():events=load("res://scripts/visitor_events.gd").new(Farm)
func clear_actor():
 if is_instance_valid(actor):
  game.world.targets.erase(actor)
  if game.target==actor:game.target=null
  if game.npc_near==actor:game.npc_near=null
  actor.queue_free()
 actor=null
func reset():clear_actor();timer=0.0;plan_timer=0.0;last_goal=Vector3.INF;events.state()
func segments():
 var lines=[]
 for i in [0,1]:
  var points=game.world.ROAD_ROUTES[i].points
  for j in range(points.size()-1):lines.append([points[j],points[j+1]])
 lines.append([Vector3(0,0,12),Vector3(-3,0,12)])
 lines.append([Vector3(40,0,-58),Vector3(55,0,-58)])
 lines.append([Vector3(55,0,-58),Vector3(82,0,-58)])
 return lines
func road_projection(p):
 var best={"point":Vector3.ZERO,"segment":[]};var distance=INF
 for line in segments():
  var q=Geometry2D.get_closest_point_to_segment(Vector2(p.x,p.z),Vector2(line[0].x,line[0].z),Vector2(line[1].x,line[1].z))
  var d=q.distance_to(Vector2(p.x,p.z))
  if d<distance:distance=d;best={"point":Vector3(q.x,0,q.y),"segment":line}
 return best
func road_path(from,to):
 var graph=AStar3D.new();var ids={};var lines=segments()
 for line in lines:
  for point in line:
   if not ids.has(point):ids[point]=ids.size();graph.add_point(ids[point],point)
  graph.connect_points(ids[line[0]],ids[line[1]])
 var start=road_projection(from);var finish=road_projection(to)
 for node in [[100,start],[101,finish]]:
  graph.add_point(node[0],node[1].point)
  for endpoint in node[1].segment:graph.connect_points(node[0],ids[endpoint])
 if start.segment==finish.segment:graph.connect_points(100,101)
 var result=graph.get_point_path(100,101)
 # Joining from a previous roadside conversation is safe along its approach.
 result.insert(0,Vector3(from.x,0,from.z))
 for i in result.size():result[i].y=game.world.ground(result[i])
 return result
func approach_path(from):
 var player=game.player.global_position;var result=road_path(from,player)
 var end=result[-1];var delta=player-end;delta.y=0
 if delta.length()>2.4 and delta.length()<14 and not game.player.driving:
  var goal=player-delta.normalized()*2.4;goal.y=game.world.ground(goal)
  var query=PhysicsRayQueryParameters3D.create(end+Vector3.UP*.95,goal+Vector3.UP*.95)
  query.exclude=[actor.get_rid(),game.player.get_rid(),game.world.truck.get_rid()]
  if safe_verge(end,goal) and game.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty():result.append(goal)
 return result
func safe_verge(from,to):
 for i in range(11):
  var p=from.lerp(to,float(i)/10)
  if p.x>-14 and p.x<5 and p.z>-26 and p.z<-7:return false
  if Vector2((p.x+58)/17.5,(p.z-57)/12).length()<1.08:return false
  if abs(p.x-(-62+sin(p.z*.04)*8))<2.7 and not (p.z>32 and p.z<36):return false
 return true
func spawn(offer):
 var player=game.player.global_position;var spawn_at=Vector3(55,0,-58);var best=INF
 for line in segments():
  for p in line:
   var distance=Vector2(p.x-player.x,p.z-player.z).length()
   if distance>=16 and distance<best:best=distance;spawn_at=p
 spawn_at.y=game.world.ground(spawn_at)
 actor=load("res://scripts/visitor_actor.gd").new();actor.game=game;actor.record_id=int(offer.id);actor.person=int(offer.person);actor.position=spawn_at
 game.world.add_child(actor);game.world.targets.append(actor);actor.follow(approach_path(spawn_at));last_goal=player
 if not offer.announced:
  offer.announced=true;Farm.commit()
  game.ui.toast(Lang.t("มีผู้มาเยือนกำลังเดินมาหา · ดูจุดสีฟ้าบนแผนที่"),5)
func nearby():return is_instance_valid(actor) and not actor.departing and actor.global_position.distance_to(game.player.global_position)<4.5
func _process(dt):
 if not game.playing or game.modal:return
 timer+=dt;plan_timer+=dt
 if timer<.5:return
 timer=0
 var active=events.state().active
 if is_instance_valid(actor):
  if active.is_empty() and not actor.departing:
   actor.departing=true;actor.follow(road_path(actor.global_position,Vector3(62,0,-58)))
  if actor.departing:
   if actor.waiting or actor.global_position.distance_to(game.player.global_position)>45:clear_actor()
  elif actor.waiting and plan_timer>2 and game.player.global_position.distance_to(last_goal)>5:
   actor.follow(approach_path(actor.global_position));last_goal=game.player.global_position;plan_timer=0
 else:
  if active.is_empty():active=events.maybe_offer()
  if not active.is_empty():spawn(active)
