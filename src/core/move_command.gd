class_name MoveCommand
extends GameCommand
## "Walk my character to this cell of the map I am on."

var target_cell: Vector2i = Vector2i.ZERO


static func create(for_player_id: String, cell: Vector2i) -> MoveCommand:
	var command: MoveCommand = MoveCommand.new()
	command.player_id = for_player_id
	command.target_cell = cell
	return command
