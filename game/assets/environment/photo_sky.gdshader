shader_type sky;
uniform sampler2D panorama : source_color, filter_linear_mipmap, repeat_enable;
uniform float day_amount = 1.0;
uniform float dusk_amount = 0.0;
void sky() {
 vec3 photo = texture(panorama, SKY_COORDS).rgb;
 vec3 warm = photo * vec3(1.16, 0.80, 0.59);
 vec3 day = mix(photo, warm, dusk_amount * 0.70);
 vec3 night = vec3(0.006, 0.012, 0.028) + photo * vec3(0.012, 0.018, 0.030);
 COLOR = mix(night, day, day_amount);
}
