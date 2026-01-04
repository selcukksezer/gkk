shader_type canvas_item;

uniform vec4 top_color : hint_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform vec4 mid_color : hint_color = vec4(1.0, 0.45, 0.05, 1.0);
uniform vec4 bottom_color : hint_color = vec4(0.1, 0.02, 0.0, 0.0);
uniform float speed : hint_range(0.1, 6.0) = 1.8;
uniform float scale : hint_range(0.5, 3.0) = 1.6;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

// Simple hash / noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f*f*(3.0-2.0*f);
    float a = hash(i + vec2(0.0,0.0));
    float b = hash(i + vec2(1.0,0.0));
    float c = hash(i + vec2(0.0,1.0));
    float d = hash(i + vec2(1.0,1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        v += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV * vec2(scale, scale);
    // Move flames upward and animate
    float t = TIME * speed;
    float n = fbm(vec2(uv.x * 1.2, uv.y * 2.2 - t));
    // create vertical falloff so flames concentrate near bottom
    float falloff = smoothstep(0.0, 1.0, 1.0 - uv.y);
    float shape = smoothstep(0.2, 0.85, n + (1.0 - uv.y) * 1.2);
    // Add ripples
    float ripple = sin((uv.x + t * 0.5) * 10.0) * 0.05;
    float mask = clamp(shape + ripple * 0.6, 0.0, 1.0) * falloff;

    vec3 col = mix(bottom_color.rgb, mid_color.rgb, saturate(n * 1.5));
    col = mix(col, top_color.rgb, pow(falloff, 1.5));
    float alpha = mask * intensity;

    COLOR = vec4(col * alpha, alpha);
}

// Helper for older GLSL compatibility
float saturate(float v) { return clamp(v, 0.0, 1.0); }
