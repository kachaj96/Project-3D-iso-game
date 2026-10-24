class_name CharacterState
extends RefCounted
## Everything that belongs to one player's character and is saved in that player's
## own character file. M1 only needs identity and position; class, stats and inventory
## come later.
##
## Two different ids (decision D-013):
## - character_id: who the character is. Created once, never changes, names the save file.
## - player_id: which seat at the table controls it in this session ("player:1"). The host
##   assigns it each time a game starts. Commands and combat controllers use it.

const ID_PREFIX: String = "char."

var character_id: String = ""
var player_id: String = ""
var map_id: String = ""
var cell: Vector2i = Vector2i.ZERO


## A new, practically unique character id like "char.9f3a51c0d2e47b18".
## Uses the system's secure random source, not the game RNG: an id is not gameplay
## randomness and must not repeat between devices that use the same seed.
static func generate_character_id() -> String:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(8)
	return ID_PREFIX + bytes.hex_encode()
