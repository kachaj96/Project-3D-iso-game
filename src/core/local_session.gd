class_name LocalSession
extends GameSession
## Session for a game whose Authority runs on this device (solo play, later the co-op host).

var _authority: Authority


func _init(authority: Authority, player_id: String) -> void:
	_authority = authority
	local_player_id = player_id


## Brings the local player's character into the game on map_id.
func start(character_id: String, map_id: String) -> void:
	events_emitted.emit(_authority.add_character(local_player_id, character_id, map_id))


func send(command: GameCommand) -> void:
	# The sender is always the local seat: this device can only speak for its own player.
	events_emitted.emit(_authority.submit(local_player_id, command))
