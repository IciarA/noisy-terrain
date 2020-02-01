#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_Tone;
uniform bool u_Night;

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_dist;
in vec2 fs_point;

in vec2 fs_p;
in float fs_test;
in float fs_colM1;
in float fs_colM2;
in float fs_tval;
in float fs_ry;


out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


// get f(y) for straitaions but add noise to y before using f(y) 

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


vec3 mountCol(float ry) {

    vec2 p = vec2(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y);

    if (ry < 0.1) { // Ground sand
        vec3 color = vec3(0.7 * ((fs_test + 1.0)), 0.6 * ((fs_test + 1.0)), 0.5 * ((fs_test + 1.0)));
        vec3 color2 = vec3(0.7 * ((rand(p) + 1.0)), 0.6 * ((rand(p) + 1.0)), 0.5 * ((rand(p) + 1.0)));

        vec3 color3 = mix(color, color2, 0.5);

        return color3;
    }
    else if (ry >= 0.1 && ry <= 0.3) { // Ground sand mix
        vec3 color = vec3(0.7 * ((fs_test + 1.0)), 0.6 * ((fs_test + 1.0)), 0.5 * ((fs_test + 1.0)));
        vec3 color2 = vec3(0.7 * ((rand(p) + 1.0)), 0.6 * ((rand(p) + 1.0)), 0.5 * ((rand(p) + 1.0)));

        vec3 color3 = mix(color, color2, 0.25);

        vec3 color4 = vec3(0.6 * ((fs_colM1 + 1.0)), 0.547 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));

        float tempT = (fs_Pos.y - 0.1) * 2.5;
        
        vec3 color5 = mix(color3, color4, tempT);

        return color5;
    }
    else if (ry <= 0.4) { // transition
        vec3 color = vec3(0.7 * ((fs_test + 1.0)), 0.6 * ((fs_test + 1.0)), 0.5 * ((fs_test + 1.0)));
        vec3 color2 = vec3(0.7 * ((rand(p) + 1.0)), 0.6 * ((rand(p) + 1.0)), 0.5 * ((rand(p) + 1.0)));
        vec3 color3 = mix(color, color2, 0.25);
        
        vec3 color4 = vec3(0.6 * ((fs_colM1 + 1.0)), 0.547 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));

        float tempT = (fs_Pos.y - 0.1) * 2.5;
        vec3 color5 = mix(color3, color4, tempT);


        vec3 color6 = vec3(0.5 * ((fs_colM1 + 1.0)), 0.447 * ((fs_colM1 + 1.0)), 0.35 * ((fs_colM1 + 1.0)));
        tempT = (ry - 0.3) * 10.0;
        vec3 color7 = mix(color5, color6, tempT);

        return color7;
    }
    else if (ry < 0.6) { //Mountain 1
        vec3 color = vec3(0.5 * ((fs_colM1 + 1.0)), 0.447 * ((fs_colM1 + 1.0)), 0.35 * ((fs_colM1 + 1.0)));

        return color;
    }
    else if (ry <= 0.65) { //transition
        vec3 color = vec3(0.5 * ((fs_colM1 + 1.0)), 0.447 * ((fs_colM1 + 1.0)), 0.35 * ((fs_colM1 + 1.0)));

        vec3 color2 = vec3(0.7 * ((fs_colM1 + 1.0)), 0.52 * ((fs_colM1 + 1.0)), 0.34 * ((fs_colM1 + 1.0)));
        color2 *= .85;
        
        float tempT = (ry - 0.6) * 20.0;
        vec3 color3 = mix(color, color2, tempT);

        return color3;
    }
    else if (ry < 0.8) { //mountain 2
        vec3 color = vec3(0.7 * ((fs_colM1 + 1.0)), 0.52 * ((fs_colM1 + 1.0)), 0.34 * ((fs_colM1 + 1.0)));
        vec3 color2 = vec3(fbm3(fs_p) * ry, fs_colM2 * ry, fs_colM2 * ry);
        vec3 color3 = mix(color, color2, .25);
        
        color = color * 0.85;

        return color;
    }
    else if (ry <= 0.85) { // transition
        vec3 color = vec3(0.7 * ((fs_colM1 + 1.0)), 0.52 * ((fs_colM1 + 1.0)), 0.34 * ((fs_colM1 + 1.0)));
        color *= .85;

        vec3 color2 = vec3(0.5 * ((fs_colM1 + 1.0)), 0.3 * ((fs_colM1 + 1.0)), 0.2 * ((fs_colM1 + 1.0)));
        vec3 color3 = color2 * (ry + 0.3);

        float tempT = (ry - 0.8) * 20.0;
        vec3 color4 = mix(color, color3, tempT);

        return color4;
    }
    else if (ry < 1.3) { //mountain 3
        vec3 color = vec3(0.5 * ((fs_colM1 + 1.0)), 0.3 * ((fs_colM1 + 1.0)), 0.2 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (ry + 0.3);
        
        return color2;
    }
    else if (ry <= 1.4) { //transition
        vec3 color = vec3(0.5 * ((fs_colM1 + 1.0)), 0.3 * ((fs_colM1 + 1.0)), 0.2 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (ry + 0.3);

        vec3 color3 = vec3(0.6 * ((fs_colM1 + 1.0)), 0.55 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color4 = color3 * (1.0 / (pow(ry, 2.9) / 3.1));

        float tempT = (ry - 1.3) * 10.0;
        vec3 color5 = mix(color2, color4, tempT);

        return color5;
    }
    else if (ry < 1.8) { //mountain 4
        vec3 color = vec3(0.6 * ((fs_colM1 + 1.0)), 0.55 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (1.0 / (pow(ry, 2.9) / 3.1));
        
        return color2;
    }
    else if (ry <= 1.9) { //transition
        vec3 color = vec3(0.6 * ((fs_colM1 + 1.0)), 0.55 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (1.0 / (pow(ry, 2.9) / 3.1));

        vec3 color3 = vec3(0.65 * ((fs_colM1 + 1.0)), 0.6 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color4 = color3 * (pow(ry, 2.0) / 4.7);

        float tempT = (ry - 1.8) * 10.0;
        vec3 color5 = mix(color2, color4, tempT);

        return color5;
    }
    else if (ry <= 2.3){ //mountain 5
        vec3 color = vec3(0.65 * ((fs_colM1 + 1.0)), 0.6 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (pow(ry, 2.0) / 4.7);
        
        return color2;
    }
    else if (ry <= 2.4) { // transition
        vec3 color = vec3(0.65 * ((fs_colM1 + 1.0)), 0.6 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (pow(ry, 2.0) / 4.7);

        vec3 color3 = vec3(0.63 * ((fs_test + 1.0)), 0.55 * ((fs_test + 1.0)), 0.45 * ((fs_test + 1.0)));

        float tempT = (ry - 2.3) * 10.0;
        vec3 color4 = mix(color2, color3, tempT);

        return color4;
    }
    else { //mountain 6
        vec3 color = vec3(0.63 * ((fs_test + 1.0)), 0.55 * ((fs_test + 1.0)), 0.45 * ((fs_test + 1.0)));
        
        return color;
    }

}



vec3 plainCol(float ry) {
    vec2 p = vec2(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y);

    if (ry < 0.1) { // Ground sand
        vec3 color = vec3(0.7 * ((fs_test + 1.0)), 0.6 * ((fs_test + 1.0)), 0.5 * ((fs_test + 1.0)));
        vec3 color2 = vec3(0.7 * ((rand(p) + 1.0)), 0.6 * ((rand(p) + 1.0)), 0.5 * ((rand(p) + 1.0)));

        vec3 color3 = mix(color, color2, 0.5);

        return color3;
    }
    else if (ry >= 0.1 && ry <= 0.3) { // Ground sand mix
        vec3 color = vec3(0.7 * ((fs_test + 1.0)), 0.6 * ((fs_test + 1.0)), 0.5 * ((fs_test + 1.0)));
        vec3 color2 = vec3(0.7 * ((rand(p) + 1.0)), 0.6 * ((rand(p) + 1.0)), 0.5 * ((rand(p) + 1.0)));

        vec3 color3 = mix(color, color2, 0.25);

        vec3 color4 = vec3(0.6 * ((fs_colM1 + 1.0)), 0.547 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));

        float tempT = (fs_Pos.y - 0.1) * 2.5;
        
        vec3 color5 = mix(color3, color4, tempT);

        return color5;
    }
    else if (ry <= 0.4) { // transition
        vec3 color = vec3(0.7 * ((fs_test + 1.0)), 0.6 * ((fs_test + 1.0)), 0.5 * ((fs_test + 1.0)));
        vec3 color2 = vec3(0.7 * ((rand(p) + 1.0)), 0.6 * ((rand(p) + 1.0)), 0.5 * ((rand(p) + 1.0)));
        vec3 color3 = mix(color, color2, 0.25);
        
        vec3 color4 = vec3(0.6 * ((fs_colM1 + 1.0)), 0.547 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));

        float tempT = (fs_Pos.y - 0.1) * 2.5;
        vec3 color5 = mix(color3, color4, tempT);


        vec3 color6 = vec3(0.5 * ((fs_colM1 + 1.0)), 0.447 * ((fs_colM1 + 1.0)), 0.35 * ((fs_colM1 + 1.0)));
        tempT = (ry - 0.3) * 10.0;
        vec3 color7 = mix(color5, color6, tempT);

        return color7;
    }
    else if (ry < 0.6) { //Grass
        vec3 color = vec3(0.3 * ((fs_colM1 + 1.0)), 0.3 * ((fs_colM1 + 1.0)), 0.0 * ((fs_colM1 + 1.0)));

        return color;
    }
    else if (ry <= 0.65) { //transition
        vec3 color = vec3(0.5 * ((fs_colM1 + 1.0)), 0.447 * ((fs_colM1 + 1.0)), 0.35 * ((fs_colM1 + 1.0)));

        vec3 color2 = vec3(0.7 * ((fs_colM1 + 1.0)), 0.52 * ((fs_colM1 + 1.0)), 0.34 * ((fs_colM1 + 1.0)));
        color2 = color2 * 0.85;
        
        float tempT = (ry - 0.6) * 20.0;
        vec3 color3 = mix(color, color2, tempT);

        return color3;

    }
    else if (ry < 0.8) { //mountain 2
        vec3 color = vec3(0.7 * ((fs_colM1 + 1.0)), 0.52 * ((fs_colM1 + 1.0)), 0.34 * ((fs_colM1 + 1.0)));
        vec3 color2 = vec3(fbm3(fs_p) * ry, fs_colM2 * ry, fs_colM2 * ry);
        vec3 color3 = mix(color, color2, .25);
        
        color = color * 0.85;

        return color;
    }
    else if (ry <= 0.85) { // transition
        vec3 color = vec3(0.7 * ((fs_colM1 + 1.0)), 0.52 * ((fs_colM1 + 1.0)), 0.34 * ((fs_colM1 + 1.0)));
        color *= .85;

        vec3 color2 = vec3(0.5 * ((fs_colM1 + 1.0)), 0.3 * ((fs_colM1 + 1.0)), 0.2 * ((fs_colM1 + 1.0)));
        vec3 color3 = color2 * (ry + 0.3);

        float tempT = (ry - 0.8) * 20.0;
        vec3 color4 = mix(color, color3, tempT);

        return color4;
    }
    else if (ry < 1.3) { //mountain 3
        vec3 color = vec3(0.5 * ((fs_colM1 + 1.0)), 0.3 * ((fs_colM1 + 1.0)), 0.2 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (ry + 0.3);
        
        return color2;
    }
    else if (ry <= 1.4) { //transition
        vec3 color = vec3(0.5 * ((fs_colM1 + 1.0)), 0.3 * ((fs_colM1 + 1.0)), 0.2 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (ry + 0.3);

        vec3 color3 = vec3(0.6 * ((fs_colM1 + 1.0)), 0.55 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color4 = color3 * (1.0 / (pow(ry, 2.9) / 3.1));

        float tempT = (ry - 1.3) * 10.0;
        vec3 color5 = mix(color2, color4, tempT);

        return color5;
    }
    else if (ry < 1.8) { //mountain 4
        vec3 color = vec3(0.6 * ((fs_colM1 + 1.0)), 0.55 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (1.0 / (pow(ry, 2.9) / 3.1));
        
        return color2;
    }
    else if (ry <= 1.9) { //transition
        vec3 color = vec3(0.6 * ((fs_colM1 + 1.0)), 0.55 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (1.0 / (pow(ry, 2.9) / 3.1));

        vec3 color3 = vec3(0.65 * ((fs_colM1 + 1.0)), 0.6 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color4 = color3 * (pow(ry, 2.0) / 4.7);

        float tempT = (ry - 1.8) * 10.0;
        vec3 color5 = mix(color2, color4, tempT);

        return color5;
    }
    else if (ry <= 2.3){ //mountain 5
        vec3 color = vec3(0.65 * ((fs_colM1 + 1.0)), 0.6 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (pow(ry, 2.0) / 4.7);
        
        return color2;
    }
    else if (ry <= 2.4) { // transition
        vec3 color = vec3(0.65 * ((fs_colM1 + 1.0)), 0.6 * ((fs_colM1 + 1.0)), 0.45 * ((fs_colM1 + 1.0)));
        vec3 color2 = color * (pow(ry, 2.0) / 4.7);

        vec3 color3 = vec3(0.63 * ((fs_test + 1.0)), 0.55 * ((fs_test + 1.0)), 0.45 * ((fs_test + 1.0)));

        float tempT = (ry - 2.3) * 10.0;
        vec3 color4 = mix(color2, color3, tempT);

        return color4;
    }
    else { //mountain 6
        vec3 color = vec3(0.63 * ((fs_test + 1.0)), 0.55 * ((fs_test + 1.0)), 0.45 * ((fs_test + 1.0)));
        
        return color;
    }
}



void main()
{
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog

    vec2 p = vec2(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y);
    vec2 q = vec2( fbm3( p ), fbm3( vec2(p.x + 5.2, p.y + 1.3) ) );
    vec2 test_p = p + 4.0 * q;
    float test = fbm3( test_p );

    float ry = fs_ry;

    if (fs_tval < 0.5) {
        vec3 col = mountCol(ry);
        col = (0.7 * col) + (0.3 * vec3(0.8, 0.7, 0.5));// / (pow(ry, 3.0));
        col *= u_Tone;
        

        if (u_Night) {

            vec3 white = (rand(vec2(fs_Pos.x, fs_Pos.z))) * vec3(1.0, 1.0, 1.0) + (1.0 - rand(vec2(fs_Pos.x, fs_Pos.z))) * vec3(0.7, 0.7, 0.0);
            vec3 sky = vec3(164.0 / 255.0, 233.0 / 255.0, 1.0);
            vec3 night_sky = vec3(0.0, 0.0, 0.0);

            vec3 col2 = mix(night_sky, white, clamp(rand(vec2(fs_Pos.x, fs_Pos.z)) - 0.5, 0.0, 1.0));

            out_Col = vec4(mix(col, night_sky, t), 1.0);
        }
        else {
            vec3 sky = vec3(164.0 / 255.0, 233.0 / 255.0, 1.0);
            vec3 col2 = mix(sky, vec3(1.0, 1.0, 1.0), noised(vec2(fs_Pos.x, fs_Pos.z) / 15.0));

            out_Col = vec4(mix(col, col2, t), 1.0);
        }
    }

    else if (fs_tval <= 0.55) {
        vec3 mcol = mountCol(ry);
        mcol = (0.7 * mcol) + (0.3 * vec3(0.8, 0.7, 0.5));// / (pow(ry, 3.0));

        vec3 pcol = plainCol(ry);
        pcol = (0.7 * pcol)+ (0.3 * vec3(0.8, 0.7, 0.5));
        
        float tempT = smoothstep(0.6, 0.9, (fs_tval - 0.5) * 20.0);
        vec3 col = mix(mcol, pcol, tempT);
        col *= u_Tone;

        if (u_Night) { 
 
            vec3 white = (rand(vec2(fs_Pos.x, fs_Pos.z))) * vec3(1.0, 1.0, 1.0) + (1.0 - rand(vec2(fs_Pos.x, fs_Pos.z))) * vec3(0.7, 0.7, 0.0);
            vec3 sky = vec3(164.0 / 255.0, 233.0 / 255.0, 1.0);
            vec3 night_sky = vec3(0.0, 0.0, 0.0);

            vec3 col2 = mix(night_sky, white, clamp(rand(vec2(fs_Pos.x, fs_Pos.z)) - 0.5, 0.0, 1.0));

            out_Col = vec4(mix(col, night_sky, t), 1.0);
        }
        else {
            vec3 sky = vec3(164.0 / 255.0, 233.0 / 255.0, 1.0);
            vec3 col2 = mix(sky, vec3(1.0, 1.0, 1.0), noised(vec2(fs_Pos.x, fs_Pos.z) / 15.0));

            out_Col = vec4(mix(col, col2, t), 1.0);
        }
    }


    else {
        vec3 col = plainCol(ry);
        col = ((0.7 * col) + (0.3 * vec3(0.8, 0.7, 0.5)));

        col *= u_Tone;

        if (u_Night) {

            vec3 white = (rand(vec2(fs_Pos.x, fs_Pos.z))) * vec3(1.0, 1.0, 1.0) + (1.0 - rand(vec2(fs_Pos.x, fs_Pos.z))) * vec3(0.7, 0.7, 0.0);
            vec3 sky = vec3(164.0 / 255.0, 233.0 / 255.0, 1.0);
            vec3 night_sky = vec3(0.0, 0.0, 0.0);

            vec3 col2 = mix(night_sky, white, clamp(rand(vec2(fs_Pos.x, fs_Pos.z)) - 0.5, 0.0, 1.0));

            out_Col = vec4(mix(col, night_sky, t), 1.0);
        }
        else {
            vec3 sky = vec3(164.0 / 255.0, 233.0 / 255.0, 1.0);
            vec3 col2 = mix(sky, vec3(1.0, 1.0, 1.0), noised(vec2(fs_Pos.x, fs_Pos.z) / 15.0));

            out_Col = vec4(mix(col, col2, t), 1.0);
        }
    }
}
