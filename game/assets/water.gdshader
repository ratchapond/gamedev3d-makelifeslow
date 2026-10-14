shader_type spatial;
render_mode cull_disabled;
void fragment(){
 float ripple=sin(UV.x*18.0+TIME*0.65)*sin(UV.y*12.0-TIME*0.4);
 ALBEDO=mix(vec3(0.22,0.47,0.49),vec3(0.50,0.72,0.68),0.5+ripple*0.12);
 ROUGHNESS=0.4;
}
