extends Resource
class_name CardModeData

@export var mode_name: String = "Alternate Mode"

@export_group("Combat Range")
@export var is_melee: bool = false
@export var is_ranged: bool = true
@export var has_depth_charge: bool = false
@export var can_attack: bool = true

@export_group("Domain & Roles")
@export var is_ground: bool = false
@export var is_air: bool = false
@export var is_naval: bool = false
@export var is_sub_naval: bool = false
@export var is_orbital: bool = false
@export var is_anti_air: bool = false
@export var is_sam: bool = false

@export_group("Base ATK mods")
@export var attack_power: int = 2
@export_range(0, 100) var crit_chance: int = 0 
@export var crit_multiplier: float = 2.0 

@export_group("Attack Times & Burst")
@export var attack_times: int = 1
@export var max_attack_cooldown: int = 0
@export var burst_count: int = 1
@export var burst_delay: float = 0.2

@export_group("Attack ETC.")
@export var base_ignore_def: bool = false 
@export var splash_damage: bool = false
@export var outgoing_damage_type: String = "normal"

@export_group("Visual Effects & Audio")
@export_enum("None", "Judgement Cut", "Explosion", "Gunfire", "Melee Hit") var attack_vfx: String = "None"
@export var attack_sfx: Array[AudioStream] = []	
