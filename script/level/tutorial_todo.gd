extends VBoxContainer

# Drag file font (ExtResource("2_n7h5c")) ke sini lewat Inspector
@export var custom_font: Font
# Ukuran font default
@export var font_size: int = 22
# Jarak animasi "slide" dari bawah (pixel)
@export var slide_distance: float = 20.0

func _ready():
	# --- CONTOH PENGGUNAAN (Bisa dihapus nanti) ---
	# Menambahkan item saat game mulai untuk testing
	await get_tree().create_timer(0.5).timeout
	add_checklist_item("Left click / Space to dash")
	
	await get_tree().create_timer(0.3).timeout
	add_checklist_item("Left click when circle is perfect")
	
	await get_tree().create_timer(0.3).timeout
	add_checklist_item("Right click to Super Dash")


# Fungsi untuk menambahkan item baru ke dalam VBox
func add_checklist_item(text_content: String):
	# 1. MEMBUAT NODE
	var hbox = HBoxContainer.new()
	var checkbox = CheckBox.new()
	var label = Label.new()
	
	# 2. SETUP CHECKBOX
	checkbox.focus_mode = Control.FOCUS_NONE # Agar tidak ada outline fokus
	checkbox.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# 3. SETUP LABEL
	label.text = text_content
	label.z_index = 1 # Sesuai setup Anda
	
	# Mengatur Font jika ada yang dimasukkan di Inspector
	if custom_font:
		label.add_theme_font_override("font", custom_font)
	
	label.add_theme_font_size_override("font_size", font_size)
	
	# 4. MENYUSUN NODE (Memasukkan ke Tree)
	hbox.add_child(checkbox)
	hbox.add_child(label)
	
	# Kita tambahkan ke VBox ini
	add_child(hbox)
	
	# 5. ANIMASI FADE-IN DARI BAWAH
	# Karena VBoxContainer memaksa posisi child, kita tidak bisa meng-animasikan 'position' secara langsung dengan mudah.
	# Triknya: Kita gunakan 'modulate' (transparansi) dan 'constant_separation' manipulasi atau Tween sederhana.
	
	# Set kondisi awal: Transparan
	hbox.modulate.a = 0.0
	
	# Membuat Tween
	var tween = create_tween()
	tween.set_parallel(true) # Jalankan animasi secara bersamaan
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animasi 1: Fade In (Alpha 0 -> 1)
	tween.tween_property(hbox, "modulate:a", 1.0, 0.5)
	
	# Trik Animasi 2: Slide dari bawah (Simulasi)
	# Karena VBox mengunci posisi, kita bisa memanipulasi transform grafisnya saja tanpa merusak layout
	# Kita geser node sedikit ke bawah, lalu kembalikan ke posisi 0
	label.position.y += slide_distance 
	checkbox.position.y += slide_distance 
	tween.tween_property(label, "position:y", label.position.y - slide_distance, 0.5)
	tween.tween_property(checkbox, "position:y", checkbox.position.y - slide_distance, 0.5)
	
	# Catatan: Jika animasi posisi terasa glitchy karena layout update, 
	# cukup gunakan animasi modulate saja, itu sudah terlihat bagus.
