#version 300 es
precision highp float;

uniform sampler2D TEXTURE_0;

in vec3 worldpos;
in vec2 uv;

#include "util.glsl"

out vec4 fragcolor;
void main(){

	vec4 albedo = texture(TEXTURE_0, uv);

	vec3 color = vec3(FOG_COLOR.r, FOG_COLOR.g * 0.7, FOG_COLOR.b * 0.5) + vec3(0.8, 0.9, 1.0) * fnight;

	float l = length(worldpos.xz);
		color += max0(0.01 / pow(l * (18.0 - fnight * 12.0), 8.0));
 		color *= exp(0.9 - l) / 5.0;
		albedo.rgb = color;

	fragcolor = albedo * CURRENT_COLOR;
}
