extends Node

var registered_keys: Dictionary = {}
var chain_buffer: Array[Key] = []
var chain_timeout: Timer
const CHAIN_WINDOW_SEC: float = 1.5

func _ready() -> void:
	chain_timeout = Timer.new()
	chain_timeout.one_shot = true
	chain_timeout.wait_time = CHAIN_WINDOW_SEC
	chain_timeout.timeout.connect(_on_chain_timeout)
	add_child(chain_timeout)

func register(entity: KeyEntity) -> void:
	registered_keys[entity.key] = entity
	for effect in entity.effects:
		effect.on_register(entity)
	SignalBus.key_registered.emit(entity)

func unregister(key: Key) -> void:
	if not registered_keys.has(key):
		return
	var entity: KeyEntity = registered_keys[key]
	for effect in entity.effects:
		effect.on_remove(entity)
	registered_keys.erase(key)

func handle_key(key: Key, player: Player) -> void:
	if not registered_keys.has(key):
		return
	var entity: KeyEntity = registered_keys[key]

	# Lock check
	if entity.is_locked:
		for effect in entity.effects:
			effect.on_blocked(entity, player)
		return

	entity.increment_press()

	# Run effects (may lock the key mid-press)
	for effect in entity.effects:
		effect.on_press(entity, player)

	# Chain buffer: always append before resolving
	chain_buffer.append(key)
	chain_timeout.start()
	SignalBus.chain_buffer_changed.emit(chain_buffer.duplicate())

	# Try chain match first
	var chain_spell: SpellData = ChainSpellRegistry.match_sequence(chain_buffer)
	if chain_spell != null:
		chain_buffer.clear()
		chain_timeout.stop()
		SignalBus.chain_buffer_changed.emit([])
		SignalBus.chain_matched.emit(chain_spell)
		_resolve_spell(chain_spell, player)
		return

	# No chain match — resolve single key spell if not chain-only
	if entity.spell != null and \
	   entity.spell.activation_type != SpellData.SpellType.CHAIN_ONLY:
		_resolve_spell(entity.spell, player)

func _resolve_spell(spell: SpellData, player: Player) -> void:
	match spell.activation_type:
		SpellData.SpellType.INSTANT:
			if player.stats.spend_mana(spell.mana_cost):
				# Spawn effect at player position
				if spell.projectile_scene:
					player.wand.try_fire(player.get_global_mouse_position())
		SpellData.SpellType.EQUIP_WAND:
			if player.stats.spend_mana(spell.mana_cost):
				player.wand.equip_spell(spell)

func _on_chain_timeout() -> void:
	chain_buffer.clear()
	SignalBus.chain_buffer_changed.emit([])

# External modification API
func lock_key(key: Key) -> void:
	if registered_keys.has(key):
		registered_keys[key].lock()

func unlock_key(key: Key) -> void:
	if registered_keys.has(key):
		registered_keys[key].unlock()

func add_effect(key: Key, effect: KeyEffect) -> void:
	if registered_keys.has(key):
		registered_keys[key].effects.append(effect)
		effect.on_register(registered_keys[key])

func reset_press_count(key: Key) -> void:
	if registered_keys.has(key):
		registered_keys[key].press_count = 0
