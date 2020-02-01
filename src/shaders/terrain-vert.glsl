#version 300 es

// Perlin noise broad - absolute value, clmaped 
// Perlin noise [-1, 1] - absolute value so -1 is 1 now, clamp absoute value to get valleys and multiply with fbm
// Adjust with smoothstep
// Smoothstep creates transition ()
// Can also use sin functions

// 2 noise functions - one for mountains and one for groudn - combine using fbm as t for 

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_Mount;
uniform float u_Perlin;
uniform float u_Path;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_dist;
out vec2 fs_point;

out vec2 fs_p;
out float fs_test;
out float fs_colM1;
out float fs_colM2;
out float fs_tval;
out float fs_ry;


float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

float rand(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 random(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float interpNoise(float x, float y) {
  float intX = floor(x);
  float fractX = fract(x);
  float intY = floor(y);
  float fractY = fract(y);

  float v1 = rand(vec2(intX, intY));
  float v2 = rand(vec2(intX + 1.f, intY));
  float v3 = rand(vec2(intX, intY + 1.f));
  float v4 = rand(vec2(intX + 1.f, intY + 1.f));

  float i1 = mix(v1, v2, fractX);
  float i2 = mix(v3, v4, fractX);
  return mix(i1, i2, fractY);
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

float fbm32 (vec2 p) {
    // Initialize the variables to be used
    float total = 0.0;
    float amplitude = 0.5;
    int octaves = 8;

    // For loop that interates through octaves
    for (int i = 0; i < octaves; i++) {
        total += amplitude * interpNoise2D(p);
        p *= 3.0;
        amplitude *= .5;
    }

    return total;
}

float fbm(float x, float y) {
  float total = 0.f;
  float persistence = 0.1f;
  int octaves = 8;

  for (int i = 0; i < octaves; i++) {
    float i_float = float(i);
    float freq = pow(2.f, i_float);
    float amp = pow(persistence, i_float);

    total += interpNoise(x * freq, y * freq) * amp;
  }

  return total;
}



// Perlin noise 
vec2 hash( vec2 x )
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + u_Perlin*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
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




void main()
{
  // The dimensions of the cell division, based on the dimensions of the screen.
  float m = 0.1f;
  float n = 0.1f;

  // The cell where the current point is
  vec2 p = vec2(floor((vs_Pos.x + u_PlanePos.x) * m), floor((vs_Pos.z + u_PlanePos.y) * n));
  // The random point within that cell
  vec2 randVec = p + random(p);

  // Variables to keep track of the closest random point to the current point and their distance
  vec2 final_point = randVec;
  vec2 curr_rand = randVec;
  float dist = 999999.00;
  float dist2 = 999999.00;
  float dist3 = 999999.00;

  float result = 0.f;

  // Worley Noise (not used, left just in case)
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      float i_float = float(i);
      float j_float = float(j);
      // Random point at the current cell.
      curr_rand = vec2(p[0] + i_float - 1.f, p[1] + j_float - 1.f) + random(vec2 (p[0] + i_float - 1.f, p[1] + j_float - 1.f));
      // Distance from random point to current point.
      float curr_dist = sqrt(pow((vs_Pos.x + u_PlanePos.x) * m - curr_rand[0], 2.f) + pow((vs_Pos.z + u_PlanePos.y) * n - curr_rand[1], 2.f));
      // If the distance is smaller than previous distance, store that distance and the current random point.
      if (curr_dist < dist) {
        dist2 = dist;
        dist = curr_dist;
        final_point = curr_rand;
      }
      else if (curr_dist < dist2) {
        dist3 = dist2;
        dist2 = curr_dist;
      }
      else if (curr_dist < dist3) {
        dist3 = curr_dist;
      }
    }
  }

  result = -dist + dist2;
  result = pow(clamp(result, 0.1f, 0.9f) - 0.1f, 0.5f);

    float final_result = pow(mix(result, fbm3(p), 0.3f), 4.f) * 5.f;


  p = vec2(vs_Pos.x + u_PlanePos.x, vs_Pos.z + u_PlanePos.y);
  vec2 q = vec2( fbm3( p ), fbm3( vec2(p.x + 5.2, p.y + 1.3) ) );
  vec2 test_p = p + 4.0 * q;
  float test = fbm3( test_p );



  
  
  // Mountains
  float path = smoothstep(0.2, 0.7, abs(noised(p / 10.0)) * u_Path);
  float mountains = ((path * smoothstep(0.0, 2.0, fbm3(p) * 3.0)) * 2.5);

  if (mountains < 0.2) {
    mountains = mix(mountains, test, 0.2);
  }

  // Flat ground
  float ground = mix((smoothstep(0.001, 0.3, abs(noised(p / 20.0))) / 4.f), fbm3(p), 0.4);

  // Mixing val
  float t = smoothstep(0.45, 0.55, fbm(p.x / 15.f, p.y / 15.f));
  float height = mix(mountains, ground, t);
  if (u_Mount <= 1.0) {
    t = smoothstep(0.45, 0.55, fbm(p.x / 15.f, p.y / 15.f)) * u_Mount;
    height = mix(mountains, ground, t);
  }
  else {
    t = smoothstep(0.45, 0.55, fbm(p.x / 15.f, p.y / 15.f));
    if (t <= 0.95) {
      t = u_Mount - 1.0;
    }
    height = mix(mountains, ground, t);
  }
  

  
  fs_Pos.x = vs_Pos.x;
  fs_Pos.y = height;
  fs_Pos.z = vs_Pos.z;
  fs_tval = t;
  fs_ry = height + ((fbm3(p * 20.0) - 0.5) / 4.0);

  fs_p = p;
  fs_test = fbm3(p * 5.0);
  fs_colM1 = fbm3( test_p * 10.0 );
  vec2 col2 = vec2(height, vs_Pos.x);
  fs_colM2 = fbm(col2.x * 10.0, col2.y * 10.f);
  

  vec4 modelposition = vec4(vs_Pos.x, height, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
}
