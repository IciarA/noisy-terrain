#version 300 es
precision highp float;

// The fragment shader used to render the background of the scene
// Modify this to make your background more interesting
uniform vec2 u_PlanePos;
uniform bool u_Night;

in vec3 fs_Pos;
in float fs_fbm;

out vec4 out_Col;


float rand(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}







// Perlin noise 
vec2 hash( vec2 x )
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

float noised( vec2 p )
{
  vec2 i = floor( p );
  vec2 f = fract( p );

  vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
  vec2 du = 30.0*f*f*(f*(f-2.0)+1.0);

  vec2 ga = hash( i + vec2(0.0,0.0) );
  vec2 gb = hash( i + vec2(1.0,0.0) );
  vec2 gc = hash( i + vec2(0.0,1.0) );
  vec2 gd = hash( i + vec2(1.0,1.0) );

  float va = dot( ga, f - vec2(0.0,0.0) );
  float vb = dot( gb, f - vec2(1.0,0.0) );
  float vc = dot( gc, f - vec2(0.0,1.0) );
  float vd = dot( gd, f - vec2(1.0,1.0) );

  return va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd);
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
    int octaves = 12;

    // For loop that interates through octaves
    for (int i = 0; i < octaves; i++) {
        total += amplitude * interpNoise2D(p);
        p *= 1.5;
        amplitude *= .5;
    }

    return total;
}




void main() {

  float t = fbm3(vec2(fs_Pos.y, fs_Pos.y));
  vec3 white = (rand(vec2(fs_Pos.x, fs_Pos.y))) * vec3(1.0, 1.0, 1.0) + (1.0 - rand(vec2(fs_Pos.x, fs_Pos.y))) * vec3(0.7, 0.7, 0.0);
  
  vec3 sky = vec3(164.0 / 255.0, 233.0 / 255.0, 1.0);
  vec3 night_sky = vec3(0.0, 0.0, 0.0);

  if (u_Night) {
    vec3 col = mix(night_sky, white, clamp(rand(vec2(fs_Pos.x, fs_Pos.y)) - 0.5, 0.0, 1.0));

    out_Col = vec4(col, 1.0);
  }
  else {
    white = vec3(1.0, 1.0, 1.0);
    vec3 col = mix(sky, white, noised(vec2(fs_Pos.x, fs_Pos.y) * 6.0));
    out_Col = vec4(col, 1.0);
    //out_Col = vec4(vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), 1.0);
  }

  //vec3 col = mix(sky, white, fbm3(vec2(fs_Pos.x + u_PlanePos.x, fs_Pos.y + u_PlanePos.y) * 10.0));
  //float r = rand(vec2(fs_Pos.x, fs_Pos.y));
  //float t = clamp((rand(vec2(fs_Pos.x, fs_Pos.y)) - 0.1), 0.0f, 1.0f);
  //vec3 col = mix(night_sky, white, clamp(rand(vec2(fs_Pos.x, fs_Pos.y)) - 0.5, 0.0, 1.0));

  //out_Col = vec4(col, 1.0);
  //out_Col = vec4(vec3(0.5 * ((fs_Pos.z + 1.0)), 0.3 * ((fs_Pos.z + 1.0)), 0.2 * ((fs_Pos.z + 1.0))), 1.0);

}
