class_name GameSession
extends RefCounted
## What the screen talks to. It sends this device's commands and hands back every event
## that happened, through one signal. The screen never asks the Authority directly, so it
## works the same whether the Authority runs here (solo, co-op host) or on another phone
## (co-op guest). Decision D-014.

## Every event for every player, in the order they happened.
signal events_emitted(events: Array[GameEvent])

## The seat this device plays, for example "player:1".
var local_player_id: String = ""


## Sends a command for the local player. Results arrive later through events_emitted.
func send(_command: GameCommand) -> void:
	push_error("GameSession.send must be implemented by a concrete session")
