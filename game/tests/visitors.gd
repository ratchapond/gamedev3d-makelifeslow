extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func verify(value,message):
 checks+=1
 if not value:failures+=1;push_error("VISITORS: "+message)
func fresh(farm):farm.new_game();farm.data.hour=9
func run():
 var farm=root.get_node("Farm");farm.save_enabled=false
 var events=load("res://scripts/visitor_events.gd").new(farm)
 fresh(farm);var money=farm.data.money;var s=events.state()
 verify(farm.data.money==money and s.active.is_empty(),"Legacy saves gain visitor state without losing money or items")
 verify(events.maybe_offer().is_empty(),"First arrival has a delay")
 farm.data.hour=10;var offer=events.maybe_offer()
 verify(offer.kind=="gift","The first neighbour brings a gentle welcome gift")
 var stored=JSON.stringify(offer)
 verify(JSON.stringify(events.create_offer("loan"))==stored,"An unresolved offer never rerolls")
 var id=int(offer.id);var result=events.resolve(id,true)
 verify(result.ok and events.state().active.is_empty(),"Accepting settles an offer")
 var bag=JSON.stringify(farm.data.bag);var seeds=JSON.stringify(farm.data.seeds)
 verify(not events.resolve(id,true).ok and JSON.stringify(farm.data.bag)==bag and JSON.stringify(farm.data.seeds)==seeds,"Repeated acceptance cannot duplicate a gift")
 verify(events.maybe_offer().is_empty(),"Visitors do not immediately respawn")
 farm.data.hour=17;events.maybe_offer();events.resolve(events.state().active.id,false)
 farm.data.hour=18
 verify(events.maybe_offer().is_empty() and int(events.state().count)==2,"At most two new visits are scheduled per day")
 fresh(farm);farm.data.hour=21;events.state().next_at=0
 verify(events.maybe_offer().is_empty(),"New visitors do not arrive at night")
 fresh(farm);farm.data.bag={};farm.add_good("carrot",2);offer=events.create_offer("trade");id=int(offer.id)
 farm.take("carrot",1);bag=JSON.stringify(farm.data.bag);money=farm.data.money
 verify(not events.resolve(id,true).ok and JSON.stringify(farm.data.bag)==bag and farm.data.money==money,"Insufficient trade goods never partially charge the player")
 farm.add_good("carrot",1);farm.add_good("feed",78)
 verify(not events.resolve(id,true).ok and farm.qty("carrot")==2,"A trade that would overflow the bag leaves the offered items untouched")
 farm.take("feed",2)
 verify(events.resolve(id,true).ok and farm.qty("carrot")==0 and farm.qty("feed")==80,"Outgoing trade items free space before incoming items are counted")
 fresh(farm);offer=events.create_offer("loan");id=int(offer.id);var person=int(offer.person)
 farm.data.money=49
 verify(not events.resolve(id,true).ok and farm.data.money==49 and events.state().pending.is_empty(),"Cannot lend money the player does not have")
 farm.data.money=50
 verify(events.resolve(id,true).ok and farm.data.money==0 and events.state().pending.size()==1,"A loan charges exactly once and records a receivable")
 verify(not events.resolve(id,true).ok and events.state().pending.size()==1,"Duplicate loan callbacks cannot create another debt")
 var serialized=JSON.stringify(farm.data);farm.data=JSON.parse_string(serialized);s=events.state()
 verify(s.pending.size()==1 and int(s.pending[0].amount)==50,"Loan principal persists through JSON save/reload")
 farm.data.day=2;farm.data.hour=10;s.next_at=0;offer=events.create_offer("gift")
 verify(offer.kind=="gift","Loans are not repaid before their promised day")
 events.resolve(offer.id,false);farm.data.day=3;farm.data.hour=10;s.next_at=0
 offer=events.maybe_offer();id=int(offer.id)
 verify(offer.kind=="repayment" and int(offer.person)==person,"The same neighbour returns to repay when due")
 events.resolve(id,false)
 verify(s.pending.size()==1 and farm.data.money==0,"Postponing a repayment preserves the receivable")
 offer=events.create_offer();id=int(offer.id);events.resolve(id,true)
 verify(farm.data.money==50 and s.pending.is_empty(),"Accepting a repayment restores the principal and settles the debt")
 events.resolve(id,true)
 verify(farm.data.money==50,"A repayment cannot be collected twice")
 fresh(farm);offer=events.create_offer("kindness");id=int(offer.id);money=farm.data.money
 var reward=events.describe_bundle(offer.reward);farm.data=JSON.parse_string(JSON.stringify(farm.data))
 verify(events.describe_bundle(events.state().active.reward)==reward,"Surprise gifts are fixed before acceptance and survive reload")
 result=events.resolve(id,true)
 verify(result.ok and farm.data.money==money-40 and result.received!="","Helping a stranger grants the promised surprise after one payment")
 events.resolve(id,true)
 verify(farm.data.money==money-40,"Kindness events cannot charge twice")
 fresh(farm);offer=events.create_offer("loan");money=farm.data.money;bag=JSON.stringify(farm.data.bag)
 events.resolve(offer.id,false)
 verify(farm.data.money==money and JSON.stringify(farm.data.bag)==bag and events.state().pending.is_empty(),"Declining a request has no economic penalty")
 # Full game: navigation, movement, physical E, UI, language and old-save restore.
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.start_game(false);g.modal=true
 await physics_frame
 var path=g.visitors.road_path(Vector3(0,0,12),Vector3(62,0,-58));var length=0.0
 for i in range(path.size()-1):length+=path[i].distance_to(path[i+1])
 verify(path.size()>3 and length<115,"Road graph connects the village junction without a large detour")
 var on_roads=true
 for p in path:
  if g.world.road_clearance(p)>.001:on_roads=false
 verify(on_roads,"The visitor navigation route follows existing roads")
 verify(not g.visitors.safe_verge(Vector3(-49,0,53),Vector3(-58,0,57)),"Visitors do not approach through the lake")
 verify(not g.visitors.safe_verge(Vector3(8,0,-12),Vector3(0,0,-15)),"Visitors do not cut through crop plots")
 g.player.position=Vector3(0,.1,12);g.player.yaw=0
 offer=g.visitors.events.create_offer("gift");g.visitors.spawn(offer);var actor=g.visitors.actor
 verify(is_instance_valid(actor) and g.world.targets.has(actor),"A single visible visitor is registered for interaction")
 verify(actor.collision_layer==0,"Visitors do not block the player's walking route")
 var before=actor.position;g.modal=false
 for i in range(100):await physics_frame
 verify(actor.position.distance_to(before)>1,"Visitor Walk animation travels along its road path")
 verify(actor.ap and "Walk" in actor.ap.current_animation,"Travelling visitors play the walking clip")
 g.modal=true;actor._physics_process(.1)
 verify("Idle" in actor.ap.current_animation,"Visitors stop their walking animation during a conversation")
 g.modal=true;actor.position=Vector3(4,0,12);actor.waiting=true;actor.waypoint=actor.route.size();g.player.position=Vector3(4,.1,14)
 g.target=null;g.modal=false
 await process_frame
 g.update_target()
 var key=InputEventKey.new();key.physical_keycode=KEY_E;key.keycode=0x0e33;key.pressed=true;Input.parse_input_event(key);await process_frame
 verify(g.modal and g.target==actor,"Physical E opens the visitor in front of the player")
 var person_name=g.visitors.events.PEOPLE[int(offer.person)].name
 verify(is_instance_valid(g.ui.title_label) and g.ui.title_label.text==person_name,"Visitor UI identifies the person")
 g.ui.resolve_visit(int(offer.id),true,person_name)
 verify(g.visitors.events.state().active.is_empty(),"Visitor dialog commits the saved offer once")
 g.ui.close();g.visitors._process(.6)
 verify(actor.departing,"A settled visitor walks away")
 g.modal=true;g.visitors.reset();verify(not is_instance_valid(g.visitors.actor),"Starting or loading a game cleans up the previous visitor")
 root.get_node("Lang").set_language("en")
 offer=g.visitors.events.create_offer("loan");g.ui.visitor(offer.id)
 var english=true
 for c in g.ui.overlay.find_children("*","Control",true,false):
  if c is Label or c is BaseButton:
   for i in str(c.text).length():
    var code=str(c.text).unicode_at(i)
    if code>=0x0e01 and code<=0x0e5b and code!=0x0e3f:english=false
 verify(english,"Visitor dialog and payment controls are translated")
 var old_path=farm.save_path;farm.save_path="user://visitor_regression.json";farm.save_game();farm.new_game();farm.load_game()
 verify(int(g.visitors.events.state().active.id)==int(offer.id),"Active visits survive the actual game save/load path")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(farm.save_path));farm.save_path=old_path
 print("VISITOR_TESTS ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
