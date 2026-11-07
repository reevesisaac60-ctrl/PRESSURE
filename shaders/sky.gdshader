shader_type sky;

uniform sampler2D cloud_base : repeat_enable, filter_linear;
uniform sampler2D cloud_detail : repeat_enable, filter_linear;
uniform sampler2D cloud_distortion : repeat_enable, filter_linear;

uniform vec3 sky_top : source_color = vec3(0.025, 0.055, 0.24);
uniform vec3 sky_horizon : source_color = vec3(0.12, 0.32, 0.65);

uniform vec3 cloud_dark : source_color = vec3(0.12, 0.055, 0.32);
uniform vec3 cloud_mid : source_color = vec3(0.12, 0.48, 0.85);
uniform vec3 cloud_bright : source_color = vec3(0.95, 0.20, 0.65);
uniform vec3 cloud_highlight : source_color = vec3(1.0, 0.65, 0.32);

uniform float cloud_scale = 0.5;
uniform float detail_scale = 1.1;
uniform float distortion_strength = 0.22;

uniform float cloud_coverage = 0.43;
uniform float cloud_sharpness = 0.10;
uniform float cloud_speed = 0.018;
uniform float cloud_intensity = 1.0;

uniform float horizon_glow = 0.35;
uniform float plane_height = 0.15;

void sky() {
    vec3 direction = normalize(EYEDIR);

    vec2 plane_uv = direction.xz / (max(direction.y, 0.0) + plane_height);

    float height = smoothstep(-0.2, 0.85, direction.y);
    vec3 color = mix(sky_horizon, sky_top, height);

    float time = TIME * cloud_speed;
    vec2 base_uv = plane_uv * cloud_scale;

    float distortion_x = texture(
        cloud_distortion,
        base_uv * 0.65 + vec2(time, 0.0)
    ).r;

    float distortion_y = texture(
        cloud_distortion,
        base_uv * 0.65 + vec2(0.0, -time * 0.8)
    ).r;

    vec2 distortion = vec2(
        distortion_x - 0.5,
        distortion_y - 0.5
    );

    vec2 layer_a_uv = base_uv + distortion * distortion_strength;
    layer_a_uv += vec2(time, time * 0.2);

    vec2 layer_b_uv = base_uv * 1.7 - distortion * 0.5;
    layer_b_uv += vec2(-time * 0.7, time * 0.35);

    float layer_a = texture(cloud_base, layer_a_uv).r;
    float layer_b = texture(cloud_detail, layer_b_uv).r;

    float detail = texture(
        cloud_detail,
        base_uv * detail_scale / cloud_scale +
        vec2(time * 0.4, -time * 0.25)
    ).r;

    // Combine the cloud layers.
    float cloud_noise = layer_a * 0.68 + layer_b * 0.32;
    cloud_noise += (detail - 0.5) * 0.16;

    float cloud_mask = smoothstep(
        cloud_coverage,
        cloud_coverage + cloud_sharpness,
        cloud_noise
    );

    vec3 cloud_color = mix(
        cloud_dark,
        cloud_mid,
        smoothstep(0.25, 0.58, cloud_noise)
    );

    cloud_color = mix(
        cloud_color,
        cloud_bright,
        smoothstep(0.52, 0.76, detail)
    );

    cloud_color = mix(
        cloud_color,
        cloud_highlight,
        smoothstep(0.72, 0.92, cloud_noise)
    );

    float cloud_light = smoothstep(0.35, 0.85, detail);
    cloud_color *= mix(0.65, 1.2, cloud_light);

    float sky_mask = smoothstep(0.0, 0.3, direction.y);
    cloud_mask *= sky_mask;

    color = mix(
        color,
        cloud_color * cloud_intensity,
        cloud_mask
    );

    float glow = exp(-abs(direction.y) * 7.0) * horizon_glow;
    color += vec3(0.22, 0.08, 0.28) * glow;

    COLOR = color;
}