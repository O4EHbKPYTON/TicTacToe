extends Node

signal quantum_response(result, cell_index)

const SERVER_URL := "http://127.0.0.1:8000/run-cirq"
const BLOCH_SPHERE_URL := "http://127.0.0.1:8000/bloch_sphere/superposition"
const FORMULA_URL := ""
