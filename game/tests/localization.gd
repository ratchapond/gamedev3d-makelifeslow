extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func verify(value,message):
 checks+=1
 if not value:failures+=1;push_error(message)
func thai(text):
 for i in str(text).length():
  var code=str(text).unicode_at(i)
  if code>=0x0e01 and code<=0x0e5b and code!=0x0e3f:return true
 return false
func run():
 var farm=root.get_node("Farm");farm.save_enabled=false
 var lang=root.get_node("Lang");lang.set_language("th")
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 await process_frame
 var font=load("res://assets/fonts/NotoSansThai.ttf")
 var names="รัชชานนท์ คงอมกรวิชญ์ ภู่ชัยภูมิทรงพล บุญเที่ยงชุณหกาญจน์ วิไลสอน"
 for i in names.length():
  var code=names.unicode_at(i)
  verify(font.has_char(code),"Font covers creator names")
 g.ui.credits();verify(g.ui.title_label.text=="ผู้จัดทำ","Thai creator heading")
 var text=""
 for l in g.ui.body.find_children("*","Label",true,false):text+=l.text
 for id in ["673380530-5","673380304-4","673380315-9","673380519-3"]:verify(text.contains(id),"Creator ID present")
 lang.set_language("en")
 verify(farm.season()=="Spring","Season localized")
 verify(farm.good_title("milk_premium")=="Cow milk ★","Premium goods localized")
 var money=farm.data.money
 g.start_game(false);g.modal=true;g.ui.update_hud()
 verify(not thai(g.ui.stats.text),"HUD fully English")
 verify(not thai(g.ui.tool_line.get_child(0).text),"Tools English")
 for sign in g.world.find_children("*","Label3D",true,false):verify(not thai(sign.text),"World sign English")
 for menu in ["controls","inventory","market","livestock","upgrades","journal","map_screen","settings_screen","pause_screen"]:
  g.ui.call(menu)
  for c in g.ui.overlay.find_children("*","Control",true,false):
   if c is Label or c is BaseButton:verify(not thai(c.text),"English menu "+menu+": "+c.text)
 g.ui.animal(1)
 for c in g.ui.body.find_children("*","Control",true,false):
  if c is Label or c is BaseButton:verify(not thai(c.text),"Animal care English")
 g.ui.credits();verify(g.ui.title_label.text=="Creators","English creator heading")
 verify(farm.data.money==money,"Language keeps gameplay state")
 lang.set_language("th");g.ui.update_hud();verify(g.ui.stats.text.begins_with("วันที่"),"Switch back to Thai")
 for sign in g.world.find_children("*","Label3D",true,false):verify(thai(sign.text),"World sign returns to Thai")
 print("LOCALIZATION_TESTS ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
