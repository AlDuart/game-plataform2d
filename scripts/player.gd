extends CharacterBody2D

#possiveis estados de animação do player
enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	slide,
	hurt,
	duck
}
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D



@onready var reload_timer: Timer = $ReloadTimer
@export var MAXSPEED = 100
@export var acceleration  = 400
@export var deceleration = 400
@export var slide_deceleration = 100
const JUMP_VELOCITY = -350.0
const DUCKING_SPEED = 30



var direction = 0
var status: PlayerState
var jump_count = 0
@export var max_jump_count = 2




func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	
	match status:
		PlayerState.slide:
			slide_state(delta)
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.hurt:
			hurt_state(delta)
	
	move_and_slide()

func go_to_hurt_state():
	status = PlayerState.hurt
	anim.play("hurt")
	velocity.x = 0
	reload_timer.start()
	return

func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")

func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")

func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	
func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	set_small_colider()
	
	
func exit_from_duck_state():
	set_normal_collider()
	
func go_to_slide_state():
	status = PlayerState.slide
	anim.play("slide")
	set_small_colider()
	
func exit_from_slide_state():
	set_normal_collider()
	
func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	
func idle_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if Input.is_action_pressed("duck"):
		go_to_duck_state()
	return
	
func hurt_state(_delta):
	pass

func walk_state(delta):
	move(delta)
	
	if velocity.x == 0:
		go_to_idle_state()
		return
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	if !is_on_floor():
		jump_count += 1
		go_to_fall_state()
		return
	if Input.is_action_just_pressed("duck"):
		go_to_slide_state()
		return
	
func duck_state(_delta):
	update_direction()
	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return
	
	
	
func jump_state(delta):
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	if velocity.y > 0:
		go_to_fall_state()
		return
	
	

func fall_state(delta):
	move(delta)
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	
	if is_on_floor():
		jump_count = 0
		go_to_idle_state()
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
			return
func slide_state(delta):
	velocity.x = move_toward(velocity.x, 0, slide_deceleration * delta)
	if Input.is_action_just_released("duck"):
		exit_from_slide_state()
		go_to_walk_state()
		return
	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state()
		return


func move(delta):
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * MAXSPEED, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	

func update_direction():
	direction = Input.get_axis("left", "right")
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false


func can_jump() -> bool:
	return jump_count < max_jump_count


func set_small_colider():
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 9
	collision_shape.position.y = 11
	
	hitbox_collision_shape.shape.size.y = 15
	hitbox_collision_shape.position.y = 9
	
func set_normal_collider():
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 22
	collision_shape.position.y = 4
	
	hitbox_collision_shape.shape.size.y = 24
	hitbox_collision_shape.position.y = 3



func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()
	
func hit_enemy(area: Area2D):
	if velocity.y > 0:
		area.get_parent().take_damage()  #inimigo morre
		go_to_jump_state()
	else:
		if status != PlayerState.hurt:
			go_to_hurt_state()           #player morre

func hit_lethal_area():
	go_to_hurt_state()


func _on_reload_timer_timeout() -> void:
	get_tree() .reload_current_scene()
