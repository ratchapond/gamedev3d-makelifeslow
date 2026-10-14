extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.get_node("Farm").save_enabled=false
 var lang=root.get_node("Lang")
 var g=load("res://main.tscn").instantiate();root.add_child(g)
 lang.set_language("th");g.ui.credits()
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://creators_th_preview.png")
 lang.set_language("en");g.ui.settings_screen()
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://settings_en_preview.png")
 g.ui.title_screen()
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://title_en_preview.png")
 quit()
