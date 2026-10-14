extends SceneTree
var f
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(value,description):
 checks+=1
 if not value:failures+=1;push_error("FAILED: "+description)
func run():
 f=root.get_node("Farm");f.save_enabled=false;f.save_path="user://automated_test_save.json";f.new_game()
 check(f.data.money==550 and f.data.animals.size()==2,"starter resources")
 f.use_plot(0,2);check(f.data.plots[0].crop=="","cannot sow before tilling")
 f.use_plot(0,0);f.use_plot(0,2);check(f.data.seeds.carrot==7,"seed consumed once")
 f.use_plot(0,2);check(f.data.seeds.carrot==7,"occupied plot prevents duplicate seed spend")
 f.next_day();check(f.data.plots[0].growth==0,"dry crop stalls")
 for i in range(2):f.use_plot(0,1);f.next_day()
 f.use_plot(0,3);check(f.qty("carrot")==2 and f.data.plots[0].crop=="","watered crop grows and harvests")
 var money=f.data.money;f.sell_good("carrot");check(f.data.money==money+56,"fresh produce sale")
 f.use_plot(20,0);check(not f.data.plots[20].tilled,"locked land")
 var cow=f.data.animals[1];var id=int(cow.id)
 for i in range(3):
  f.feed_animal(id);f.next_day()
 check(f.mature(cow) and cow.product==2,"fed calf matures and produces milk")
 f.collect_animal(id);check(f.qty("milk")==2 and cow.product==0,"collect product exactly once")
 f.collect_animal(id);check(f.qty("milk")==2,"no repeated product duplication")
 f.data.money=5000;f.add_animal("cow",1);var premium=f.data.animals[-1];premium.age=3;premium.fed=true;f.next_day();f.collect_animal(premium.id)
 check(f.qty("milk_premium")==4 and f.price("milk_premium")>f.price("milk"),"premium breed yield and price")
 var before=f.data.animals.size();f.process_meat(premium.id);check(f.data.animals.size()==before-1 and f.qty("meat_premium")==10,"meat processing removes animal and adds product")
 f.add_animal("pig",0);var pig=f.data.animals[-1];pig.age=3;money=f.data.money;f.sell_animal(pig.id);check(f.data.money==money+210,"live animal sale")
 f.add_animal("dog",0);var dog=f.data.animals[-1];before=f.data.animals.size();f.process_meat(dog.id);f.sell_animal(dog.id);check(f.data.animals.size()==before,"pets protected")
 f.upgrade("farm");check(f.max_plots()==24,"farm upgrade unlocks plots")
 f.upgrade("tool");f.use_plot(1,0);f.use_plot(0,1);check(f.data.plots[1].water,"watering can area upgrade")
 f.upgrade("barn");check(f.capacity()==11,"barn capacity upgrade")
 f.data.money=0;var level=f.data.home_level;f.upgrade("home");check(f.data.home_level==level,"no negative balance on upgrades")
 f.data.bag={};f.add_good("feed",79);cow.product=5;f.collect_animal(id);check(f.qty("milk")==1 and cow.product==4,"partial collection preserves product when bag nearly full")
 var before_qty=f.bag_count();f.add_good("meat",10);check(f.bag_count()==before_qty,"full bag prevents overflow")
 f.data.plots[6].tilled=true;f.data.plots[6].water=false;f.use_plot(5,0);f.use_plot(5,1);check(not f.data.plots[6].water,"watering does not wrap across rows")
 f.data.day=22;f.data.plots[2]={"tilled":true,"crop":"carrot","growth":0,"water":true};f.next_day();check(f.data.plots[2].growth==1,"winter watered even day grows")
 f.data.plots[2].water=true;f.next_day();check(f.data.plots[2].growth==1,"winter odd day slows growth")
 f.data.money=1234;f.save_game();f.new_game();check(f.load_game() and f.data.money==1234,"save and reload full farm")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(f.save_path))
 if failures==0:print("SYSTEM_TESTS_PASSED ",checks)
 else:print("SYSTEM_TESTS_FAILED ",failures)
 quit(0 if failures==0 else 1)
