class_name GameCommand
extends RefCounted
## Base class for everything a player can ask the game to do. A command only says what
## the player wants. The Authority decides whether it is allowed and what happens.

var player_id: String = ""
