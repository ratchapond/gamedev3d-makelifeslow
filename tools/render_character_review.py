import bpy,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
for index,path in enumerate([ROOT/'art-source/original-glb/player.glb',ROOT/'game/assets/models/player.glb']):
 existing=set(bpy.context.scene.objects)
 bpy.ops.import_scene.gltf(filepath=str(path))
 added=set(bpy.context.scene.objects)-existing
 rig=next(o for o in added if o.type=='ARMATURE')
 for o in list(added):
  if o.type=='MESH' and not any(m.type=='ARMATURE' for m in o.modifiers):bpy.data.objects.remove(o,do_unlink=True)
 if rig.animation_data:
  idle=next((s.action for t in rig.animation_data.nla_tracks for s in t.strips if 'Idle' in t.name),None)
  for t in rig.animation_data.nla_tracks:t.mute=True
  rig.animation_data.action=idle
 rig.location.x=(-.6 if index==0 else .6)
scene=bpy.context.scene;scene.frame_set(1);scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False
scene.render.resolution_x=1000;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Soft daylight');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.42,.52,.46,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
bpy.ops.mesh.primitive_plane_add(size=200);ground=bpy.context.object;mat=bpy.data.materials.new('Warm neutral floor');mat.diffuse_color=(.42,.49,.40,1);ground.data.materials.append(mat)
bpy.ops.object.camera_add(location=(2,-7,2.5));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.1;scene.camera=cam
for pos,power,size in [((2,-3,4),450,4),((-3,-1,2),200,3)]:
 bpy.ops.object.light_add(type='AREA',location=pos);light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((0,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
scene.view_settings.view_transform='AgX';scene.render.filepath='/workspace/scratch/farmer-refinement.png';bpy.ops.render.render(write_still=True)
