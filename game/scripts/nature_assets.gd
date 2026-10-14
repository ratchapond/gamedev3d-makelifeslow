extends RefCounted
var world
var prefabs={}
var batches={}
func _init(owner):world=owner
func prefab(key):
 if prefabs.has(key):return prefabs[key]
 var scene=load("res://assets/environment/nature/"+key+".gltf").instantiate()
 world.add_child(scene);scene.visible=false
 var items=[];var groups={};var bounds=AABB();var first=true
 for part in scene.find_children("*","MeshInstance3D",true,false):
  var transform=world.global_transform.affine_inverse()*part.global_transform
  var box=transform*part.get_aabb()
  bounds=box if first else bounds.merge(box);first=false
  for surface in part.mesh.get_surface_count():
   var material=part.mesh.surface_get_material(surface)
   var group_key=material.resource_name if material else "default"
   if not groups.has(group_key):
    var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
    if material is StandardMaterial3D:
     material=material.duplicate();material.cull_mode=BaseMaterial3D.CULL_DISABLED
     material.roughness=1.0;material.diffuse_mode=BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
     material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
     if key=="Bush_Common":
      material.albedo_texture=load("res://assets/environment/nature/Leaves_TwistedTree.png");material.albedo_color=Color("79a864")
     if key=="Plant_1":material.uv1_offset=Vector3(-.175,0,0)
     if key=="Plant_7":material.uv1_scale=Vector3(1,.825,1)
     if material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
      material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;material.alpha_scissor_threshold=.45
    groups[group_key]={"st":st,"material":material}
   groups[group_key].st.append_from(part.mesh,surface,transform)
 for group in groups.values():
  var mesh=group.st.commit();mesh.surface_set_material(0,group.material)
  items.append({"mesh":mesh,"transform":Transform3D.IDENTITY})
 scene.free()
 # Include off-centre leaves in a rotation-independent horizontal footprint.
 var radius=0.0
 for i in range(8):
  var corner=bounds.get_endpoint(i)
  radius=max(radius,Vector2(corner.x,corner.z).length())
 var result={"items":items,"height":max(bounds.size.y,.01),"bottom":bounds.position.y,"radius":radius}
 prefabs[key]=result;return result
func place(key,p,height,angle=0.0,shadows=false):
 var source=prefab(key);var scale_v=height/source.height
 # Check every placement, including hand-placed shrubs and tree-base ferns.
 # Reserve the whole foliage footprint plus a small verge outside the road.
 if key.begins_with("Bush_") or key.begins_with("Flower_") or key.begins_with("Fern_") or key.begins_with("Clover_") or key.begins_with("Plant_"):
  if world.road_clearance(p)<source.radius*abs(scale_v)+.45:return false
 var placement=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*scale_v),p+Vector3(0,-source.bottom*scale_v,0))
 for i in source.items.size():
  var batch_key=key+":"+str(i)+":"+str(shadows)
  if not batches.has(batch_key):batches[batch_key]={"asset":key,"mesh":source.items[i].mesh,"transforms":[],"shadows":shadows}
  batches[batch_key].transforms.append(placement*source.items[i].transform)
 return true
func flush(parent):
 for batch in batches.values():
  var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=batch.mesh;mm.instance_count=batch.transforms.size()
  for i in batch.transforms.size():mm.set_instance_transform(i,batch.transforms[i])
  var node=MultiMeshInstance3D.new();node.set_meta("nature_asset",batch.asset);node.multimesh=mm;node.visibility_range_end=145;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if batch.shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node)
 batches.clear()
