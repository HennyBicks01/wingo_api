shader_type canvas_item;
uniform vec4 grid_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec4 background_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float line_thickness : hint_range(0.0, 0.1) = 0.02;
uniform float grid_size : hint_range(10.0, 100.0) = 50.0;
uniform float scroll_speed : hint_range(-2.0, 2.0) = 0.2;

void fragment() {
   // Create scrolling effect
   vec2 shifted_uv = UV;
   shifted_uv.y += TIME * scroll_speed;
   
   // Calculate grid
   vec2 grid = fract(shifted_uv * grid_size);
   
   // Create lines
   float lines = 0.0;
   lines += smoothstep(0.0, line_thickness, grid.x) - smoothstep(1.0 - line_thickness, 1.0, grid.x);
   lines += smoothstep(0.0, line_thickness, grid.y) - smoothstep(1.0 - line_thickness, 1.0, grid.y);
   
   // Mix colors
   COLOR = mix(background_color, grid_color, lines);
}