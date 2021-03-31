#version 300 es
precision highp float;
uniform mat4 WORLDVIEWPROJ;

in vec4 POSITION;

out float isskyhorizon;

void main(){

    vec4 position = POSITION;
        position.y -= length(position.xz) * 0.2;
    gl_Position = WORLDVIEWPROJ * position;

    isskyhorizon = length(POSITION.xz);
}
