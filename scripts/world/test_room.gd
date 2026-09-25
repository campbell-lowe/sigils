extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var interaction_area: Area2D = $Becca/InteractionArea
@onready var keeper_interaction_area: Area2D = $Keeper/InteractionArea
@onready var fountain_interaction_area: Area2D = $Fountain/InteractionArea
@onready var interaction_prompt: Label = $Interface/InteractionPrompt
@onready var objective_label: Label = $Interface/Objective
@onready var dialogue_box: ColorRect = $Interface/DialogueBox
@onready var speaker_label: Label = $Interface/DialogueBox/Speaker
@onready var dialogue_label: Label = $Interface/DialogueBox/Dialogue
@onready var dialogue_hint: Label = $Interface/DialogueBox/Hint
@onready var sigil_effect: Polygon2D = $Fountain/SigilEffect

var dialogue_open := false
var dialogue_line_index := 0
var e_was_pressed := false
var dialogue_lines: Array[String] = []
var active_interaction := ""
var becca_spoken := false
var keeper_spoken := false
var rite_complete := false

func _ready() -> void:
	dialogue_box.visible = false
	interaction_prompt.visible = false
	sigil_effect.visible = false
	_update_objective()

func _process(_delta: float) -> void:
	var e_pressed := Input.is_key_pressed(KEY_E)
	var interaction_pressed := (e_pressed and not e_was_pressed) or Input.is_action_just_pressed("ui_accept")
	e_was_pressed = e_pressed

	if dialogue_open:
		player.movement_enabled = false
		interaction_prompt.visible = false
		if interaction_pressed:
			_advance_dialogue()
		return

	player.movement_enabled = true
	active_interaction = _get_nearby_interaction()
	interaction_prompt.visible = active_interaction != "" and not rite_complete
	if interaction_prompt.visible:
		interaction_prompt.text = _prompt_for(active_interaction)
	if interaction_prompt.visible and interaction_pressed:
		_start_interaction(active_interaction)

func _get_nearby_interaction() -> String:
	if fountain_interaction_area.has_overlapping_bodies():
		return "fountain"
	if keeper_interaction_area.has_overlapping_bodies():
		return "keeper"
	if interaction_area.has_overlapping_bodies():
		return "becca"
	return ""

func _prompt_for(interaction: String) -> String:
	match interaction:
		"becca":
			return "Press E to talk to Becca"
		"keeper":
			return "Press E to speak with the Keeper"
		"fountain":
			if becca_spoken and keeper_spoken:
				return "Press E to begin the Sigil Rite"
			return "The Fountain of Fire awaits"
	return ""

func _start_interaction(interaction: String) -> void:
	match interaction:
		"becca":
			becca_spoken = true
			_update_objective()
			_show_dialogue("Becca", ["Stay close to me, Andrea. The palace can be overwhelming."])
		"keeper":
			keeper_spoken = true
			_update_objective()
			_show_dialogue("Keeper", ["The Fountain of Fire will reveal the sigil meant for you."])
		"fountain":
			if becca_spoken and keeper_spoken:
				_begin_rite()

func _show_dialogue(speaker: String, lines: Array[String]) -> void:
	dialogue_open = true
	dialogue_line_index = 0
	dialogue_lines = lines
	speaker_label.text = speaker
	dialogue_label.text = dialogue_lines[dialogue_line_index]
	dialogue_hint.text = "Press E to close"
	dialogue_box.visible = true

func _begin_rite() -> void:
	rite_complete = true
	_update_objective()
	sigil_effect.visible = true
	sigil_effect.scale = Vector2(0.2, 0.2)
	var reveal_tween := create_tween()
	reveal_tween.set_parallel(true)
	reveal_tween.tween_property(sigil_effect, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(sigil_effect, "rotation", TAU, 1.4)
	_show_dialogue("Andrea", ["The fire answers. My Valestra Sigil has manifested."])

func _update_objective() -> void:
	if rite_complete:
		objective_label.text = "Objective complete: The Valestra Sigil has manifested."
	elif becca_spoken and keeper_spoken:
		objective_label.text = "Objective: Reach the Fountain of Fire."
	elif becca_spoken:
		objective_label.text = "Objective: Speak with the Keeper."
	else:
		objective_label.text = "Objective: Speak with Becca."

func _advance_dialogue() -> void:
	dialogue_open = false
	dialogue_box.visible = false