#version 300 es
#include "uniformEntityConstants.h"
#include "uniformShaderConstants.h"

uniform sampler2D TEXTURE_0;
uniform sampler2D TEXTURE_1;

#ifdef USE_MULTITEXTURE
	uniform sampler2D TEXTURE_2;
#endif
precision highp float;

in vec4 light;
in vec4 fogColor;
in vec2 uv;

#ifdef COLOR_BASED
	in vec4 vertColor;
#endif

#ifdef USE_OVERLAY
    // When drawing horses on specific android devices, overlay color ends up being garbage data.
    // Changing overlay color to high precision appears to fix the issue on devices tested
	in vec4 overlayColor;
#endif

#ifdef TINTED_ALPHA_TEST
	in float alphaTestMultiplier;
#endif

#ifdef GLINT
	in vec2 layer1UV;
	in vec2 layer2UV;
	in vec4 tileLightColor;
	in vec4 glintColor;
#endif

vec4 glintBlend(vec4 dest, vec4 source) {
	// glBlendFuncSeparate(GL_SRC_COLOR, GL_ONE, GL_ONE, GL_ZERO)
	return vec4(source.rgb * source.rgb, source.a) + vec4(dest.rgb, 0.0);
}

#include "util.cs.glsl"
#ifdef USE_EMISSIVE
#ifdef USE_ONLY_EMISSIVE
#define NEEDS_DISCARD(C) (C.a == 0.0 || C.a == 1.0 )
#else
#define NEEDS_DISCARD(C)	(C.a + C.r + C.g + C.b == 0.0)
#endif
#else
#ifndef USE_COLOR_MASK
#define NEEDS_DISCARD(C)	(C.a < 0.5)
#else
#define NEEDS_DISCARD(C)	(C.a == 0.0)
#endif
#endif

out vec4 fragcolor;
void main()
{
	vec4 color = vec4(1.0);
	vec2 suv = fract(uv * 32.0) * (1.0 / 64.0);

#ifndef NO_TEXTURE
#ifdef USE_OVERLAY
	if(
		TEXTURE_DIMENSIONS.xy == vec2(1024, 1024) ||
		TEXTURE_DIMENSIONS.xy == vec2(2048, 2048) ||
		TEXTURE_DIMENSIONS.xy == vec2(4096, 4096)
	){
		color = textureLod(TEXTURE_0, uv - suv, 0.0);
	} else {
		color = texture(TEXTURE_0, uv);
	}
#else
	color = textureLod(TEXTURE_0, uv - suv, 0.0);
#endif // use overlay

#ifdef MASKED_MULTITEXTURE
	vec4 tex1 = texture( TEXTURE_1, uv );

	// If tex1 has a non-black color and no alpha, use color; otherwise use tex1
	float maskedTexture = ceil( dot( tex1.rgb, vec3(1.0, 1.0, 1.0) ) * ( 1.0 - tex1.a ) );
	color = mix(tex1, color, clamp(maskedTexture, 0.0, 1.0));
#endif // MASKED_MULTITEXTURE

#if defined(ALPHA_TEST) && !defined(USE_MULTITEXTURE) && !defined(MULTIPLICATIVE_TINT)
	if(NEEDS_DISCARD(color))
		discard;
#endif // ALPHA_TEST

#ifdef TINTED_ALPHA_TEST
vec4 testColor = color;
testColor.a *= alphaTestMultiplier;
	if(NEEDS_DISCARD(testColor))
		discard;
#endif // TINTED_ALPHA_TEST
#endif // NO_TEXTURE

#ifdef COLOR_BASED
	color *= vertColor;
#endif

#ifdef MULTI_COLOR_TINT
	// Texture is a mask for tinting with two colors
	vec2 colorMask = color.rg;

	// Apply the base color tint
	color.rgb = colorMask.rrr * CHANGE_COLOR.rgb;

	// Apply the secondary color mask and tint so long as its grayscale value is not 0
	color.rgb = mix(color, colorMask.gggg * MULTIPLICATIVE_TINT_CHANGE_COLOR, ceil(colorMask.g)).rgb;
#else

#ifdef USE_COLOR_MASK
	color.rgb = mix(color.rgb, color.rgb*CHANGE_COLOR.rgb, color.a);
	color.a *= CHANGE_COLOR.a;
#endif

#ifdef ITEM_IN_HAND
	color.rgb = mix(color.rgb, color.rgb*CHANGE_COLOR.rgb, vertColor.a);
#if defined(MCPE_PLATFORM_NX) && defined(NO_TEXTURE) && defined(GLINT)
	// TODO(adfairfi): This needs to be properly fixed soon. We have a User Story for it in VSO: 102633
	vec3 dummyColor = texture(TEXTURE_0, vec2(0.0, 0.0)).rgb;
	color.rgb += dummyColor * 0.000000001;
#endif
#endif // MULTI_COLOR_TINT

#endif

#ifdef USE_MULTITEXTURE
	vec4 tex1 = texture( TEXTURE_1, uv );
	vec4 tex2 = texture( TEXTURE_2, uv );
	color.rgb = mix(color.rgb, tex1.rgb, tex1.a);
#ifdef ALPHA_TEST
	if (color.a < 0.5 && tex1.a == 0.0) {
		discard;
	}
#endif

#ifdef COLOR_SECOND_TEXTURE
	if (tex2.a > 0.0) {
		color.rgb = tex2.rgb + (tex2.rgb * CHANGE_COLOR.rgb - tex2.rgb)*tex2.a;//lerp(tex2.rgb, tex2 * changeColor.rgb, tex2.a)
	}
#else
	color.rgb = mix(color.rgb, tex2.rgb, tex2.a);
#endif
#endif

#ifdef MULTIPLICATIVE_TINT
	vec4 tintTex = texture(TEXTURE_1, uv);
#ifdef MULTIPLICATIVE_TINT_COLOR
	tintTex.rgb = tintTex.rgb * MULTIPLICATIVE_TINT_CHANGE_COLOR.rgb;
#endif

#ifdef ALPHA_TEST
	color.rgb = mix(color.rgb, tintTex.rgb, tintTex.a);
	if (color.a + tintTex.a <= 0.0) {
		discard;
	}
#endif

#endif

#ifdef USE_OVERLAY
	//use either the diffuse or the OVERLAY_COLOR
	color.rgb = mix(color, overlayColor, overlayColor.a).rgb;
#endif

#ifdef USE_EMISSIVE
	//make glowy stuff
	color *= mix(vec4(1.0), light, color.a );
#else
	color *= light;
#endif
	color.rgb = toLinear(color.rgb);
	color.rgb = tonemap(color.rgb);
	//apply fog
	color.rgb = mix( color.rgb, fogColor.rgb, fogColor.a );

#ifdef GLINT
	// Applies color mask to glint texture instead and blends with original color
	vec4 layer1 = texture(TEXTURE_1, fract(layer1UV)).rgbr * glintColor;
	vec4 layer2 = texture(TEXTURE_1, fract(layer2UV)).rgbr * glintColor;
	vec4 glint = (layer1 + layer2) * tileLightColor;

	color = glintBlend(color, glint);
#endif

	//WARNING do not refactor this
#ifdef UI_ENTITY
	color.a *= HUD_OPACITY;
#endif
	fragcolor = color;
}
