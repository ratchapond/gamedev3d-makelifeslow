extends Node
signal changed
signal notice(text)
const CROPS = {
 "carrot":{"title":"แครอต","days":2,"seed":12,"price":28,"color":Color("eaa052")},
 "tomato":{"title":"มะเขือเทศ","days":3,"seed":22,"price":52,"color":Color("d7654a")},
 "pumpkin":{"title":"ฟักทอง","days":4,"seed":35,"price":85,"color":Color("e8b354")}
}
const SPECIES = {
 "chicken":{"title":"ไก่","cost":85,"days":2,"yield":"egg","qty":1,"sale":65,"meat":2},
 "duck":{"title":"เป็ด","cost":110,"days":2,"yield":"duck_egg","qty":1,"sale":90,"meat":3},
 "cow":{"title":"วัว","cost":300,"days":3,"yield":"milk","qty":2,"sale":260,"meat":10},
 "goat":{"title":"แพะ","cost":190,"days":3,"yield":"goat_milk","qty":2,"sale":155,"meat":5},
 "sheep":{"title":"แกะ","cost":220,"days":3,"yield":"wool","qty":2,"sale":185,"meat":5},
 "pig":{"title":"หมู","cost":160,"days":3,"yield":"","qty":0,"sale":210,"meat":8},
 "dog":{"title":"สุนัข","cost":140,"days":3,"yield":"","qty":0,"sale":0,"meat":0},
 "cat":{"title":"แมว","cost":120,"days":3,"yield":"","qty":0,"sale":0,"meat":0}
}
const GOODS = {"egg":["ไข่ไก่",20],"duck_egg":["ไข่เป็ด",26],"milk":["นมวัว",38],"goat_milk":["นมแพะ",44],"wool":["ขนแกะ",45],"meat":["เนื้อสัตว์",35],"feed":["อาหารสัตว์",6]}
const SAVE = "user://alpine_farm_v1.json"
var save_path=SAVE
var save_enabled=true
var data = {}
var settings = {"master":0.8,"music":0.45,"sfx":0.65,"ambient":0.5,"sensitivity":0.0025,"quality":1,"fullscreen":false,"fov":70.0,"invert_y":false,"fps_limit":60,"show_fps":false,"resolution":0,"language":"th"}

func _ready():
 new_game()
 load_settings()
 Lang.set_language(settings.language)

func new_game():
 data={"day":1,"hour":8.0,"money":550,"selected_seed":"carrot","farm_level":0,"tool_level":0,"home_level":0,"barn_level":0,"bag":{},"seeds":{"carrot":8,"tomato":3,"pumpkin":2},"plots":[],"animals":[],"next_id":1,"player":[2.0,0.0,10.0],"truck":[5.0,0.0,14.0,0.0],"quests":[],"stats":{"harvest":0,"animal_products":0,"sold":0,"upgrades":0}}
 for i in range(36):data.plots.append({"tilled":false,"crop":"","growth":0,"water":false})
 add_good("feed",8)
 add_animal("chicken",0,false)
 add_animal("cow",0,false)

func max_plots():return 12+int(data.farm_level)*12
func capacity():return 6+int(data.barn_level)*5
func pet_count():
 var n=0
 for a in data.animals:
  if a.species in ["cat","dog"]:n+=1
 return n
func barn_count():return data.animals.size()-pet_count()
func season():return [Lang.t("ใบไม้ผลิ"),Lang.t("ฤดูร้อน"),Lang.t("ใบไม้ร่วง"),Lang.t("ฤดูหนาว")][int((int(data.day)-1)/7)%4]
func good_title(k):
 var premium=k.ends_with("_premium")
 var base=k.trim_suffix("_premium")
 var title=CROPS[base].title if CROPS.has(base) else GOODS.get(base,[base,0])[0]
 return Lang.t(title)+(" ★" if premium else "")
func price(k):
 var base=k.trim_suffix("_premium")
 var v=CROPS[base].price if CROPS.has(base) else GOODS.get(base,[base,0])[1]
 return int(v*(1.65 if k.ends_with("_premium") else 1.0))
func qty(k):return int(data.bag.get(k,{"qty":0}).qty)
func bag_count():
 var n=0
 for k in data.bag:n+=qty(k)
 return n
func bag_capacity():return 80+int(data.home_level)*60
func room_for(n):
 if bag_count()+n>bag_capacity():notice.emit(Lang.t("กระเป๋าเต็ม ขายผลผลิตหรืออัปเกรดบ้าน"));return false
 return true
func add_good(k,n):
 if not room_for(n):return false
 if not data.bag.has(k):data.bag[k]={"qty":0,"day":data.day}
 var previous=int(data.bag[k].qty)
 data.bag[k].day=(previous*float(data.bag[k].day)+n*int(data.day))/float(previous+n)
 data.bag[k].qty+=n
 return true
func take(k,n):
 if qty(k)<n:return false
 data.bag[k].qty-=n
 if data.bag[k].qty<=0:data.bag.erase(k)
 return true
func spend(n):
 if data.money<n:
  notice.emit(Lang.t("เงินไม่พอ ต้องการ ฿%d")%n)
  return false
 data.money-=n
 return true
func commit(text=""):
 changed.emit()
 if text!="":notice.emit(text)
 if save_enabled:save_game()

func use_plot(i,tool):
 if i>=max_plots():notice.emit(Lang.t("แปลงนี้ยังล็อกอยู่ อัปเกรดฟาร์มที่ร้านช่าง"));return
 var p=data.plots[i]
 match tool:
  0:
   if p.crop!="":notice.emit(Lang.t("มีพืชอยู่แล้ว ใช้ตะกร้าเก็บเมื่อโตเต็มที่"));return
   p.tilled=true
   commit(Lang.t("เตรียมดินแล้ว"))
  1:
   if not p.tilled:notice.emit(Lang.t("ใช้จอบเตรียมดินก่อน"));return
   p.water=true
   if data.tool_level>0:
    var nearby=[i-1,i+1]
    if int(data.tool_level)>1:nearby.append_array([i-6,i+6])
    for j in nearby:
     if j<0 or j>=max_plots():continue
     if abs(j-i)==1 and int(j/6)!=int(i/6):continue
     if data.plots[j].tilled:data.plots[j].water=true
   commit(Lang.t("รดน้ำแล้ว วันนี้พืชจะโตเมื่อนอน"))
  2:
   var k=data.selected_seed
   if not p.tilled:notice.emit(Lang.t("ใช้จอบเตรียมดินก่อน"));return
   if p.crop!="":notice.emit(Lang.t("แปลงนี้ปลูกแล้ว"));return
   if int(data.seeds.get(k,0))<=0:notice.emit(Lang.t("เมล็ดหมด ซื้อเพิ่มที่ตลาด"));return
   data.seeds[k]-=1;p.crop=k;p.growth=0
   commit(Lang.t("ปลูก")+CROPS[k].title+Lang.t("แล้ว"))
  3:
   if p.crop=="":notice.emit(Lang.t("ยังไม่มีพืชในแปลง"));return
   if int(p.growth)<int(CROPS[p.crop].days):notice.emit(Lang.t("พืชยังไม่โต รดน้ำแล้วพักผ่อน"));return
   if not add_good(p.crop,2+int(data.farm_level)):return
   data.stats.harvest+=1
   p.crop="";p.growth=0;p.water=false
   commit(Lang.t("เก็บผลผลิตแล้ว เปิดกระเป๋าด้วย I"))
func buy_seed(k):
 if spend(CROPS[k].seed*5):data.seeds[k]=int(data.seeds.get(k,0))+5;commit(Lang.t("ซื้อเมล็ด")+CROPS[k].title+Lang.t(" 5 เมล็ด"))
func buy_feed():
 if not room_for(5):return
 if spend(30):add_good("feed",5);commit(Lang.t("ซื้ออาหารสัตว์ 5 ถุง"))
func add_animal(k,breed,charge=true):
 var pet=k in ["dog","cat"]
 if (pet and pet_count()>=2) or (not pet and barn_count()>=capacity()):notice.emit(Lang.t("พื้นที่เลี้ยงเต็มแล้ว อัปเกรดคอกก่อน"));return false
 if charge and not spend(int(SPECIES[k].cost)*(2 if breed>0 else 1)):return false
 var n=int(data.next_id);data.next_id+=1
 data.animals.append({"id":n,"species":k,"breed":breed,"age":0,"fed":false,"product":0,"bond":0,"x":15.0+float(n%4)*2.0,"z":4.0+float(n%3)*2.0})
 if charge:commit(Lang.t("ซื้อ")+SPECIES[k].title+Lang.t("วัยเด็กแล้ว"))
 return true
func animal_by_id(id):
 for a in data.animals:
  if int(a.id)==int(id):return a
 return {}
func mature(a):return int(a.age)>=int(SPECIES[a.species].days)
func feed_animal(id):
 var a=animal_by_id(id)
 if a.is_empty():return
 if a.fed:notice.emit(Lang.t("วันนี้ให้อาหารแล้ว"));return
 if not take("feed",1):notice.emit(Lang.t("อาหารหมด ซื้อที่ร้านสัตว์"));return
 a.fed=true;a.bond=min(100,int(a.bond)+8);commit(Lang.t("ให้อาหาร")+SPECIES[a.species].title+Lang.t("แล้ว"))
func collect_animal(id):
 var a=animal_by_id(id)
 if a.is_empty():return
 if int(a.product)<=0:notice.emit(Lang.t("ยังไม่มีผลผลิต ให้อาหารแล้วรอวันถัดไป"));return
 var k=SPECIES[a.species].yield+("_premium" if int(a.breed)>0 else "")
 var amount=min(int(a.product),bag_capacity()-bag_count())
 if amount<=0:notice.emit(Lang.t("กระเป๋าเต็ม ขายของหรืออัปเกรดบ้านก่อน"));return
 if not add_good(k,amount):return
 data.stats.animal_products+=amount;a.product-=amount
 commit(Lang.t("เก็บ")+good_title(k)+Lang.t("แล้ว"))
func sell_animal(id):
 var a=animal_by_id(id)
 if a.is_empty():return
 if a.species in ["dog","cat"]:notice.emit(Lang.t("สัตว์เลี้ยงเป็นเพื่อน ไม่รับขาย"));return
 var n=int(SPECIES[a.species].sale)*(2 if int(a.breed)>0 else 1)
 if not mature(a):n=int(n*.45)
 data.money+=n;data.animals.erase(a);data.stats.sold+=n;commit(Lang.t("ขายสัตว์ได้ ฿%d")%n)
func process_meat(id):
 var a=animal_by_id(id)
 if a.is_empty():return
 if not mature(a) or int(SPECIES[a.species].meat)<=0:notice.emit(Lang.t("รับเฉพาะปศุสัตว์โตเต็มวัย"));return
 if not add_good("meat"+("_premium" if int(a.breed)>0 else ""),int(SPECIES[a.species].meat)):return
 data.animals.erase(a);commit(Lang.t("ส่งแปรรูปและรับเนื้อเข้ากระเป๋าแล้ว"))
func sale_value(k,amount):
 if not data.bag.has(k) or k=="feed":return 0
 var freshness=clamp(1.0-(int(data.day)-int(data.bag[k].day))*.04,.7,1.0) if k.trim_suffix("_premium") in CROPS else 1.0
 return int(clamp(int(amount),0,qty(k))*price(k)*freshness)
func sell_good(k,amount=-1):
 if not data.bag.has(k) or k=="feed":return 0
 var count=qty(k) if amount<0 else clamp(int(amount),0,qty(k))
 if count==0:return 0
 var n=sale_value(k,count)
 data.money+=n;data.stats.sold+=n;data.bag[k].qty-=count
 if qty(k)==0:data.bag.erase(k)
 commit(Lang.t("ขาย %d ชิ้น ได้ ฿%d")%[count,n])
 return n
func sell_all():
 var n=0
 for k in data.bag.keys():n+=sell_good(k)
 notice.emit(Lang.t("ขายทั้งหมดได้ ฿%d")%n)
func upgrade(k):
 var key=k+"_level";var level=int(data[key]);var cost=(level+1)*{"farm":180,"tool":150,"home":250,"barn":200}[k]
 if level>=2:notice.emit(Lang.t("อัปเกรดสูงสุดแล้ว"));return
 if spend(cost):data[key]+=1;data.stats.upgrades+=1;commit(Lang.t("อัปเกรดแล้ว"))
func next_day(wake_hour=7.0):
 for p in data.plots:
  if p.crop!="" and p.water:
   if season()!=Lang.t("ฤดูหนาว") or int(data.day)%2==0:p.growth=min(int(p.growth)+1,int(CROPS[p.crop].days))
  p.water=false
 for a in data.animals:
  if a.fed:
   a.age+=1
   if mature(a):a.product+=int(SPECIES[a.species].qty)*(2 if int(a.breed)>0 else 1)
  a.fed=false
 data.day+=1;data.hour=wake_hour
 commit((Lang.t("เช้าวันใหม่") if wake_hour>=5 else Lang.t("วันใหม่"))+" · "+season()+Lang.t(" · วันที่ ")+str(data.day))
func advance_time(hours):
 data.hour+=hours
 while data.hour>=24:
  var remaining=data.hour-24.0
  next_day(remaining)
func save_game():
 var f=FileAccess.open(save_path,FileAccess.WRITE)
 if f:f.store_string(JSON.stringify(data))
func has_save():return FileAccess.file_exists(save_path)
func load_game():
 if not has_save():return false
 var v=JSON.parse_string(FileAccess.get_file_as_string(save_path))
 if not v is Dictionary or not v.has("plots") or not v.has("animals"):return false
 data=v
 return true
func save_settings():
 if not save_enabled:return
 var f=FileAccess.open("user://settings.json",FileAccess.WRITE)
 if f:f.store_string(JSON.stringify(settings))
func load_settings():
 if FileAccess.file_exists("user://settings.json"):
  var v=JSON.parse_string(FileAccess.get_file_as_string("user://settings.json"))
  if v is Dictionary:settings.merge(v,true)
