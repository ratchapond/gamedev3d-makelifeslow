shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform bool horizontal=false;
void vertex(){
 if(!horizontal){VERTEX.z+=sin(VERTEX.x*7.0+TIME*2.1)*.035;}
}
void fragment(){
 float stream=sin(UV.x*35.0+sin(UV.y*11.0-TIME*3.0)*.5)*.5+.5;
 float streak=sin(UV.y*24.0-TIME*5.0+UV.x*5.0)*.5+.5;
 float white=smoothstep(.55,.94,stream*.72+streak*.3)*.55;
 ALBEDO=mix(vec3(.28,.58,.60),vec3(.82,.95,.92),white);
 ROUGHNESS=.27;SPECULAR=.45;
}
