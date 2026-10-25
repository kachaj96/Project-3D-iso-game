class_name MapProp
extends Resource
## An object standing on a map cell that the player can tap, for example a sign.
## The cell must also be listed in the map's blocked_cells: nobody walks through a sign.

const ID_PATTERN: String = "^prop(\\.[a-z0-9_]+)+$"
## Every kind the game knows how to show and use. Add a kind here only together with the
## code that handles it.
const KINDS: Array[String] = ["sign", "inspect"]

@export var id: String = ""
## What it looks like and how it behaves. "sign" shows its text; "inspect" shows what the hero says or thinks when he looks at it (blood traces, a coffin).
@export var kind: String = "sign"
@export var cell: Vector2i = Vector2i.ZERO
## Translation key of the text shown to the player, never the text itself.
@export var text_key: String = ""
