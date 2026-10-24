class_name InteractCommand
extends GameCommand
## "Use the object on this cell of the map I am on." If the character is not next to it,
## the Authority first walks it to a free cell beside the object.

var target_cell: Vector2i = Vector2i.ZERO


static func create(for_player_id: String, cell: Vector2i) -> InteractCommand:
	var command: InteractCommand = InteractCommand.new()
	command.player_id = for_player_id
	command.target_cell = cell
	return command
