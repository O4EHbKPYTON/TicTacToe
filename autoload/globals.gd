extends Node

signal quantum_response(result, cell_index)

const SERVER_URL := "http://127.0.0.1:8000/run-cirq"
const BLOCH_SPHERE_URL := "http://127.0.0.1:8000/bloch_sphere/"
const FORMULA_URL := "http://127.0.0.1:8000/formula"

var tutorial_steps = []
var current_step := 0
var current_state := "superposition"
