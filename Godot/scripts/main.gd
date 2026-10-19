extends Node3D

const SPEED := 6.0
const RUN_SPEED := 9.0
const GRAVITY := 20.0
const SAVE_PATH := "user://arielia_save.json"

var player: CharacterBody3D
var camera_pivot: Node3D
var camera: Camera3D
var move_touch := Vector2.ZERO
var yaw := 0.0
var pitch := -0.12
var last_drag := Vector2.ZERO
var look_index := -1
var running := false
var hp := 100
var gold := 0
var xp := 0
var level := 1
var clock := 0.0
var rng := RandomNumberGenerator.new()
var sun: DirectionalLight3D
var status_label: Label
var stats_label: Label
var animals: Array[Node3D] = []

func _ready() -> void:
 rng.randomize()
 _build_environment()
 _build_world()
 _build_player()
 _build_ui()
 _load_save()

func _material(color: Color) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = 0.9
 return m

func _build_environment() -> void:
 var env_node := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_SKY
 var sky := Sky.new()
 var sky_mat := ProceduralSkyMaterial.new()
 sky_mat.sky_top_color = Color(0.08, 0.2, 0.43)
 sky_mat.sky_horizon_color = Color(0.58, 0.7, 0.82)
 sky.sky_material = sky_mat
 env.sky = sky
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color(0.62, 0.69, 0.8)
 env.ambient_light_energy = 0.7
 env_node.environment = env
 add_child(env_node)
 sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-45, -25, 0)
 sun.shadow_enabled = true
 add_child(sun)

func _build_world() -> void:
 var ground := StaticBody3D.new()
 var ground_mesh := MeshInstance3D.new()
 var plane := PlaneMesh.new()
 plane.size = Vector2(260, 260)
 ground_mesh.mesh = plane
 ground_mesh.material_override = _material(Color(0.16, 0.31, 0.12))
 ground.add_child(ground_mesh)
 var collision := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(260, 1, 260)
 collision.shape = box
 collision.position.y = -0.5
 ground.add_child(collision)
 add_child(ground)
 # River, path, trees and rocks are procedural placeholders.
 var river := MeshInstance3D.new()
 var water := BoxMesh.new()
 water.size = Vector3(8, 0.12, 180)
 river.mesh = water
 river.position = Vector3(24, 0.03, 0)
 river.material_override = _material(Color(0.04, 0.3, 0.55))
 add_child(river)
 var path := MeshInstance3D.new()
 var road := BoxMesh.new()
 road.size = Vector3(7, 0.08, 90)
 path.mesh = road
 path.position = Vector3(-18, 0.04, -35)
 path.material_override = _material(Color(0.28, 0.23, 0.16))
 add_child(path)
 for i in range(85):
  var p := Vector3(rng.randf_range(-115,115), 0, rng.randf_range(-115,115))
  if absf(p.x - 24) < 7 or (absf(p.x + 18) < 6 and p.z < 12 and p.z > -80):
   continue
  _add_tree(p, rng.randf_range(0.7, 1.4))
 for i in range(20):
  var rock := MeshInstance3D.new()
  var mesh := SphereMesh.new()
  mesh.radius = rng.randf_range(0.35, 0.9)
  mesh.height = mesh.radius * 1.5
  rock.mesh = mesh
  rock.position = Vector3(rng.randf_range(-100,100), mesh.height * 0.35, rng.randf_range(-100,100))
  rock.material_override = _material(Color(0.31,0.33,0.3))
  add_child(rock)
 _build_village()
 _build_animals()

func _add_tree(p: Vector3, s: float) -> void:
 var tree := Node3D.new()
 tree.position = p
 tree.scale = Vector3.ONE * s
 var trunk := MeshInstance3D.new()
 var trunk_mesh := CylinderMesh.new()
 trunk_mesh.top_radius = 0.16
 trunk_mesh.bottom_radius = 0.28
 trunk_mesh.height = 2.4
 trunk.mesh = trunk_mesh
 trunk.position.y = 1.2
 trunk.material_override = _material(Color(0.24,0.12,0.06))
 tree.add_child(trunk)
 var crown := MeshInstance3D.new()
 var crown_mesh := SphereMesh.new()
 crown_mesh.radius = 1.2
 crown_mesh.height = 2.4
 crown.mesh = crown_mesh
 crown.position.y = 2.8
 crown.material_override = _material(Color(rng.randf_range(0.04,0.12),rng.randf_range(0.2,0.36),0.06))
 tree.add_child(crown)
 var body := StaticBody3D.new()
 var shape_node := CollisionShape3D.new()
 var shape := CylinderShape3D.new()
 shape.radius = 0.35
 shape.height = 2.4
 shape_node.shape = shape
 shape_node.position.y = 1.2
 body.add_child(shape_node)
 tree.add_child(body)
 add_child(tree)

func _build_village() -> void:
 for i in range(6):
  var house := Node3D.new()
  house.position = Vector3(-30 + (i % 3) * 10, 0, -52 + int(i / 3) * 12)
  var walls := MeshInstance3D.new()
  var wall_mesh := BoxMesh.new()
  wall_mesh.size = Vector3(5.5,3,5)
  walls.mesh = wall_mesh
  walls.position.y = 1.5
  walls.material_override = _material([Color(0.55,0.36,0.22),Color(0.48,0.4,0.3),Color(0.61,0.5,0.34)][i%3])
  house.add_child(walls)
  var roof := MeshInstance3D.new()
  var roof_mesh := PrismMesh.new()
  roof_mesh.size = Vector3(6,2,5.5)
  roof.mesh = roof_mesh
  roof.position.y = 3.8
  roof.material_override = _material(Color(0.32,0.08,0.07))
  house.add_child(roof)
  var building_body := StaticBody3D.new()
  var shape_node := CollisionShape3D.new()
  var shape := BoxShape3D.new()
  shape.size = Vector3(5.5,3,5)
  shape_node.shape = shape
  shape_node.position.y = 1.5
  building_body.add_child(shape_node)
  house.add_child(building_body)
  add_child(house)

func _build_animals() -> void:
 for i in range(8):
  var animal := Node3D.new()
  animal.name = "Wildlife_%02d" % i
  animal.position = Vector3(rng.randf_range(-80,80),0,rng.randf_range(-80,80))
  animal.set_meta("home", animal.position)
  animal.set_meta("target", Vector3.ZERO)
  animal.set_meta("wait", rng.randf_range(1,4))
  animal.set_meta("speed", rng.randf_range(0.8,1.6))
  var body := MeshInstance3D.new()
  var body_mesh := CapsuleMesh.new()
  body_mesh.radius = 0.3
  body_mesh.height = 0.9
  body.mesh = body_mesh
  body.position.y = 0.55
  body.rotation_degrees.z = 90
  body.material_override = _material(Color(0.48,0.34,0.19))
  animal.add_child(body)
  var head := MeshInstance3D.new()
  var head_mesh := SphereMesh.new()
  head_mesh.radius = 0.2
  head.mesh = head_mesh
  head.position = Vector3(0,0.62,-0.45)
  head.material_override = body.material_override
  animal.add_child(head)
  add_child(animal)
  animals.append(animal)

func _build_player() -> void:
 player = CharacterBody3D.new()
 player.name = "Player"
 player.position = Vector3(0,0.2,5)
 var shape_node := CollisionShape3D.new()
 var capsule := CapsuleShape3D.new()
 capsule.radius = 0.36
 capsule.height = 1.8
 shape_node.shape = capsule
 shape_node.position.y = 0.9
 player.add_child(shape_node)
 var body := MeshInstance3D.new()
 var body_mesh := CapsuleMesh.new()
 body_mesh.radius = 0.36
 body_mesh.height = 1.2
 body.mesh = body_mesh
 body.position.y = 1.05
 body.material_override = _material(Color(0.55,0.05,0.1))
 player.add_child(body)
 var head := MeshInstance3D.new()
 var head_mesh := SphereMesh.new()
 head_mesh.radius = 0.23
 head.mesh = head_mesh
 head.position.y = 1.82
 head.material_override = _material(Color(0.72,0.5,0.36))
 player.add_child(head)
 add_child(player)
 camera_pivot = Node3D.new()
 camera_pivot.position.y = 1.6
 player.add_child(camera_pivot)
 camera = Camera3D.new()
 camera.position = Vector3(0,0.7,6)
 camera.rotation_degrees.x = 7
 camera.current = true
 camera_pivot.add_child(camera)

func _build_ui() -> void:
 var layer := CanvasLayer.new()
 add_child(layer)
 var panel := PanelContainer.new()
 panel.position = Vector2(12,12)
 panel.custom_minimum_size = Vector2(310,76)
 layer.add_child(panel)
 var column := VBoxContainer.new()
 panel.add_child(column)
 var title := Label.new()
 title.text = "أريليا | عالم مفتوح"
 column.add_child(title)
 stats_label = Label.new()
 column.add_child(stats_label)
 status_label = Label.new()
 status_label.text = "اجمع الذهب واستكشف القرية"
 column.add_child(status_label)
 _touch_button(layer,"◀",Vector2(20,-110),Vector2(80,-50),Vector2(-1,0))
 _touch_button(layer,"▶",Vector2(150,-110),Vector2(210,-50),Vector2(1,0))
 _touch_button(layer,"▲",Vector2(85,-175),Vector2(145,-115),Vector2(0,-1))
 _touch_button(layer,"▼",Vector2(85,-105),Vector2(145,-45),Vector2(0,1))
 _action_button(layer,"قفز",Vector2(-140,-170),Vector2(-30,-110),_jump)
 _action_button(layer,"هجوم",Vector2(-140,-100),Vector2(-30,-40),_attack)
 _action_button(layer,"حفظ",Vector2(-260,-100),Vector2(-150,-40),_save_game)
 var run_btn := _make_button(layer,"جري",Vector2(-260,-170),Vector2(-150,-110))
 run_btn.button_down.connect(func(): running = true)
 run_btn.button_up.connect(func(): running = false)

func _make_button(parent: Control, label_text: String, a: Vector2, b: Vector2) -> Button:
 var btn := Button.new()
 btn.text = label_text
 btn.anchor_left = 1
 btn.anchor_right = 1
 btn.anchor_top = 1
 btn.anchor_bottom = 1
 btn.offset_left = a.x
 btn.offset_top = a.y
 btn.offset_right = b.x
 btn.offset_bottom = b.y
 parent.add_child(btn)
 return btn

func _touch_button(parent: Control, label_text: String, a: Vector2, b: Vector2, dir: Vector2) -> void:
 var btn := Button.new()
 btn.text = label_text
 btn.anchor_top = 1
 btn.anchor_bottom = 1
 btn.offset_left = a.x
 btn.offset_top = a.y
 btn.offset_right = b.x
 btn.offset_bottom = b.y
 btn.button_down.connect(func(): move_touch = dir)
 btn.button_up.connect(func():
  if move_touch == dir:
   move_touch = Vector2.ZERO
 )
 parent.add_child(btn)

func _action_button(parent: Control, label_text: String, a: Vector2, b: Vector2, callback: Callable) -> void:
 var btn := _make_button(parent,label_text,a,b)
 btn.pressed.connect(callback)

func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  yaw -= event.relative.x * 0.004
  pitch = clampf(pitch - event.relative.y * 0.003,-0.6,0.2)
 elif event is InputEventScreenTouch:
  if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.45:
   look_index = event.index
   last_drag = event.position
  elif not event.pressed and event.index == look_index:
   look_index = -1
 elif event is InputEventScreenDrag and event.index == look_index:
  var delta_pos: Vector2 = event.position - last_drag
  yaw -= delta_pos.x * 0.006
  pitch = clampf(pitch - delta_pos.y * 0.004,-0.6,0.2)
  last_drag = event.position

func _physics_process(delta: float) -> void:
 if not is_instance_valid(player): return
 var input_vec := Input.get_vector("move_left","move_right","move_forward","move_back")
 if move_touch.length() > 0.1: input_vec = move_touch
 var dir := Vector3(input_vec.x,0,input_vec.y).rotated(Vector3.UP,yaw)
 var speed := RUN_SPEED if running else SPEED
 player.velocity.x = move_toward(player.velocity.x,dir.x*speed,24*delta)
 player.velocity.z = move_toward(player.velocity.z,dir.z*speed,24*delta)
 if dir.length() > 0.08: player.rotation.y = lerp_angle(player.rotation.y,atan2(dir.x,-dir.z),delta*8)
 if not player.is_on_floor(): player.velocity.y -= GRAVITY*delta
 elif player.velocity.y < 0: player.velocity.y = 0
 if Input.is_action_just_pressed("jump") and player.is_on_floor(): player.velocity.y = 7.2
 player.move_and_slide()
 camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y,yaw,delta*7)
 camera_pivot.rotation.x = lerpf(camera_pivot.rotation.x,pitch,delta*7)
 _update_animals(delta)
 clock += delta*0.02
 sun.rotation_degrees = Vector3(-25-sin(clock)*65,-30+cos(clock)*150,0)
 sun.light_energy = clampf(sin(clock)*0.5+0.5,0.12,1.2)
 if stats_label: stats_label.text = "❤️ %d   ⭐ مستوى %d   🪙 ذهب %d" % [hp,level,gold]

func _update_animals(delta: float) -> void:
 for animal in animals:
  var wait := float(animal.get_meta("wait"))
  var target: Vector3 = animal.get_meta("target")
  if wait > 0:
   animal.set_meta("wait",wait-delta)
   continue
  if target == Vector3.ZERO or animal.position.distance_to(target) < 1:
   if rng.randf() < 0.35:
    animal.set_meta("wait",rng.randf_range(1,4))
    animal.set_meta("target",Vector3.ZERO)
    continue
   var home: Vector3 = animal.get_meta("home")
   target = home + Vector3(rng.randf_range(-10,10),0,rng.randf_range(-10,10))
   animal.set_meta("target",target)
  var d := target-animal.position
  d.y = 0
  if d.length() > 0.1:
   animal.position += d.normalized()*float(animal.get_meta("speed"))*delta
   animal.rotation.y = lerp_angle(animal.rotation.y,atan2(d.x,d.z),delta*3)

func _jump() -> void:
 if player.is_on_floor(): player.velocity.y = 7.2

func _attack() -> void:
 for animal in animals:
  if is_instance_valid(animal) and player.global_position.distance_to(animal.global_position) < 3:
   animal.queue_free()
   animals.erase(animal)
   xp += 10
   if xp >= level*50:
    xp -= level*50
    level += 1
   status_label.text = "ضربت مخلوقًا واكتسبت خبرة"
   return
 status_label.text = "مفيش مخلوق قريب"

func _save_game() -> void:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify({"hp":hp,"gold":gold,"xp":xp,"level":level,"pos":[player.position.x,player.position.y,player.position.z],"clock":clock}))
  file.close()
  status_label.text = "تم حفظ التقدم على الجهاز"

func _load_save() -> void:
 if not FileAccess.file_exists(SAVE_PATH): return
 var file := FileAccess.open(SAVE_PATH,FileAccess.READ)
 if not file: return
 var data: Variant = JSON.parse_string(file.get_as_text())
 file.close()
 if typeof(data) != TYPE_DICTIONARY: return
 hp = int(data.get("hp",100))
 gold = int(data.get("gold",0))
 xp = int(data.get("xp",0))
 level = int(data.get("level",1))
 var p: Variant = data.get("pos",[0,0.2,5])
 if p is Array and p.size() == 3: player.position = Vector3(float(p[0]),float(p[1]),float(p[2]))
 clock = float(data.get("clock",0))
