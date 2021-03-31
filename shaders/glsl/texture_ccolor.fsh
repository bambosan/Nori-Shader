#version 300 es
precision highp float;

uniform vec3 TEXTURE_DIMENSIONS;
uniform vec4 CURRENT_COLOR;
uniform sampler2D TEXTURE_0;

in vec2 uv;

out vec4 fragcolor;
void main()
{
	vec2 suv = fract(uv * 32.0) * (1.0 / 64.0);
	vec4 diffuse;
	if(
		TEXTURE_DIMENSIONS.xy == vec2(1024, 1024) ||
		TEXTURE_DIMENSIONS.xy == vec2(2048, 2048) ||
		TEXTURE_DIMENSIONS.xy == vec2(4096, 4096)
	){
		diffuse = textureLod(TEXTURE_0, uv - suv, 0.0);
	} else {
		diffuse = texture(TEXTURE_0, uv);
	}

#ifdef ALPHA_TEST
	if(diffuse.a < 0.5) discard;
#endif

	fragcolor = CURRENT_COLOR * diffuse;
}
