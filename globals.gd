extends Node

var cells: Array[Button] = []
var moves: Array[String] = []
var game_started: bool = false
var current_player: String = "X"
var quantum_params: Dictionary = {"qX": 0.0, "qO": 0.0}
var tutorial_index := 0
