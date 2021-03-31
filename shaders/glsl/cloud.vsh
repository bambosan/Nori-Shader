#version 300 es
precision highp float;

uniform mat4 WORLDVIEWPROJ;
uniform mat4 WORLD;

in vec4 POSITION;
in vec4 COLOR;

out vec4 color;

void main()
{
	vec4 pos = WORLDVIEWPROJ * POSITION;
	vec4 worldPos = WORLD * POSITION;
 	gl_Position = pos;

 	color = vec4(0, 0, 0, 0);
}
