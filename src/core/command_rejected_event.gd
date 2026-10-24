class_name CommandRejectedEvent
extends GameEvent
## The Authority refused a command. reason is a code for logs and tests ("unknown_player",
## "no_path", "already_there"), not text shown to the player.

var reason: String = ""


static func create(for_player_id: String, why: String) -> CommandRejectedEvent:
	var event: CommandRejectedEvent = CommandRejectedEvent.new()
	event.player_id = for_player_id
	event.reason = why
	return event
