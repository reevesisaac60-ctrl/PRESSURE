shader_type canvas_item;

uniform sampler2D screen_texture :
    hint_screen_texture,
    repeat_disable,
    filter_nearest;

uniform float pixel_size : hint_range(1.0, 12.0) = 3.0;

void fragment() {
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;

    vec2 pixel_count = screen_size / pixel_size;

    vec2 pixel_uv = (
        floor(SCREEN_UV * pixel_count) + 0.5
    ) / pixel_count;

    COLOR = textureLod(screen_texture, pixel_uv, 0.0);
}
