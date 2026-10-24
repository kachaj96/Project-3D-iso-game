"""Renders a 3D character into isometric sprite frames, one set per facing.

Run (from the project root):
  blender -b --python tools/blender/render_sprites.py -- --input demo --out build/sprites --name demo

Options (all after the "--"):
  --input PATH|demo   .glb/.gltf/.fbx/.blend file, or "demo" for a built-in test figure
  --out DIR           output folder (frames are written to DIR/NAME/)
  --name NAME         base name of the frames
  --size PX           frame size in pixels, square (default 256)
  --height UNITS      character height in world units, 1 unit = one cell side (default 1.5)
  --directions N      8 (default) or 4
  --frames N          frames to render per direction, spread over the animation (default 1)
  --action NAME       animation (action) to play; default is the first one found, if any
  --outline UNITS     outline thickness in world units (default 0.015)
  --outline-color R,G,B   outline color, 0-1 (default 0.12,0.09,0.07: dark warm brown, not black)

Conventions (they match docs/ART_PIPELINE.md and the Godot grid):
  - Orthographic camera, 30 degrees above the horizon: a ground square shows as a 2:1 diamond.
  - 1 world unit = 90.51 px, so a cell side of 1 unit gives a 128 px wide diamond.
  - The key light is fixed on the screen's top-left. The model turns, the light never does.
  - Facing order is clockwise on the screen, starting toward the camera:
    S, SW, W, NW, N, NE, E, SE  (with 4 directions: S, W, N, E).
  - The model's own front must point along +Y in Blender before it is imported
    (for glTF files the importer already converts this).
  - The point on the ground under the character is at 50% of the frame width and 75% of
    its height. Use that as the sprite's anchor in Godot.
"""

import math
import os
import sys

import bpy
from mathutils import Vector

CELL_DIAMOND_PX = 128.0
PX_PER_UNIT = CELL_DIAMOND_PX / math.sqrt(2.0)  # 90.51
CAMERA_ELEVATION_DEG = 30.0
ANCHOR_FROM_TOP = 0.75
DIRECTION_NAMES_8 = ["S", "SW", "W", "NW", "N", "NE", "E", "SE"]
DIRECTION_NAMES_4 = ["S", "W", "N", "E"]


def parse_args():
    argv = sys.argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else []
    opts = {
        "input": "demo", "out": "build/sprites", "name": "sprite", "size": 256,
        "height": 1.5, "directions": 8, "frames": 1, "action": "",
        "outline": 0.015, "outline_color": (0.12, 0.09, 0.07),
    }
    i = 0
    while i < len(argv):
        key = argv[i].lstrip("-").replace("-", "_")
        value = argv[i + 1]
        if key in ("size", "directions", "frames"):
            opts[key] = int(value)
        elif key in ("height", "outline"):
            opts[key] = float(value)
        elif key == "outline_color":
            opts[key] = tuple(float(v) for v in value.split(","))
        else:
            opts[key] = value
        i += 2
    return opts


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_material(name, color):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    return mat


def build_demo_figure():
    """A simple cartoon figure with a clear front (nose) and a walking bob, for testing."""
    root = bpy.data.objects.new("DemoRoot", None)
    bpy.context.collection.objects.link(root)

    def add(op, name, mat, **kwargs):
        op(**kwargs)
        obj = bpy.context.active_object
        obj.name = name
        obj.data.materials.append(mat)
        obj.parent = root
        bpy.ops.object.shade_smooth()
        return obj

    cloak = make_material("Cloak", (0.75, 0.15, 0.12))
    skin = make_material("Skin", (0.95, 0.75, 0.55))
    boots = make_material("Boots", (0.25, 0.17, 0.10))
    hat = make_material("Hat", (0.15, 0.30, 0.35))
    add(bpy.ops.mesh.primitive_cone_add, "Body", cloak, radius1=0.3, radius2=0.18, depth=0.7, location=(0, 0, 0.55))
    add(bpy.ops.mesh.primitive_uv_sphere_add, "Head", skin, radius=0.26, location=(0, 0, 1.15))
    add(bpy.ops.mesh.primitive_cone_add, "Nose", skin, radius1=0.06, radius2=0.0, depth=0.16, location=(0, 0.3, 1.13), rotation=(-math.pi / 2, 0, 0))
    add(bpy.ops.mesh.primitive_cone_add, "Hat", hat, radius1=0.3, radius2=0.04, depth=0.35, location=(0, 0, 1.45))
    add(bpy.ops.mesh.primitive_cylinder_add, "FootL", boots, radius=0.09, depth=0.14, location=(-0.12, 0.04, 0.07))
    add(bpy.ops.mesh.primitive_cylinder_add, "FootR", boots, radius=0.09, depth=0.14, location=(0.12, 0.04, 0.07))
    # A short "walk" animation: the figure bobs up and down.
    scene = bpy.context.scene
    scene.frame_start, scene.frame_end = 1, 9
    for frame, z in ((1, 0.0), (3, 0.06), (5, 0.0), (7, 0.06), (9, 0.0)):
        root.location.z = z
        root.keyframe_insert("location", index=2, frame=frame)
    return root


def import_model(path):
    ext = os.path.splitext(path)[1].lower()
    before = set(bpy.data.objects)
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=path)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    elif ext == ".blend":
        with bpy.data.libraries.load(path) as (src, dst):
            dst.objects = src.objects
        for obj in dst.objects:
            if obj is not None:
                bpy.context.collection.objects.link(obj)
    else:
        raise SystemExit("Unsupported file type: " + ext)
    new_objects = [o for o in bpy.data.objects if o not in before]
    # One parent for everything, so the whole model can be turned and scaled together.
    root = bpy.data.objects.new("ModelRoot", None)
    bpy.context.collection.objects.link(root)
    for obj in new_objects:
        if obj.parent is None:
            obj.parent = root
    return root


def mesh_objects(root):
    family = set(root.children_recursive)
    family.add(root)
    return [o for o in bpy.data.objects if o.type == "MESH" and o in family]


def world_bounds(root):
    bpy.context.view_layer.update()
    corners = []
    for obj in mesh_objects(root):
        for c in obj.bound_box:
            corners.append(obj.matrix_world @ Vector(c))
    xs, ys, zs = [c.x for c in corners], [c.y for c in corners], [c.z for c in corners]
    return Vector((min(xs), min(ys), min(zs))), Vector((max(xs), max(ys), max(zs)))


def normalize_model(root, target_height):
    """Scales to the target height and puts the feet on the ground at the world origin."""
    low, high = world_bounds(root)
    height = high.z - low.z
    if height <= 0:
        raise SystemExit("Model has no height")
    factor = target_height / height
    root.scale = (root.scale.x * factor, root.scale.y * factor, root.scale.z * factor)
    low, high = world_bounds(root)
    root.location.x -= (low.x + high.x) / 2.0
    root.location.y -= (low.y + high.y) / 2.0
    root.location.z -= low.z


def apply_toon(root, outline_width, outline_color):
    """Cel shading in three tones plus an outline made from a flipped, slightly larger shell."""
    outline = bpy.data.materials.new("Outline")
    outline.use_nodes = True
    outline.use_backface_culling = True
    nodes = outline.node_tree.nodes
    nodes.clear()
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = (*outline_color, 1.0)
    out = nodes.new("ShaderNodeOutputMaterial")
    outline.node_tree.links.new(emission.outputs["Emission"], out.inputs["Surface"])

    for obj in mesh_objects(root):
        for mat in obj.data.materials:
            if mat is None or not mat.use_nodes:
                continue
            tree = mat.node_tree
            bsdf = next((n for n in tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
            output = next((n for n in tree.nodes if n.type == "OUTPUT_MATERIAL"), None)
            if bsdf is None or output is None:
                continue
            base_input = bsdf.inputs["Base Color"]
            diffuse = tree.nodes.new("ShaderNodeBsdfDiffuse")
            diffuse.inputs["Color"].default_value = (1, 1, 1, 1)
            to_rgb = tree.nodes.new("ShaderNodeShaderToRGB")
            ramp = tree.nodes.new("ShaderNodeValToRGB")
            ramp.color_ramp.interpolation = "CONSTANT"
            ramp.color_ramp.elements[0].position = 0.0
            ramp.color_ramp.elements[0].color = (0.45, 0.45, 0.55, 1)  # shadow tone, slightly cool
            ramp.color_ramp.elements[1].position = 0.35
            ramp.color_ramp.elements[1].color = (0.80, 0.80, 0.82, 1)  # middle tone
            extra = ramp.color_ramp.elements.new(0.70)
            extra.color = (1.0, 0.97, 0.90, 1)  # lit tone, slightly warm
            mix = tree.nodes.new("ShaderNodeMix")
            mix.data_type = "RGBA"
            mix.blend_type = "MULTIPLY"
            mix.inputs["Factor"].default_value = 1.0
            emit = tree.nodes.new("ShaderNodeEmission")
            tree.links.new(diffuse.outputs["BSDF"], to_rgb.inputs["Shader"])
            tree.links.new(to_rgb.outputs["Color"], ramp.inputs["Fac"])
            tree.links.new(ramp.outputs["Color"], mix.inputs["A"])
            if base_input.is_linked:
                tree.links.new(base_input.links[0].from_socket, mix.inputs["B"])
            else:
                mix.inputs["B"].default_value = base_input.default_value
            tree.links.new(mix.outputs["Result"], emit.inputs["Color"])
            tree.links.new(emit.outputs["Emission"], output.inputs["Surface"])

        obj.data.materials.append(outline)
        shell = obj.modifiers.new("OutlineShell", "SOLIDIFY")
        shell.thickness = outline_width
        shell.offset = 1.0
        shell.use_flip_normals = True
        shell.use_rim = False
        shell.material_offset = len(obj.data.materials)  # beyond the last slot: uses the outline slot


def setup_render(size):
    scene = bpy.context.scene
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.eevee.taa_render_samples = 32
    world = bpy.data.worlds.new("World")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (1, 1, 1, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
    scene.world = world


def setup_camera_and_light(size):
    scene = bpy.context.scene
    elevation = math.radians(CAMERA_ELEVATION_DEG)
    distance = 30.0
    horizontal = Vector((1.0, 1.0, 0.0)).normalized()
    cam_data = bpy.data.cameras.new("Camera")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = size / PX_PER_UNIT
    cam_data.shift_y = ANCHOR_FROM_TOP - 0.5  # moves the ground point down to 75% of the frame
    cam_data.clip_start = 0.1
    cam_data.clip_end = 100.0
    cam = bpy.data.objects.new("Camera", cam_data)
    cam.location = (horizontal * math.cos(elevation) + Vector((0, 0, math.sin(elevation)))) * distance
    bpy.context.collection.objects.link(cam)
    target = bpy.data.objects.new("CameraTarget", None)
    bpy.context.collection.objects.link(target)
    track = cam.constraints.new("TRACK_TO")
    track.target = target
    track.track_axis = "TRACK_NEGATIVE_Z"
    track.up_axis = "UP_Y"
    scene.camera = cam

    # Screen top-left: left on screen is (1,-1)/sqrt2 in world, toward the camera is (1,1)/sqrt2.
    left = Vector((1.0, -1.0, 0.0)).normalized()
    toward = Vector((1.0, 1.0, 0.0)).normalized()
    to_light = left * 0.5 + toward * 0.3 + Vector((0, 0, 0.8))
    sun_data = bpy.data.lights.new("Sun", "SUN")
    sun_data.energy = 3.0
    sun = bpy.data.objects.new("Sun", sun_data)
    sun.rotation_euler = (-to_light).to_track_quat("-Z", "Y").to_euler()
    bpy.context.collection.objects.link(sun)


def pick_action(root, wanted):
    actions = list(bpy.data.actions)
    if not actions:
        return None
    action = next((a for a in actions if a.name == wanted), actions[0]) if wanted else actions[0]
    for obj in bpy.data.objects:
        if obj.animation_data is None and (obj.type == "ARMATURE" or obj == root):
            obj.animation_data_create()
        if obj.animation_data is not None and obj.type in ("ARMATURE", "EMPTY"):
            try:
                obj.animation_data.action = action
            except TypeError:
                pass
    start, end = (int(action.frame_range[0]), int(action.frame_range[1]))
    bpy.context.scene.frame_start, bpy.context.scene.frame_end = start, end
    return action


def render_all(root, opts):
    scene = bpy.context.scene
    names = DIRECTION_NAMES_8 if opts["directions"] == 8 else DIRECTION_NAMES_4
    step_deg = 360.0 / len(names)
    out_dir = os.path.abspath(os.path.join(opts["out"], opts["name"]))
    os.makedirs(out_dir, exist_ok=True)
    base_z = root.rotation_euler.z
    frames = max(1, opts["frames"])
    start, end = scene.frame_start, scene.frame_end
    for k, direction in enumerate(names):
        theta = math.radians(-45.0 - step_deg * k)
        root.rotation_euler.z = base_z + theta
        for f in range(frames):
            frame = start if frames == 1 else round(start + (end - start) * f / frames)
            scene.frame_set(frame)
            scene.render.filepath = os.path.join(out_dir, "%s_%s_%03d.png" % (opts["name"], direction, f))
            bpy.ops.render.render(write_still=True)
    print("Rendered %d directions x %d frames into %s" % (len(names), frames, out_dir))


def main():
    opts = parse_args()
    reset_scene()
    setup_render(opts["size"])
    if opts["input"] == "demo":
        root = build_demo_figure()
    else:
        root = import_model(os.path.abspath(opts["input"]))
    pick_action(root, opts["action"])
    normalize_model(root, opts["height"])
    apply_toon(root, opts["outline"], opts["outline_color"])
    setup_camera_and_light(opts["size"])
    render_all(root, opts)


main()
