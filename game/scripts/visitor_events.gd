extends RefCounted
# Saved offers are resolved once, with all inventory checks before any payment.
const PEOPLE=[{"name":"มะลิ","asset":"seed"},{"name":"ลุงเพิ่ม","asset":"carpenter"},{"name":"ดาว","asset":"livestock"},{"name":"ภู","asset":"seed"}]
var farm
func _init(owner):farm=owner
func now():return int(farm.data.day)*24.0+float(farm.data.hour)
func state():
 if not farm.data.get("visitors") is Dictionary:
  farm.data.visitors={"seed":randi(),"serial":0,"day":int(farm.data.day),"count":0,"next_at":now()+1.0,"active":{},"pending":[],"history":[],"last_kind":""}
 if not farm.data.visitors.has("seed"):farm.data.visitors.seed=randi()
 return farm.data.visitors
func maybe_offer():
 var s=state()
 if not s.active.is_empty():return s.active
 if int(s.day)!=int(farm.data.day):s.day=int(farm.data.day);s.count=0
 if int(s.count)>=2 or now()<float(s.next_at) or float(farm.data.hour)<9 or float(farm.data.hour)>18:return {}
 return create_offer()
func create_offer(kind=""):
 var s=state()
 if not s.active.is_empty():return s.active
 if int(s.day)!=int(farm.data.day):s.day=int(farm.data.day);s.count=0
 s.serial=int(s.serial)+1
 var rng=RandomNumberGenerator.new();rng.seed=int(s.seed)+int(s.serial)*937+int(farm.data.day)*53
 var due={}
 for debt in s.pending:
  if int(debt.due_day)<=int(farm.data.day):due=debt;break
 if not due.is_empty():kind="repayment"
 elif kind=="":
  if int(s.serial)==1:kind="gift"
  else:
   var choices=["trade","gift","loan","kindness"];choices.erase(s.last_kind);kind=choices[rng.randi_range(0,choices.size()-1)]
 var person=int(due.person) if not due.is_empty() else rng.randi_range(0,PEOPLE.size()-1)
 var offer={"id":int(s.serial),"kind":kind,"person":person,"cost":{},"reward":{},"announced":false}
 match kind:
  "trade":
   if farm.qty("carrot")>=2:offer.cost={"goods":{"carrot":2}};offer.reward={"goods":{"feed":4}}
   elif farm.qty("egg")>=1:offer.cost={"goods":{"egg":1}};offer.reward={"seeds":{"tomato":2}}
   else:offer.cost={"money":25};offer.reward={"seeds":{"carrot":4}}
  "gift":offer.reward={"goods":{"feed":2}} if rng.randi()%2==0 else {"seeds":{"carrot":3}}
  "loan":offer.cost={"money":50};offer["due_day"]=int(farm.data.day)+2
  "kindness":
   offer.cost={"money":40}
   offer.reward=[{"seeds":{"pumpkin":2}},{"goods":{"feed":6}},{"goods":{"wool":2}}][rng.randi_range(0,2)]
  "repayment":offer.reward={"money":int(due.amount)};offer["pending_id"]=int(due.id)
  _:return {}
 s.active=offer;s.count=int(s.count)+1;s.last_kind=kind;farm.commit()
 return offer
func describe_bundle(bundle):
 var parts=[]
 if int(bundle.get("money",0))>0:parts.append("฿%d"%int(bundle.money))
 for key in bundle.get("goods",{}):parts.append(farm.good_title(key)+" ×%d"%int(bundle.goods[key]))
 for key in bundle.get("seeds",{}):parts.append(Lang.t("เมล็ด")+Lang.t(farm.CROPS[key].title)+" ×%d"%int(bundle.seeds[key]))
 return " + ".join(parts) if not parts.is_empty() else Lang.t("ไม่มีค่าใช้จ่าย")
func greeting(offer):
 match offer.kind:
  "trade":return Lang.t("มีของติดมือมา อยากแลกกับของในสวนคุณสักหน่อย")
  "gift":return Lang.t("เดินผ่านแถวนี้พอดี เลยเอาของเล็ก ๆ น้อย ๆ มาฝาก")
  "loan":return Lang.t("ขอยืม ฿50 ซื้ออุปกรณ์หน่อยได้ไหม? จะเอามาคืนวันที่ %d")%max(int(offer.due_day),int(farm.data.day)+2)
  "kindness":return Lang.t("เงินค่ารถกลับบ้านขาดอยู่ ฿40 ช่วยเราหน่อยได้ไหม?")
  "repayment":return Lang.t("เอาเงินที่ยืมไว้มาคืนแล้ว ขอบคุณที่ช่วยวันนั้นนะ")
 return ""
func resolve(id,accept):
 var s=state();var offer=s.active
 if offer.is_empty() or int(offer.id)!=int(id):return {"ok":false,"message":Lang.t("คุยกับผู้มาเยือนคนนี้เรียบร้อยแล้ว")}
 if accept:
  var cost=offer.cost;var reward=offer.reward;var outgoing=0;var incoming=0
  if int(farm.data.money)<int(cost.get("money",0)):return {"ok":false,"message":Lang.t("เงินยังไม่พอ ไว้พร้อมแล้วค่อยมาคุยกัน")}
  for key in cost.get("goods",{}):
   if farm.qty(key)<int(cost.goods[key]):return {"ok":false,"message":Lang.t("ของที่จะแลกยังไม่ครบ เก็บไว้ก่อนแล้วค่อยมาคุยกัน")}
   outgoing+=int(cost.goods[key])
  for key in reward.get("goods",{}):incoming+=int(reward.goods[key])
  if farm.bag_count()-outgoing+incoming>farm.bag_capacity():return {"ok":false,"message":Lang.t("เว้นที่ในกระเป๋าก่อน แล้วค่อยรับของนะ")}
  farm.data.money+=int(reward.get("money",0))-int(cost.get("money",0))
  for key in cost.get("goods",{}):farm.take(key,int(cost.goods[key]))
  for key in reward.get("goods",{}):farm.add_good(key,int(reward.goods[key]))
  for key in reward.get("seeds",{}):farm.data.seeds[key]=int(farm.data.seeds.get(key,0))+int(reward.seeds[key])
  if offer.kind=="loan":s.pending.append({"id":int(offer.id),"person":int(offer.person),"amount":int(cost.money),"due_day":int(farm.data.day)+2})
  if offer.kind=="repayment":
   for debt in s.pending.duplicate():
    if int(debt.id)==int(offer.pending_id):s.pending.erase(debt)
 var message=Lang.t("ขอบคุณที่แวะมาคุยกัน ไว้เจอกันใหม่นะ")
 if accept:
  message=Lang.t("ขอบคุณนะ ไว้จะแวะมาหาใหม่")
  if offer.kind=="kindness":message=Lang.t("จริง ๆ เรามาลองถามน้ำใจคนในหมู่บ้าน ขอบคุณที่ช่วยนะ ของนี้ให้แทนคำขอบคุณ")
  elif offer.kind=="loan":message=Lang.t("ขอบคุณที่ให้ยืม จะกลับมาคืนให้ตามที่นัดไว้")
 s.history.append(int(offer.id))
 if s.history.size()>64:s.history.pop_front()
 s.active={};s.next_at=now()+3.0+float(int(offer.id)%3)
 farm.commit()
 return {"ok":true,"message":message,"received":describe_bundle(offer.reward) if accept and not offer.reward.is_empty() else ""}
