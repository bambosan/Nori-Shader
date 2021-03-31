#version 300 es
precision highp float;
uniform mat4 WORLDVIEWPROJ;

in vec4 POSITION;
in vec2 TEXCOORD_0;

out vec3 worldpos;
out vec2 uv;

void main()
{
    worldpos = POSITION.xyz * vec3(15.0, 1.0, 15.0);
    gl_Position = WORLDVIEWPROJ * (POSITION * vec4(13.0, 1.0, 13.0, 1.0));

    uv = TEXCOORD_0;
}
