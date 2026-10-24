class_name MapProp
extends Resource
## An object standing on a map cell that the player can tap, for example a sign.
## The cell must also be listed in the map's blocked_cells: nobody walks through a sign.

const ID_PATTERN: String = "^prop(\\.[a-z0-9_]+)+$"

@export var id: String = ""
## What it looks like and how it behaves. "sign" shows its text.
@export var kind: String = "sign"
@export var cell: Vector2i = Vector2i.ZERO
## Translation key of the text shown to the player, never the text itself.
@export var text_key: String = ""
