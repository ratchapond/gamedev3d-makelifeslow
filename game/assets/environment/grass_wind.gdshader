shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform sampler2D leaf_texture : source_color, filter_linear_mipmap, repeat_enable;
varying float tint;
void vertex(){
 tint=INSTANCE_CUSTOM.r;
 float phase=INSTANCE_CUSTOM.a*6.283;
 VERTEX.x+=sin(TIME*.95+phase+NODE_POSITION_WORLD.x*.11)*max(VERTEX.y,0.0)*.07;
}
void fragment(){
 vec4 blade=texture(leaf_texture,UV);
 ALBEDO=blade.rgb*mix(vec3(.83,.96,.72),vec3(1.06,1.08,.87),tint);
 ALPHA=blade.a;ALPHA_SCISSOR_THRESHOLD=.45;ROUGHNESS=1.0;
}
