#version 300 es
precision highp float;

in vec3 worldpos;

#include "util.glsl"

out vec4 fragcolor;
void main(){

	vec3 adjustedpos = vec3(worldpos.x, -worldpos.y + 0.128, -worldpos.z);

	posvec.upposition = normalize(vec3(0.0, abs(adjustedpos.y), 0.0));
	posvec.nworldpos = normalize(adjustedpos);
	materials.miestrength = 1.0;

	vec3 underscatter = renderSkyColor(posvec, materials);

	float iszenith = dot(posvec.nworldpos, posvec.upposition);
	vec4 color = vec4(underscatter, pow(1.0 - iszenith, 6.0));
		color.rgb = tonemap(color.rgb);

	fragcolor = color;
}
