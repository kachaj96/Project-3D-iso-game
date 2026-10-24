"""Converts a static (unrigged) glTF model into an FBX that Mixamo accepts.

Run:
  blender -b --python tools/blender/export_static_fbx.py -- --input model.glb --output build/mixamo/model.fbx [--height 1.8]

What it does: imports the model, scales it to a human height in metres (Mixamo expects a
normal body size), puts the feet on the ground, applies all transforms, and exports an FBX
with the texture embedded. The model keeps facing -Y in Blender, which the exporter turns
into the +Z facing that Mixamo expects.
"""

import os
import sys

import bpy
from mathutils import Vector


def parse_args():
    argv = sys.argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else []
    opts = {"input": "", "output": "build/mixamo/model.fbx", "height": 1.8}
    for i in range(0, len(argv) - 1, 2):
        key = argv[i].lstrip("-")
        opts[key] = float(argv[i + 1]) if key == "height" else argv[i + 1]
    if not opts["input"]:
        raise SystemExit("--input is required")
    return opts


def main():
    opts = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(opts["input"]))
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("No mesh in the input file")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    body.name = "Character"
    bpy.context.view_layer.update()
    corners = [body.matrix_world @ Vector(c) for c in body.bound_box]
    low = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    high = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    factor = opts["height"] / (high.z - low.z)
    body.scale = (factor, factor, factor)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.context.view_layer.update()
    corners = [body.matrix_world @ Vector(c) for c in body.bound_box]
    body.location.x -= (min(c.x for c in corners) + max(c.x for c in corners)) / 2.0
    body.location.y -= (min(c.y for c in corners) + max(c.y for c in corners)) / 2.0
    body.location.z -= min(c.z for c in corners)
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
    os.makedirs(os.path.dirname(os.path.abspath(opts["output"])), exist_ok=True)
    bpy.ops.export_scene.fbx(
        filepath=os.path.abspath(opts["output"]),
        use_selection=True,
        path_mode="COPY",
        embed_textures=True,
        add_leaf_bones=False,
        bake_anim=False,
    )
    print("FBX written:", os.path.abspath(opts["output"]), "height m:", opts["height"])


main()
