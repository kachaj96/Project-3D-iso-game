class_name WorldState
extends RefCounted
## Everything that belongs to the world and its host: flags set by quests and events.
## Kept separate from CharacterState so a guest can bring a character into a host's world.

## Flag id (for example "flag.bridge_repaired") -> value.
var flags: Dictionary = {}
