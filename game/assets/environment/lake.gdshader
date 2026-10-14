shader_type spatial;
render_mode cull_disabled;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float wave=sin(world_position.x*2.8+TIME*.8)*sin(world_position.z*3.2-TIME*.9);
 float small=sin(world_position.x*10.0+world_position.z*7.0+TIME*1.8);
 ALBEDO=mix(vec3(.11,.34,.38),vec3(.30,.56,.56),.5+wave*.15+small*.035);
 NORMAL=normalize(NORMAL+vec3(wave*.045,0.0,small*.025));
 ROUGHNESS=.22;SPECULAR=.75;
}
