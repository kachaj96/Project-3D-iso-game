class_name CharacterState
extends RefCounted
## Everything that belongs to one player's character and is saved in that player's
## own character file. M1 only needs the position; class, stats and inventory come later.

var player_id: String = ""
var map_id: String = ""
var cell: Vector2i = Vector2i.ZERO
