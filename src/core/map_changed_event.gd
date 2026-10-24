class_name MapChangedEvent
extends GameEvent
## The character left a map through an exit and now stands on cell of map_id.

var from_map_id: String = ""
var map_id: String = ""
var cell: Vector2i = Vector2i.ZERO
