extends CanvasLayer
class_name PlayerUI

## 1. HUBUNGKAN NODE PLAYER ANDA DI SINI
@export var player: Player

# --- Referensi Node dari Scene Tree Anda ---
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var dash: TextureProgressBar = $Dash

# --- Ikon Skill (sesuai nama dari prompt Anda) ---
@onready var icon_puppet_shooter: Sprite2D = $IconPuppetShooter
@onready var icon_wolf: Sprite2D = $IconWolf
@onready var icon_puppet_shooter_2: Sprite2D = $IconPuppetShooter2
@onready var icon_puppet: Sprite2D = $IconPuppet

# --- Indikator Skill Khusus ---
@onready var super_dash_indicator: AnimatedSprite2D = $SuperDashIndicator
@onready var pin_label: Label = $PinLabel

# --- Variabel Internal ---
var health_manager: HealthManager
var dash_manager: DashManager
var skill_manager: SkillManager
var super_dash: SuperDash # <-- BARU
var pin: Pin # <-- BARU

# Dictionary untuk memetakan nama skill ke node ikonnya
var skill_icons: Dictionary = {}
# Dictionary untuk menyimpan posisi Y asli ikon untuk tween
var skill_icon_original_pos_y: Dictionary = {}
# Untuk melacak skill mana yang aktif (DIHAPUS)
# var last_active_skill_name := "none" (DIHAPUS)
# Ketinggian lompatan animasi tween (dalam piksel)
const SKILL_ICON_JUMP_HEIGHT = -20.0 


func _ready():
	# 1. Validasi Node Player
	if not player:
		print("ERROR di PlayerUI: Node 'player' belum di-set di Inspector!")
		set_process(false) # Matikan skrip ini jika player tidak ada
		return
		
	# 2. Ambil referensi ke manajer
	health_manager = player.health_manager
	dash_manager = player.dash_manager
	skill_manager = player.skill_manager
	super_dash = player.super_dash # <-- BARU
	pin = player.pin # <-- BARU

	# 3. Setup koneksi sinyal (Hanya untuk health)
	if health_manager:
		health_manager.health_changed.connect(_on_health_changed)
		# Set nilai awal health bar
		_on_health_changed(health_manager.current_health, health_manager.max_health)
	
	# 4. Setup koneksi sinyal untuk skill (kapan skill dipakai)
	if skill_manager:
		skill_manager.stolen_skill_used.connect(_on_stolen_skill_used)
		
	# 5. Setup koneksi sinyal untuk Pin
	if pin:
		pin.pin_count_changed.connect(_on_pin_count_changed)
		# Set nilai awal pin label
		_on_pin_count_changed(pin.current_pins, pin.max_pins)
	
	# 6. Setup ikon-ikon skill
	_setup_morph_icons()
	
	# 7. Set frame awal super dash
	if super_dash_indicator:
		super_dash_indicator.frame = 0 # Mulai dari frame 0


func _process(_delta):
	# Kita harus cek cooldown dash & skill aktif setiap frame (polling)
	if dash_manager:
		_update_dash_bar()
	
	if skill_manager:
		_update_morph_skill_icons()

	if super_dash: # <-- BARU
		_update_super_dash_indicator()

# --- 1. LOGIKA HEALTH BAR ---

func _on_health_changed(current: float, max: float):
	if health_bar:
		health_bar.max_value = max
		health_bar.value = current

# --- 2. LOGIKA DASH BAR (DIMODIFIKASI) ---

func _update_dash_bar():
	if not dash:
		return

	# --- MODIFIKASI: Prioritaskan Weak Exit Cooldown ---
	# Cek dulu apakah kita sedang dalam 'lock' dari weak exit
	if dash_manager.weak_exit_lock_timer > 0.0:
		# Ambil konstanta total waktu dari dash_manager
		var cooldown_total = dash_manager.WEAK_EXIT_LOCK_TIME
		var cooldown_left = dash_manager.weak_exit_lock_timer
		# Hitung progres (0.0 -> 1.0)
		var progress = (cooldown_total - cooldown_left) / cooldown_total 
		dash.value = progress * dash.max_value
		
		# Set bar jadi merah untuk indikator "locked" (Opsional)
		dash.tint_progress = Color.RED
	
	# --- Cek Cooldown Dash Biasa ---
	# (Hanya jika tidak sedang weak exit lock)
	else:
		# Set bar kembali normal (Opsional)
		dash.tint_progress = Color.WHITE
		
		var max_charges = dash_manager.dash_count_max
		var current_charges = max_charges - dash_manager.dash_counter

		if current_charges == max_charges:
			# Jika charge penuh, bar penuh
			dash.value = dash.max_value
		elif dash_manager.cooldown_timer > 0.0:
			# Jika sedang cooldown, hitung progres
			var cooldown_total = dash_manager.COOLDOWN
			var cooldown_left = dash_manager.cooldown_timer
			# Hitung progres (0.0 -> 1.0)
			var progress = (cooldown_total - cooldown_left) / cooldown_total 
			dash.value = progress * dash.max_value
		else:
			# Jika cooldown 0 tapi charge belum penuh
			dash.value = dash.max_value
	# --- AKHIR MODIFIKASI ---


# --- 3. LOGIKA MORPH SKILL ---

func _setup_morph_icons():
	# Petakan nama internal skill ke node ikon Anda
	# Nama ini didasarkan pada `skill_manager.gd`
	skill_icons = {
		"homing": icon_puppet_shooter,       # dari "ShootingEnemy"
		"triple_homing": icon_puppet_shooter_2, # dari "DashShootingEnemy"
		"wolf": icon_wolf,                  # dari "Wolf"
		"slash": icon_puppet                # dari "BrokenPuppet"
	}
	
	# Simpan posisi Y awal & sembunyikan semua ikon
	for icon_node in skill_icons.values():
		if icon_node:
			skill_icon_original_pos_y[icon_node] = icon_node.position.y
			icon_node.visible = false

func _update_morph_skill_icons():
	# --- AWAL LOGIKA BARU (STACKABLE) ---
	# Loop melalui semua ikon skill yang kita tahu
	for skill_name in skill_icons.keys():
		var icon_node: Sprite2D = skill_icons[skill_name]
		if not icon_node:
			continue

		# 1. Cek status 'ready' di SkillManager
		var is_ready = false
		if skill_name == "homing":
			is_ready = skill_manager.homing_shot_ready
		elif skill_name == "triple_homing":
			is_ready = skill_manager.triple_homing_shot_ready
		elif skill_name == "wolf":
			is_ready = skill_manager.wolf_morph_ready
		elif skill_name == "slash":
			is_ready = skill_manager.slash_shot_ready

		# 2. Bandingkan status 'ready' dengan 'visible'
		var is_visible = icon_node.visible

		if is_ready and not is_visible:
			# Baru didapat! Tampilkan & mainkan animasi.
			icon_node.visible = true
			_play_jump_tween(icon_node)
		elif not is_ready and is_visible:
			# Baru dipakai/hilang! Sembunyikan.
			icon_node.visible = false
	# --- AKHIR LOGIKA BARU ---

# Dipanggil saat skill dipakai (sinyal dari SkillManager)
func _on_stolen_skill_used():
	# SkillManager sudah set semua flag ke false.
	# _update_morph_skill_icons() di frame _process berikutnya
	# akan otomatis menyembunyikan semua ikon.
	pass

# Helper untuk mengurus tampilan & animasi (FUNGSI INI DIHAPUS)
# func _update_icon_visibility_and_tween(active_skill_name: String):
# (SELURUH FUNGSI INI DIHAPUS)

# Fungsi untuk animasi "lompat"
func _play_jump_tween(icon_node: Sprite2D):
	if not skill_icon_original_pos_y.has(icon_node):
		return # Tidak punya posisi asli, batalkan

	var original_y = skill_icon_original_pos_y[icon_node]
	
	# Setel ulang posisi ke awal (jika tween sebelumnya belum selesai)
	icon_node.position.y = original_y
	
	# Buat tween baru
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT) # Lompat ke atas
	tween.set_trans(Tween.TRANS_QUAD)
	
	# 1. Lompat ke atas
	tween.tween_property(icon_node, "position:y", original_y + SKILL_ICON_JUMP_HEIGHT, 0.15)
	
	# 2. Rantai tween berikutnya: Turun kembali
	tween.chain()
	tween.set_ease(Tween.EASE_IN) # Jatuh ke bawah
	tween.tween_property(icon_node, "position:y", original_y, 0.15)


# --- 4. LOGIKA PIN LABEL ---
func _on_pin_count_changed(current: int, max: int):
	if pin_label:
		pin_label.text = "%d/%d" % [current, max]


# --- 5. LOGIKA SUPER DASH INDIKATOR ---
func _update_super_dash_indicator():
	if not super_dash_indicator:
		return
	
	# --- AWAL LOGIKA BARU ---
	
	# super_dash_counter == 0 berarti "SIAP DIPAKAI"
	# super_dash_counter == 1 berarti "SEDANG MENGISI ULANG"
	var is_ready = (super_dash.super_dash_counter == 0)
	
	var target_frame = 0
	
	if is_ready:
		# Dash sudah penuh dan siap dipakai
		target_frame = 3 # Frame "Penuh"
	else:
		# Dash sedang mengisi ulang.
		# Kita cek progresnya (0, 1, atau 2)
		var current_charge = super_dash.super_dash_recharge_counter
		
		if current_charge == 2:
			target_frame = 2 # Frame "2/3"
		elif current_charge == 1:
			target_frame = 1 # Frame "1/3"
		else:
			target_frame = 0 # Frame "Kosong" (baru dipakai)
			
	if super_dash_indicator.frame != target_frame:
		super_dash_indicator.frame = target_frame
	# --- AKHIR LOGIKA BARU ---
