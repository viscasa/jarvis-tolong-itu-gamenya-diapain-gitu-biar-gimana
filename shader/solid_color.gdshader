shader_type canvas_item;

uniform vec4 custom_color : source_color; // Cor sólida que será usada

varying vec4 v_modulate;

void vertex() {
    v_modulate = COLOR; // Captura a cor do Sprite2D.modulate
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Se o pixel da textura original for completamente transparente, descarta
    if (tex.a <= 0.0) {
        discard;
    }

    // Aplica a cor sólida, mas usa apenas o alpha do modulate
    COLOR = vec4(custom_color.rgb, custom_color.a * v_modulate.a);
}
