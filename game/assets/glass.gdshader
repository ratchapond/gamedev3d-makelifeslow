shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform vec2 panel_size=vec2(800.0,500.0);
uniform float blur_pixels=1.8;
void fragment(){
 vec2 p=(UV-0.5)*panel_size;
 vec2 q=abs(p)-(panel_size*0.5-vec2(18.0));
 float d=length(max(q,0.0))+min(max(q.x,q.y),0.0)-18.0;
 float mask=1.0-smoothstep(-1.0,1.0,d);
 vec2 shift=SCREEN_PIXEL_SIZE*blur_pixels;
 vec3 bg=texture(screen_texture,SCREEN_UV).rgb;
 if(blur_pixels>0.0){
  bg=(bg*2.0+texture(screen_texture,SCREEN_UV+vec2(shift.x,shift.y)).rgb+texture(screen_texture,SCREEN_UV-vec2(shift.x,shift.y)).rgb+texture(screen_texture,SCREEN_UV+vec2(-shift.x,shift.y)).rgb+texture(screen_texture,SCREEN_UV+vec2(shift.x,-shift.y)).rgb)/6.0;
 }
 vec3 tint=mix(bg,vec3(0.09,0.19,0.16),0.72);
 float rim=(1.0-smoothstep(0.0,2.2,abs(d+1.2)))*0.18;
 tint+=rim+0.025*(1.0-UV.y);
 COLOR=vec4(tint,mask*0.96);
}
