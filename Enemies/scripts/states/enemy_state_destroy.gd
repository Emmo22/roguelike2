class_name EnemyStateDestroy extends EnemyState

@export var anim_name : String = "destroy"
@export var knockback_speed : float = 300.0
@export var decelerate_speed : float = 20.0

@export_category("AI")

var _damage_position : Vector2
var _direction : Vector2


func init() -> void:
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)
	pass
	

func enter() -> void:
	enemy.invulnerable == true
	_direction = enemy.global_position.direction_to(_damage_position)
	enemy.SetDirection(_direction)
	enemy.velocity = _direction * -knockback_speed
	enemy.UpdateAnimation(anim_name)
	enemy.animation_player.animation_finished.connect(_on_animation_finished)
	pass



func Exit() -> void:
	pass



func Process(_delta: float) -> EnemyState:
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta 
	return null



func Physics(_delta : float) -> EnemyState:
	return null



func _on_enemy_destroyed(hurtbox : Hurtbox) -> void:
	_damage_position = hurtbox.global_position
	state_machine.change_state( self )


func _on_animation_finished(I_a: String) -> void:
	enemy.queue_free()
