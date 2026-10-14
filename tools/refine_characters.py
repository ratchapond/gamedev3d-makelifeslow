"""Run with Blender 4.3+: refine exported game rigs without changing bone contracts.

Original 5.2 .blend files are retained in art-source/. This tool imports the
provided GLBs, preserving skin weights and clips, and saves editable refined rigs.
"""
import bpy,bmesh,math,json,sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
ORIGINAL=ROOT/'art-source/original-glb'
MODELS=ROOT/'game/assets/models';ART=ROOT/'art-source/refined';ART.mkdir(exist_ok=True)
TEXTURES=ROOT/'game/assets/textures/characters'
NAMES=['player','seed','livestock','carpenter']+[s+'_'+age for s in ['cow','chicken','duck','sheep','goat','pig','dog','cat'] for age in ['young','adult']]
report=[]
def add_material(name,color,rough=.8):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough
 return m

def detail_material(m,kind,strength):
 m.use_nodes=True;nodes=m.node_tree.nodes;links=m.node_tree.links;p=nodes.get('Principled BSDF')
 for n in nodes:
  if n.type=='TEX_IMAGE' and n.image:
   uv=nodes.new('ShaderNodeUVMap');uv.uv_map='UVMap';links.new(uv.outputs['UV'],n.inputs['Vector'])
 image=bpy.data.images.load(str(TEXTURES/(kind+'_normal.png')),check_existing=True);image.colorspace_settings.name='Non-Color'
 tex=nodes.new('ShaderNodeTexImage');tex.image=image;tex.label=kind+' surface detail'
 uv=nodes.new('ShaderNodeUVMap');uv.uv_map='UVMap';links.new(uv.outputs['UV'],tex.inputs['Vector'])
 normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=strength;links.new(tex.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],p.inputs['Normal'])

def skin_accessory(obj,rig,bone,parts):
 obj.vertex_groups.new(name=bone).add(list(range(len(obj.data.vertices))),1,'REPLACE')
 obj.parent=rig;mod=obj.modifiers.new('Follow original skeleton','ARMATURE');mod.object=rig
 for face in obj.data.polygons:face.use_smooth=True
 parts.append(obj)

def hat(rig,mesh,parts):
 top=max(v.co.z for v in mesh.data.vertices);z=top-.035
 straw=add_material('Sun-warmed woven straw',(.62,.42,.17));detail_material(straw,'straw',.35)
 band=add_material('Sage hat ribbon',(.12,.23,.17));detail_material(band,'linen',.22)
 # Curved solid brim, rounded crown and a soft cloth ribbon.
 for label,rad,depth,height,material in [('Wide curved brim',.285,.022,z,straw),('Rounded straw crown',.176,.15,z+.075,straw),('Sage ribbon',.178,.038,z+.034,band)]:
  bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=rad,depth=depth,location=(0,0,height));o=bpy.context.object;o.name=label;o.scale.y=.9
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  bevel=o.modifiers.new('Soft hat edges','BEVEL');bevel.width=.014 if label!='Sage ribbon' else .006;bevel.segments=3;bpy.ops.object.modifier_apply(modifier=bevel.name)
  o.data.materials.append(material)
  # Bake object transforms before joining, so accessories share the skin bind space.
  bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
  skin_accessory(o,rig,'Head',parts)

def workwear(rig,mesh,parts):
 denim=next(m for m in mesh.data.materials if m and 'Sage green denim' in m.name)
 seams=next(m for m in mesh.data.materials if m and 'Denim seams' in m.name)
 brass=next(m for m in mesh.data.materials if m and 'Old brass' in m.name)
 def panel(label,location,size,material,bone,bevel=.012):
  bpy.ops.mesh.primitive_cube_add(size=1,location=location);o=bpy.context.object;o.name=label;o.dimensions=size
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  mod=o.modifiers.new('Tailored rounded edges','BEVEL');mod.width=bevel;mod.segments=3;bpy.ops.object.modifier_apply(modifier=mod.name)
  o.data.materials.append(material);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);skin_accessory(o,rig,bone,parts)
 # A curved single cloth layer follows the torso instead of making a rigid plate.
 vertices=[];faces=[]
 for row in range(9):
  t=row/8;z=.87+t*.34
  for column in range(9):
   x=(column/8-.5)*.285;y=-.112-.03*math.sin(t*math.pi)+.027*(abs(x)/.1425)**2
   vertices.append((x,y,z))
 for row in range(8):
  for column in range(8):
   a=row*9+column;faces.append((a,a+1,a+10,a+9))
 data=bpy.data.meshes.new('Tailored curved bib');data.from_pydata(vertices,[],faces);data.materials.append(denim)
 uv=data.uv_layers.new(name='UVMap')
 for polygon in data.polygons:
  for loop in polygon.loop_indices:
   vertex=data.loops[loop].vertex_index;uv.data[loop].uv=(vertex%9/8,vertex//9/8)
 o=bpy.data.objects.new('Tailored curved bib',data);bpy.context.collection.objects.link(o);skin_accessory(o,rig,'Spine',parts)
 panel('Front work pocket',(0,-.148,1.035),(.125,.008,.09),seams,'Spine',.004)
 for x in [-.12,.12]:
  route=[Vector((x,-.145,1.18)),Vector((x,-.025,1.32)),Vector((x,.10,1.18))]
  for a,b in zip(route,route[1:]):
   bpy.ops.mesh.primitive_cube_add(size=1,location=(a+b)*.5);o=bpy.context.object;o.name='Soft denim shoulder strap';o.dimensions=(.052,.018,(b-a).length);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
   bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
   mod=o.modifiers.new('Soft strap hem','BEVEL');mod.width=.005;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
   o.data.materials.append(denim);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);skin_accessory(o,rig,'Spine',parts)
  bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=.017,location=(x,-.169,1.18));o=bpy.context.object;o.name='Brass strap button';o.scale.y=.38;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);o.data.materials.append(brass);skin_accessory(o,rig,'Spine',parts)
 for x,bone in [(.08,'ShinL'),(-.08,'ShinR')]:panel('Stitched knee reinforcement',(x,-.082,.43),(.098,.006,.115),seams,bone,.003)

def blink(mesh):
 eye_indices=set()
 for p in mesh.data.polygons:
  if p.material_index>=len(mesh.data.materials):continue
  mat=mesh.data.materials[p.material_index]
  if mat and any(s in mat.name.lower() for s in ['eye','iris','pupil','catchlight','glint']):eye_indices.update(p.vertices)
 if not eye_indices:return False
 mesh.shape_key_add(name='Basis');key=mesh.shape_key_add(name='Blink')
 # Human eyes divide along X; animal eyes divide along Y.
 human='Head' in mesh.vertex_groups and any('denim' in m.name.lower() or 'shirt' in m.name.lower() for m in mesh.data.materials if m)
 axis=0 if human else 1
 for side in [-1,1]:
  indices=[i for i in eye_indices if mesh.data.vertices[i].co[axis]*side>=0]
  if not indices:continue
  center=sum(mesh.data.vertices[i].co.z for i in indices)/len(indices)
  for i in indices:key.data[i].co.z=center+(mesh.data.vertices[i].co.z-center)*.08
 return True

args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
for name in (args or NAMES):
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(ORIGINAL/(name+'.glb')))
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
 for o in list(bpy.context.scene.objects):
  if o.type=='MESH' and o not in meshes:bpy.data.objects.remove(o,do_unlink=True)
 mesh=meshes[0];rig.data.pose_position='REST';bpy.context.view_layer.objects.active=mesh;mesh.select_set(True)
 before=sum(len(p.vertices)-2 for p in mesh.data.polygons)
 # Merge only coincident seam vertices; preserve separate facial/clothing geometry.
 bm=bmesh.new();bm.from_mesh(mesh.data)
 if name=='player':
  old_bib=[]
  for f in bm.faces:
   material=mesh.data.materials[f.material_index].name.lower();center=f.calc_center_median()
   if ('denim' in material) and .87<center.z<1.24 and center.y<-.06:old_bib.append(f)
  bmesh.ops.delete(bm,geom=old_bib,context='FACES')
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000003);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh.data);bm.free()
 subdiv=mesh.modifiers.new('Close-view silhouette refinement','SUBSURF');subdiv.subdivision_type='CATMULL_CLARK';subdiv.levels=1;subdiv.render_levels=1;subdiv.uv_smooth='PRESERVE_BOUNDARIES'
 while mesh.modifiers.find(subdiv.name)>0:bpy.ops.object.modifier_move_up(modifier=subdiv.name)
 bpy.ops.object.modifier_apply(modifier=subdiv.name)
 for p in mesh.data.polygons:p.use_smooth=True
 human=name in ['player','seed','livestock','carpenter']
 for m in mesh.data.materials:
  if not m:continue
  key=m.name.lower();p=m.node_tree.nodes.get('Principled BSDF') if m.use_nodes else None
  if not p:continue
  if any(t in key for t in ['eye','iris','pupil','catchlight','glint']):p.inputs['Roughness'].default_value=.22;continue
  if human:
   if any(t in key for t in ['denim','trouser','bib','seam']):detail_material(m,'denim',.28);p.inputs['Roughness'].default_value=.88
   elif any(t in key for t in ['cotton','shirt','apron','linen']):detail_material(m,'linen',.22);p.inputs['Roughness'].default_value=.92
   elif any(t in key for t in ['leather','boot']):detail_material(m,'leather',.22)
   elif 'straw' in key:detail_material(m,'straw',.3)
   elif 'hair' in key:detail_material(m,'fur',.18)
   elif 'skin' in key:p.inputs['Roughness'].default_value=.76
  else:
   if any(t in key for t in ['atlas','coat','fleece','feather','ivory','caramel','hair']):
    kind='fleece' if name.startswith('sheep') else 'feather' if name.startswith(('chicken','duck')) else 'fur'
    detail_material(m,kind,.32 if kind=='fleece' else .22);p.inputs['Roughness'].default_value=.9
   elif any(t in key for t in ['muzzle','nose']):p.inputs['Roughness'].default_value=.47
 parts=[]
 if name=='player':
  hat(rig,mesh,parts);workwear(rig,mesh,parts)
 if parts:
  bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True)
  for o in parts:o.select_set(True)
  bpy.context.view_layer.objects.active=mesh;bpy.ops.object.join()
 has_blink=blink(mesh)
 rig.data.pose_position='POSE'
 if name=='player':
  # Seated pose uses the original bone names and hand attachment.
  idle=next(s.action for t in rig.animation_data.nla_tracks for s in t.strips if 'Idle' in t.name)
  for t in rig.animation_data.nla_tracks:t.mute=True
  rig.animation_data.action=idle;bpy.context.scene.frame_set(1)
  pose={b.name:(b.location.copy(),b.rotation_quaternion.copy(),b.scale.copy()) for b in rig.pose.bones}
  sit=bpy.data.actions.new('Sit');rig.animation_data.action=sit
  from mathutils import Quaternion
  for b in rig.pose.bones:
   b.location,b.rotation_quaternion,b.scale=pose[b.name];b.rotation_mode='QUATERNION'
   if b.name.startswith('Thigh'):
    axis=b.bone.matrix_local.to_quaternion().inverted()@Vector((1,0,0));b.rotation_quaternion=Quaternion(axis,-1.28)
   if b.name.startswith('Shin'):
    axis=b.bone.matrix_local.to_quaternion().inverted()@Vector((1,0,0));b.rotation_quaternion=Quaternion(axis,1.45)
   for frame in [1,73]:
    b.keyframe_insert(data_path='location',frame=frame);b.keyframe_insert(data_path='rotation_quaternion',frame=frame);b.keyframe_insert(data_path='scale',frame=frame)
  track=rig.animation_data.nla_tracks.new();track.name='Sit';track.strips.new('Sit',1,sit)
 # Preserve animation names expected by the existing gameplay and hand attachment.
 if rig.animation_data:
  rig.animation_data.action=None
  for t in rig.animation_data.nla_tracks:t.mute=False
 for image in bpy.data.images:
  if image.source=='FILE' and not image.packed_file:
   try:image.pack()
   except RuntimeError:pass
 bpy.ops.wm.save_as_mainfile(filepath=str(ART/(name+'.blend')),compress=True)
 bpy.ops.export_scene.gltf(filepath=str(MODELS/(name+'.glb')),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_skins=True,export_morph=True,export_morph_normal=True,export_texcoords=True,export_normals=True,export_yup=True,export_cameras=False,export_lights=False)
 tris=sum(len(p.vertices)-2 for p in mesh.data.polygons)
 row={'asset':name,'triangles_before':before,'triangles':tris,'bytes':(MODELS/(name+'.glb')).stat().st_size,'blink':has_blink};report.append(row);print('REFINED',json.dumps(row),flush=True)
report_path=ROOT/'art-source/refined/report.json'
previous={r['asset']:r for r in json.loads(report_path.read_text())} if report_path.exists() else {}
previous.update({r['asset']:r for r in report})
report_path.write_text(json.dumps(list(previous.values()),indent=2)+'\n')
