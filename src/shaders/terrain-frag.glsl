#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Sine;

in float fs_dist;
in vec2 fs_point;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// get f(y) for straitaions but add noise to y before using f(y) 

float rand(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main()
{
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    //out_Col = vec4(mix(vec3(0.5 * (fs_Sine + 1.0)), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
    //out_Col = vec4(mix(vec3(0.5 * (fs_Pos.y + 1.0)), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
    // if (fs_Pos.y < 0.05) {
    //     out_Col = vec4(mix(vec3(fs_Pos.y, fs_Pos.y, 0.5 * ((fs_Pos.y + 1.0))), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
    // }
    // else {
        //out_Col = vec4(mix(vec3(0.5 * ((fs_Pos.y + 1.0))), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
        out_Col = vec4(mix(vec3(0.5 * ((fs_Pos.y + 1.0)), 0.3 * ((fs_Pos.y + 1.0)), 0.2 * ((fs_Pos.y + 1.0))), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
    //}
}
