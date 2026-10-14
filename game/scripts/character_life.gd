extends Node
# Small additive gestures run after the original animation clips.
var model
var game
var actor
var human = false
var skeleton
var head = -1
var eyes = []
var base_scale = Vector3.ONE
var elapsed = 0.0
var blink_clock = 0.0
var next_blink = 3.0
var blinking = false
var rng = RandomNumberGenerator.new()
var last_rotation = Quaternion.IDENTITY
var last_offset = Quaternion.IDENTITY
var has_offset = false

func setup(visual, context, is_human, seed_value):
 model = visual;game = context;actor = visual.get_parent();human = is_human
 rng.seed = seed_value;elapsed = rng.randf() * 20.0;next_blink = rng.randf_range(2.4, 5.0)
 base_scale = model.scale
 for node in model.find_children("*", "Skeleton3D", true, false): skeleton = node;break
 if skeleton: head = skeleton.find_bone("Head")
 for mesh in model.find_children("*", "MeshInstance3D", true, false):
  if not mesh.mesh: continue
  for i in range(mesh.mesh.get_blend_shape_count()):
   if mesh.mesh.get_blend_shape_name(i).to_lower() == "blink": eyes.append({"mesh": mesh, "index": i})
 process_priority = 25

func _process(dt):
 if not is_instance_valid(model) or not game or game.modal: return
 elapsed += dt;blink_clock += dt
 if not blinking and blink_clock >= next_blink:
  blinking = true;blink_clock = 0.0
 var blink_weight = 0.0
 if blinking:
  blink_weight = sin(clamp(blink_clock / 0.17, 0.0, 1.0) * PI)
  if blink_clock >= 0.17:
   blinking = false;blink_clock = 0.0;next_blink = rng.randf_range(2.6, 6.0)
 for eye in eyes:
  if is_instance_valid(eye.mesh) and abs(eye.mesh.get_blend_shape_value(eye.index) - blink_weight) > 0.001: eye.mesh.set_blend_shape_value(eye.index, blink_weight)
 # Subtle chest expansion; the feet stay anchored to the original root.
 model.scale = base_scale * Vector3(1.0 + sin(elapsed * 1.15) * 0.0015, 1.0 + sin(elapsed * 1.15) * 0.003, 1.0)
 if not skeleton or head < 0: return
 var yaw = sin(elapsed * 0.37) * (0.075 if human else 0.045)
 var pitch = sin(elapsed * 0.59) * 0.025
 if human and game.player and actor != game.player:
  var delta = game.player.global_position - actor.global_position
  if delta.length() < 5.5:
   var local = model.global_basis.inverse() * delta
   # Human meshes face local +Z; avoid rotating the neck towards someone behind.
   if local.z > 0.1: yaw = clamp(atan2(local.x, local.z), -0.35, 0.35)
 var rotation = skeleton.get_bone_pose_rotation(head)
 if has_offset and abs(rotation.dot(last_rotation)) > 0.999999: rotation = rotation * last_offset.inverse()
 var global_up = skeleton.get_bone_global_pose(head).basis.inverse() * Vector3.UP
 var offset = Quaternion(global_up.normalized(), yaw) * Quaternion(Vector3.RIGHT, pitch)
 last_rotation = rotation * offset;last_offset = offset;has_offset = true
 skeleton.set_bone_pose_rotation(head, last_rotation)
