#version 300 es
precision highp float;

uniform mat4 WORLDVIEWPROJ;
uniform mat4 WORLD;
uniform mat4 WORLDVIEW;
uniform mat4 PROJ;

uniform vec4 CHUNK_ORIGIN_AND_SCALE;
uniform vec4 FOG_COLOR;
uniform vec2 FOG_CONTROL;

uniform float RENDER_DISTANCE;
uniform float FAR_CHUNKS_DISTANCE;
uniform float RENDER_CHUNK_FOG_ALPHA;

in vec4 POSITION;
in vec4 COLOR;
in vec2 TEXCOORD_0;
in vec2 TEXCOORD_1;

const float rA = 1.0;
const float rB = 1.0;
const vec3 UNIT_Y = vec3(0,1,0);
const float DIST_DESATURATION = 56.0 / 255.0; //WARNING this value is also hardcoded in the water color, don'tchange

#ifndef BYPASS_PIXEL_SHADER
	out vec4 vcolor;
	out vec3 perchunkpos;
	out vec3 worldpos;
	out vec2 uv0;
	out vec2 uv1;
#endif

#ifdef FOG
	out float fogalpha;
#endif

void main()
{
    vec4 worldPos;
#ifdef AS_ENTITY_RENDERER
		vec4 pos = WORLDVIEWPROJ * POSITION;
		worldPos = pos;
#else
    worldPos.xyz = (POSITION.xyz * CHUNK_ORIGIN_AND_SCALE.w) + CHUNK_ORIGIN_AND_SCALE.xyz;
    worldPos.w = 1.0;

    // Transform to view space before projection instead of all at once to avoid floating point errors
    // Not required for entities because they are already offset by camera translation before rendering
    // World position here is calculated above and can get huge
    vec4 pos = WORLDVIEW * worldPos;
    pos = PROJ * pos;
#endif
	gl_Position = pos;

#ifndef BYPASS_PIXEL_SHADER
	vcolor = COLOR;
	perchunkpos = POSITION.xyz;
	worldpos = worldPos.xyz;
	uv0 = TEXCOORD_0;
	uv1 = TEXCOORD_1;
#endif

///// find distance from the camera

#if defined(FOG) || defined(BLEND)
	#ifdef FANCY
		vec3 relPos = -worldPos.xyz;
		float cameraDepth = length(relPos);
	#else
		float cameraDepth = pos.z;
	#endif
#endif

///// apply fog

#ifdef FOG
	float len = cameraDepth / RENDER_DISTANCE;
	#ifdef ALLOW_FADE
		len += RENDER_CHUNK_FOG_ALPHA;
	#endif
	fogalpha = clamp((len - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x), 0.0, 1.0);
#endif

///// blended layer (mostly water) magic
#ifdef BLEND
	//Mega hack: only things that become opaque are allowed to have vertex-driven transparency in the Blended layer...
	//to fix this we'd need to find more space for a flag in the vertex format. vcolor.a is the only unused part
	bool shouldBecomeOpaqueInTheDistance = vcolor.a < 0.95;
	if(shouldBecomeOpaqueInTheDistance) {
		#ifdef FANCY  /////enhance water
			float cameraDist = cameraDepth / FAR_CHUNKS_DISTANCE;
			vcolor = COLOR;
		#else
			// Completely insane, but if I don't have these two lines in here, the water doesn't render on a Nexus 6
			vec4 surfColor = vec4(vcolor.rgb, 1.0);
			vcolor = surfColor;

			vec3 relPos = -worldPos.xyz;
			float camDist = length(relPos);
			float cameraDist = camDist / FAR_CHUNKS_DISTANCE;
		#endif //FANCY

		float alphaFadeOut = clamp(cameraDist, 0.0, 1.0);
		vcolor.a = mix(vcolor.a, 1.0, alphaFadeOut);
	}
#endif

#ifndef BYPASS_PIXEL_SHADER
	#ifndef FOG
		// If the FOG_COLOR isn't used, the reflection on NVN fails to compute the correct size of the constant buffer as the uniform will also be gone from the reflection data
		vcolor.rgb += FOG_COLOR.rgb * 0.000001;
	#endif
#endif
}
