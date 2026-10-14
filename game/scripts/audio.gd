extends Node
var music
var ambient
func _ready():
 for bus in ["Music","Sfx","Ambient"]:
  if AudioServer.get_bus_index(bus)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
 music=AudioStreamPlayer.new();music.bus="Music";music.stream=load("res://assets/audio/meadow.ogg");music.stream.loop=true;add_child(music)
 ambient=AudioStreamPlayer.new();ambient.bus="Ambient";ambient.stream=load("res://assets/audio/valley.ogg");ambient.stream.loop=true;add_child(ambient)
 apply_settings()
func start():
 if DisplayServer.get_name()=="headless":return
 music.play();ambient.play()
func _exit_tree():
 if music:music.stop();music.stream=null
 if ambient:ambient.stop();ambient.stream=null
func apply_settings():
 for pair in [["Master","master"],["Music","music"],["Sfx","sfx"],["Ambient","ambient"]]:
  var idx=AudioServer.get_bus_index(pair[0]);var v=float(Farm.settings[pair[1]]);AudioServer.set_bus_volume_db(idx,linear_to_db(max(.0001,v)));AudioServer.set_bus_mute(idx,v<.001)
func play_sfx(name,db=0):
 if DisplayServer.get_name()=="headless":return
 var path="res://assets/audio/"+name+".wav"
 if not ResourceLoader.exists(path):return
 var p=AudioStreamPlayer.new();p.bus="Sfx";p.stream=load(path);p.volume_db=db;add_child(p);p.finished.connect(p.queue_free);p.play()
