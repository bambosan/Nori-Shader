#version 300 es
#include "uniformPerFrameConstants.h"
uniform sampler2D TEXTURE_0;
precision highp float;
in vec3 sunc;
in vec3 moonc;
in vec3 zcol;
in vec3 cpos;
in vec3 lpos;
in vec3 tlpos;
#include "shader_settings.txt"
#include "common.glsl"
out vec4 fragcol;
void main(){
	fragcol = vec4(0.0, 0.0, 0.0, 1.0);
	vec3 ajp = normalize(vec3(cpos.x, -cpos.y + 0.128, -cpos.z));
	fragcol.rgb = csky(ajp, lpos, sunc, moonc);
	float bdither = texture(TEXTURE_0, gl_FragCoord.xy / 256.0).r;
	vec4 vc = ccv(ajp, tlpos, sunc, moonc, zcol, bdither);
	fragcol.rgb = fragcol.rgb * vc.a + vc.rgb;
	fragcol.rgb = colc(fragcol.rgb);
}
