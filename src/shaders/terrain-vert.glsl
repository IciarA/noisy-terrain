#version 300 es

// Perlin noise broad - absolute value, clmaped 
// Perlin noise [-1, 1] - absolute value so -1 is 1 now, clamp absoute value to get valleys and multiply with fbm
// Adjust with smoothstep
// Smoothstep creates transition ()
// Can also use sin functions

// 2 noise functions - one for mountains and one for 

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;

out float fs_dist;
out vec2 fs_point;


// What is the seed value for?
// Erosion - loop through all the 9 grids? How do we now the size of the grids?
// How to make it smoother so there are no clear lines caused by worley

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

float fbm2(vec2 x, float H )
{    
    float G = pow(2.f, -H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    int numOctaves = 8;
    for( int i=0; i<numOctaves; i++ )
    {
        t += a*rand(f*x);
        f *= 2.0;
        a *= G;
    }
    return t;
}



// Perlin noise 
float fade(float t) {
  return t*t*t*(t*(t*6.0 - 15.0) + 10.0);
}


void main()
{
  // The dimensions of the cell division, based on the dimensions of the screen.
  float m = 0.1f;
  float n = 0.1f;

  // The cell where the current point is
  vec2 p = vec2(floor((vs_Pos.x + u_PlanePos.x) * m), floor((vs_Pos.z + u_PlanePos.y) * n));
  // The random point within that cell
  vec2 rand = p + random(p);

  // Variables to keep track of the closest random point to the current point and their distance
  vec2 final_point = rand;
  vec2 curr_rand = rand;
  float dist = 999999.00;
  float dist2 = 999999.00;
  float dist3 = 999999.00;

  float result = 0.f;

  // Loops that iterates through all the adjacent cells to the current point to find the closest of the
  // random points.
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
  //result = pow(result, 2.f);
  //vec2 worley = vec2(final_point[0] / m, final_point[1] / n)


  p = vec2(vs_Pos.x + u_PlanePos.x, vs_Pos.z + u_PlanePos.y);
  vec2 q = vec2( fbm3( p ), fbm3( vec2(p.x + 5.2, p.y + 1.3) ) );
  vec2 test_p = p + 4.0 * q;
  float test = fbm3( test_p );


  float final_result = pow(mix(result, fbm3(p), 0.3f), 4.f) * 5.f;

  //vec2 p2 = vec2(final_result, final_result);
  //vec2 q2 = vec2( fbm3( p + vec2(0.0,0.0) ), fbm3( p + vec2(5.2,1.3) ) );
  //vec2 r = vec2( fbm3( p + 4.0 * q2 + vec2(1.7,9.2) ), fbm3( p + 4.0 * q2 + vec2(8.3,2.8) ) );
  //float final_result2 = pow(mix(result, fbm3( p + 4.0 * r ), 0.3f), 4.f);
  
  
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {

    }
  }
  
  
  
  //fs_Pos = vs_Pos.xyz;
  fs_Pos.x = vs_Pos.x;
  fs_Pos.y = final_result;
  fs_Pos.z = vs_Pos.z;
  fs_Sine = (sin((vs_Pos.x + u_PlanePos.x) * 3.14159 * 0.1) + cos((vs_Pos.z + u_PlanePos.y) * 3.14159 * 0.1));
  //vec4 modelposition = vec4(vs_Pos.x, fs_Sine * 2.0, vs_Pos.z, 1.0);
  //vec4 modelposition = vec4(vs_Pos.x, pow(fbm3(p), 3.f) * 2.f, vs_Pos.z, 1.0);
  vec4 modelposition = vec4(vs_Pos.x, final_result, vs_Pos.z, 1.0);
  //vec4 modelposition = vec4(vs_Pos.x, result, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
}
