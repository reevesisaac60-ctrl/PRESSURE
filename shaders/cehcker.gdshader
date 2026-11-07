
shader_type spatial;

uniform vec4 color_a : source_color = vec4(0.025, 0.025, 0.025, 1.0);
uniform vec4 color_b : source_color = vec4(0.95, 0.95, 0.95, 1.0);

uniform vec2 checker_scale = vec2(12.0, 12.0);
uniform vec2 scroll_speed = vec2(0.35, 0.15);

uniform float roughness = 0.65;

void fragment() {
    vec2 uv = UV * checker_scale + TIME * scroll_speed;

    vec2 cell = floor(uv);

    float pattern = mod(cell.x + cell.y, 2.0);

    ALBEDO = mix(color_a.rgb, color_b.rgb, pattern);
    ROUGHNESS = roughness;
}
