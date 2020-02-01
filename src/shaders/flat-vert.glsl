#version 300 es
precision highp float;

// The vertex shader used to render the background of the scene

in vec4 vs_Pos;

out vec3 fs_Pos;
out float fs_fbm;


float rand(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


float interpNoise2D(vec2 p) {
    vec2 intP = floor(p);
    vec2 fractP = fract(p);

    // Get a random value from each of the 4 corners that contain point p
    float v1 = rand(intP);
    float v2 = rand(intP + vec2(1.0, 0.0));
    float v3 = rand(intP + vec2(0.0, 1.0));
    float v4 = rand(intP + vec2(1.0, 1.0));

    vec2 u = fractP * fractP * (3.0f - 2.0f * fractP);

    return mix(v1, v2, u.x) + (v3 - v1)* u.y * (1.0 - u.x) + (v4 - v2) * u.x * u.y;
}

float fbm3 (vec2 p) {
    // Initialize the variables to be used
    float total = 0.0;
    float amplitude = 0.5;
    int octaves = 8;

    // For loop that interates through octaves
    for (int i = 0; i < octaves; i++) {
        total += amplitude * interpNoise2D(p);
        p *= 1.5;
        amplitude *= .5;
    }

    return total;
}

void main() {
  float depth = fbm3(vec2(vs_Pos.x, vs_Pos.y) * 100.0);

  fs_Pos.x = vs_Pos.x;
  fs_Pos.y = vs_Pos.y;
  fs_Pos.z = vs_Pos.z;
  fs_fbm = depth;

  gl_Position = vs_Pos;
}
