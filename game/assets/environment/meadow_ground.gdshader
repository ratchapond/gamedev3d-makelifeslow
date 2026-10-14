shader_type spatial;
uniform sampler2D grass_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 season_tint : source_color = vec3(1.0);
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec3 detail=texture(grass_texture,UV*2.5).rgb;
 float lightness=dot(detail,vec3(.22,.62,.16));
 float patches=sin(world_position.x*.085+sin(world_position.z*.065)*1.8)*cos(world_position.z*.07)*.5+.5;
 vec3 meadow=mix(vec3(.29,.41,.16),vec3(.36,.48,.20),lightness*.25+patches*.15+.35);
 ALBEDO=mix(meadow,detail*vec3(.95,1.12,.80),.07)*season_tint;
 ROUGHNESS=1.0;
}
