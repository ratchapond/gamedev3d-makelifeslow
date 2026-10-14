extends RefCounted
# Dedicated vegetable geometry. Leaf topology and habit are specific to each crop.
var cache={}
var groups={}
var green=Color("548743")
var fresh=Color("6d9a4b")
func group(key):
 if not groups.has(key):
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);groups[key]=st
 return groups[key]
func triangle(key,a,b,c,color):
 var st=group(key);var normal=(b-a).cross(c-a).normalized()
 for point in [a,b,c]:st.set_color(color);st.set_normal(normal);st.add_vertex(point)
func stem(a,b,radius,color=Color("5b8140"),key="foliage"):
 var axis=(b-a).normalized();var side=axis.cross(Vector3.RIGHT if abs(axis.x)<.8 else Vector3.FORWARD).normalized();var other=axis.cross(side).normalized()
 for i in range(6):
  var angle=float(i)/6*TAU;var angle2=float(i+1)/6*TAU
  var v=side*cos(angle)+other*sin(angle);var w=side*cos(angle2)+other*sin(angle2)
  triangle(key,a+v*radius,b+v*radius*.7,a+w*radius,color)
  triangle(key,a+w*radius,b+v*radius*.7,b+w*radius*.7,color)
func leaf(origin,direction,length_v,width,kind,color=Color("548743")):
 var axis=direction.normalized();var side=Vector3.UP.cross(axis).normalized()
 if side.length()<.1:side=Vector3.RIGHT
 var edge=[]
 if kind=="pumpkin":
  # Broad, cordate base, five shallow palmate lobes, not a clover.
  for i in range(40):
   var angle=float(i)/40*TAU
   var radius=.80+.20*cos(5*angle)
   var u=sin(angle)*radius*.5
   var t=.48+cos(angle)*radius*.48
   if cos(angle)<-.7:t+=.14
   edge.append(Vector2(u,t))
 else:
  var segments=12 if kind=="tomato" else 6
  for sign_v in [-1,1]:
   for i in range(segments+1):
    var t=float(i)/segments if sign_v==-1 else 1.0-float(i)/segments
    var curve=pow(max(sin(t*PI),0.0),.65)
    var serration=(.77 if i%2==0 else 1.0) if kind=="tomato" else 1.0
    edge.append(Vector2(sign_v*curve*.5*serration,t))
 var center=origin+axis*length_v*.48+Vector3.UP*length_v*.08
 for i in range(edge.size()):
  var points=[]
  for q in [edge[i],edge[(i+1)%edge.size()]]:
   var bend=sin(q.y*PI)*length_v*.08-q.y*q.y*length_v*.06
   points.append(origin+axis*q.y*length_v+side*q.x*width+Vector3.UP*bend)
  triangle("foliage",center,points[0],points[1],color.lightened(.05 if i%3==0 else 0))
 # A raised midrib remains visible at close range.
 if length_v>.09:stem(origin,origin+axis*length_v*.9+Vector3.UP*length_v*.018,.0015,Color("85aa60"))
func fruit(center,size,color,kind="tomato"):
 var rings=10;var sectors=20
 for iy in range(rings):
  for ix in range(sectors):
   var points=[]
   for uv in [Vector2(ix,iy),Vector2(ix+1,iy),Vector2(ix,iy+1),Vector2(ix+1,iy+1)]:
    var theta=uv.x/sectors*TAU;var phi=uv.y/rings*PI
    var ribs=1.0+(.065*cos(theta*10) if kind=="pumpkin" else .018*cos(theta*5))
    points.append(center+Vector3(cos(theta)*sin(phi)*size.x*ribs,cos(phi)*size.y,sin(theta)*sin(phi)*size.z*ribs))
   var tint=color.darkened(.055 if kind=="pumpkin" and ix%2==0 else 0)
   triangle("fruit",points[0],points[2],points[1],tint);triangle("fruit",points[1],points[2],points[3],tint)
func seedling(crop):
 var h=.085 if crop=="carrot" else .11
 stem(Vector3.ZERO,Vector3(0,h,0),.003)
 var length_v=.055 if crop=="carrot" else .075
 var width=.012 if crop=="carrot" else .032 if crop=="tomato" else .05
 for sign_v in [-1,1]:leaf(Vector3(0,h,0),Vector3(sign_v,.12,.2),length_v,width,"oval",fresh)
func carrot(stage):
 if stage==0:seedling("carrot");return
 var height=.22 if stage==1 else .39
 for frond in range(4 if stage==1 else 7):
  var angle=float(frond)/7*TAU+.24
  var lateral=Vector3(sin(angle),0,cos(angle))
  var tip=lateral*(.075 if stage==1 else .14)+Vector3(0,height*(.85+float(frond%3)*.07),0)
  stem(Vector3.ZERO,tip,.0028)
  for level in range(1,7):
   var t=float(level)/7;var joint=tip*t
   var reach=(1-t)*(.08 if stage==1 else .125)
   var side=Vector3(-lateral.z,.15,lateral.x).normalized()
   for sign_v in [-1,1]:
    var end=joint+side*sign_v*reach+lateral*.02
    stem(joint,end,.0015)
    # Secondary narrow pinnules create the finely divided carrot foliage.
    for piece in range(3):
     var point=joint.lerp(end,float(piece+1)/4)
     for direction in [-1,1]:
      leaf(point,(lateral*direction+side*sign_v*.4+Vector3.UP*.15),reach*.38,.009 if stage==1 else .014,"oval",green if piece%2 else fresh)
  leaf(tip,lateral+Vector3.UP*.3,.035,.012,"oval",green)
 if stage==2:
  # The storage root is underground. Only its shoulder protrudes above the soil.
  var center=Vector3(0,-.04,0)
  fruit(center,Vector3(.047,.095,.047),Color("d98835"),"carrot")
  stem(Vector3(0,-.07,0),Vector3(.008,-.24,.004),.025,Color("c9762c"),"fruit")
func compound_leaf(origin,axis,length_v):
 var direction=axis.normalized();var side=Vector3.UP.cross(direction).normalized()
 var end=origin+direction*length_v
 stem(origin,end,.003)
 for t in [.35,.67]:
  for sign_v in [-1,1]:
   var root=origin.lerp(end,t)
   var leaf_direction=(side*sign_v+direction*.36+Vector3.UP*.10).normalized()
   stem(root,root+leaf_direction*.025,.002)
   leaf(root+leaf_direction*.02,leaf_direction,length_v*.55,length_v*.28,"tomato",green)
 leaf(end,direction,length_v*.65,length_v*.34,"tomato",fresh)
func flower(center,radius):
 for i in range(5):
  var angle=float(i)/5*TAU
  var direction=Vector3(sin(angle),.08,cos(angle))
  leaf(center,direction,radius,radius*.40,"oval",Color("e8ca53"))
 fruit(center+Vector3(0,.003,0),Vector3.ONE*radius*.13,Color("b89e3d"))
func tomato(stage):
 if stage==0:seedling("tomato");return
 var height=[.11,.34,.67,.96][stage]
 var base=Vector3.ZERO
 var top=Vector3(.04,height,0)
 stem(base,top,.009)
 for level in range(3 if stage==1 else 5):
  var y=height*(.18+level*.15);var angle=level*2.35+.15
  var direction=Vector3(cos(angle),.18,sin(angle)).normalized()
  var root=Vector3(.04*y/height,y,0);var branch=root+direction*(.07 if stage==1 else .11)
  stem(root,branch,.005)
  compound_leaf(branch,direction,.11 if stage==1 else .22 if stage==2 else .29)
 compound_leaf(top,Vector3(-.25,.35,.3),.12)
 if stage>=2:
  # A slim garden stake supports the upright, branching plant.
  stem(Vector3(-.10,-.02,.05),Vector3(-.10,height+.10,.05),.012,Color("b09a76"),"fruit")
  stem(Vector3(-.10,height*.55,.05),Vector3(.025,height*.55,0),.0025,Color("bbbd93"),"fruit")
  for bunch in range(2 if stage==2 else 3):
   var angle=.35+bunch*2.3;var axis=Vector3(sin(angle),0,cos(angle))
   var start=Vector3(0,height*(.35+bunch*.18),0);var tip=start+axis*.25+Vector3(0,.06,0)
   stem(start,tip,.004)
   for i in range(2):
    var position=tip+Vector3((i-.5)*.105,-.055,0)
    var radius=.038 if stage==2 else .076+float((bunch+i)%2)*.012
    var color=Color("80a449") if stage==2 else Color("db5336") if (bunch+i)%3 else Color("df7642")
    stem(tip,position+Vector3(0,radius,0),.0027)
    fruit(position,Vector3(radius,radius*.90,radius),color)
    for sepal in range(5):
     var a=float(sepal)/5*TAU;leaf(position+Vector3(0,radius*.83,0),Vector3(sin(a),.08,cos(a)),radius*.64,radius*.21,"oval",green)
  flower(top+Vector3(.065,-.08,.01),.021)
func pumpkin(stage):
 if stage==0:seedling("pumpkin");return
 var size_v=[.1,.38,.72,.93,1.12][stage]
 var curve=[]
 for i in range(11):
  var t=float(i)/10;curve.append(Vector3((t-.15)*size_v,.025+sin(t*PI)*.015,sin(t*PI*1.5)*size_v*.23))
 for i in range(10):stem(curve[i],curve[i+1],.005 if stage==1 else .012)
 for i in range(1,10,2):
  var node=curve[i];var side=-1 if i%4==1 else 1
  var leaf_length=.11 if stage==1 else .23 if stage==2 else .29
  var root=node+Vector3(0,.10 if stage==1 else .19,side*.09)
  stem(node,root,.003 if stage==1 else .007)
  leaf(root,Vector3(-.2,.10,side),leaf_length,leaf_length*.94,"pumpkin",green.lightened(float(i%3)*.04))
  # A coiled tendril grows from a vine node.
  if stage>=2:
   var previous=node
   for j in range(12):
    var a=float(j)*.8;var point=node+Vector3(.015*j,sin(a)*.018+.03,cos(a)*.018)
    stem(previous,point,.0018);previous=point
 if stage>=2:flower(curve[6]+Vector3(0,.08,-.10),.055 if stage==2 else .07)
 if stage>=3:
  var center=curve[8]+Vector3(.01,.115 if stage==3 else .18,-.20)
  var radius=.13 if stage==3 else .225
  fruit(center,Vector3(radius,radius*.79,radius),Color("6e9945") if stage==3 else Color("db8b38"),"pumpkin")
  var fruit_top=center+Vector3(0,radius*.79,0)
  stem(curve[8],fruit_top+Vector3(-.04,.025,0),.012,Color("77954c"))
  stem(fruit_top,fruit_top+Vector3(-.04,.065,0),.018,Color("647b40"))
func get_model(crop,stage):
 var key=crop+":"+str(stage)
 if cache.has(key):return cache[key]
 groups={}
 match crop:
  "carrot":carrot(stage)
  "tomato":tomato(stage)
  "pumpkin":pumpkin(stage)
 var parts=[]
 for name in groups:
  var mesh=groups[name].commit()
  var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.vertex_color_is_srgb=true;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.roughness=.58 if name=="fruit" else 1.0;material.diffuse_mode=BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
  mesh.surface_set_material(0,material);parts.append(mesh)
 cache[key]=parts;return parts
