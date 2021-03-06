typedef struct {
    float3 o;
    float3 d;
} ray;

ray calc_ray(float2 uv, float time) {
    ray r;
    r.o = (float3)(-3.0, 0.0, 0.0);
    //r.o = (float3)(time * 5, time * 5, -3.0);
    r.d = normalize((float3)(1.0, uv));

    return r;
}

float sphere_de(float3 pos, float time) {
    pos = copysign(fmod(pos, 4.0) - 2.0, pos);
    return length(pos) - 0.5;
}

float mandelbulb_de(float3 pos, float time) {
    // pos = fmod(fabs(pos), 4.0) - 2.0;
    float3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    int Iterations = 4;
    float Bailout = 4.0;
    float Power = 8.0;
    for (int i = 0; i < Iterations; i++) {
        r = length(z);
        if (r>Bailout) break;

        // convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan2(z.y, z.x);
        dr = pow(r, Power - 1.0)*Power*dr + 1.0;

        // scale and rotate the point
        float zr = pow(r, Power);
        theta = theta*Power;
        phi = phi*Power;

        // convert back to cartesian coordinates
        z = zr*(float3)(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z += pos;
        //z += pos * cos(time * 2.0);
    }
    return 0.5*log(r)*r / dr;
}

float march(ray r, float time) {
    float total_dist = 0.0;
    int steps;
    int max_ray_steps = 64;
    float min_distance = 0.002;
    for (steps = 0; steps < max_ray_steps; ++steps) {
        float3 p = r.o + total_dist * r.d;
        float distance = mandelbulb_de(p, time);
        total_dist += distance;
        if (distance < min_distance) break;
    }

    return 1.0 - (float)steps / (float)max_ray_steps;
}

float3 shade(float2 uv, float time) {
    ray r = calc_ray(uv, time);
    float i = march(r, time);
    return (float3)(i, i, i);
}

void kernel start(
    global int* screen_buffer,
    constant const int* width,
    constant const int* height,
    constant float* time
) {
    float2 pos = { get_global_id(0), get_global_id(1) };
    //float2 pos = (float2)(pixel_id % *width, pixel_id / *width);

    float ar = (float)*width / (float)*height;
    float2 uv = pos / min(*width, *height) - (float2)(ar * 0.5, 0.5);

    float3 fcolor = 255 - shade(uv, *time) * 255;
    int icolor = ((int) fcolor.z << 16) + ((int) fcolor.y << 8) + (int) fcolor.x;
    screen_buffer[(int)(pos.y * *width + pos.x)] = icolor;
}
