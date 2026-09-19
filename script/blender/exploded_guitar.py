"""Builds the exploded guitar for /lab and bakes it to glTF.

Run headless:

    blender.exe --background --factory-startup --python exploded_guitar.py -- <out.glb>

Every component is a separate object carrying a custom property describing where
it sits when assembled and how far it travels when apart, so the viewer can
drive the explode itself instead of playing back baked geometry. A short
assemble animation is baked too, for the case where the viewer just wants to
play the clip.
"""

import math
import sys
import os

import bpy


# --- helpers ---------------------------------------------------------------


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, color, metallic=0.0, roughness=0.4):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


PARTS = []


def place(obj, name, home, travel, mat=None, rotation=(0, 0, 0)):
    """Name a part, move it home, and record its explode vector."""
    obj.name = name
    obj.location = home
    obj.rotation_euler = rotation

    if mat is not None:
        obj.data.materials.append(mat)

    obj["home"] = list(home)
    obj["travel"] = list(travel)

    PARTS.append(obj)
    return obj


def slab(name, size, home, travel, mat=None, bevel=0.0, segments=3):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    obj = bpy.context.active_object
    obj.scale = (size[0], size[1], size[2])

    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    if bevel > 0:
        modifier = obj.modifiers.new("bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = segments
        bpy.ops.object.modifier_apply(modifier=modifier.name)

    bpy.ops.object.shade_smooth()
    return place(obj, name, home, travel, mat)


def rod(name, radius, length, home, travel, mat=None, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=length, vertices=16)
    obj = bpy.context.active_object
    bpy.ops.object.shade_smooth()
    return place(obj, name, home, travel, mat, rotation)


# --- the instrument --------------------------------------------------------
#
# Axis convention: +Y runs from the bridge (negative) up to the headstock, +Z is
# toward the viewer. Dimensions are in metres, so this is a real guitar's size
# and the viewer only has to frame it, not rescale it.


def build():
    body_mat = material("Body", (0.42, 0.06, 0.04), metallic=0.15, roughness=0.32)
    back_mat = material("BodyBack", (0.14, 0.03, 0.02), roughness=0.6)
    neck_mat = material("Neck", (0.55, 0.33, 0.14), roughness=0.55)
    board_mat = material("Fretboard", (0.09, 0.05, 0.04), roughness=0.7)
    metal_mat = material("Metal", (0.75, 0.76, 0.8), metallic=0.95, roughness=0.2)
    dark_mat = material("Pickup", (0.04, 0.04, 0.05), roughness=0.45)
    guard_mat = material("Guard", (0.95, 0.93, 0.87), roughness=0.4)
    string_mat = material("String", (0.86, 0.85, 0.82), metallic=1.0, roughness=0.15)

    # Body: a beveled slab. The bevel is what stops it reading as a box.
    slab("Body", (0.33, 0.46, 0.05), (0, -0.16, 0), (0, 0, 0), body_mat, bevel=0.055)

    # Cavity cover, the piece you actually unscrew.
    slab("CavityCover", (0.10, 0.11, 0.006), (-0.09, -0.30, -0.028),
         (-0.34, -0.20, -0.36), back_mat)

    # Neck and fretboard.
    slab("Neck", (0.052, 0.36, 0.022), (0, 0.17, 0.008), (0, 0.46, 0.22), neck_mat, bevel=0.006)
    slab("Fretboard", (0.050, 0.345, 0.008), (0, 0.17, 0.023), (0, 0.16, 0.44), board_mat)

    # Frets, spaced by the rule of eighteen.
    scale_length = 0.345
    for i in range(1, 13):
        distance = scale_length * (1 - math.pow(2, -i / 12.0))
        y = 0.345 - distance - 0.005
        slab(f"Fret{i:02d}", (0.050, 0.0016, 0.003), (0, y, 0.030),
             (0, 0.16 + i * 0.015, 0.50), metal_mat)

    slab("Nut", (0.054, 0.006, 0.008), (0, 0.338, 0.028), (0, 0.02, 0.36),
         material("Nut", (0.9, 0.88, 0.82), roughness=0.5))

    # Headstock, angled back slightly the way a real one is.
    slab("Headstock", (0.068, 0.10, 0.018), (0, 0.46, 0.004), (0, 0.62, 0.16),
         neck_mat, bevel=0.006, segments=2)

    # Three tuners a side, posts plus buttons.
    for side in (-1, 1):
        for i in range(3):
            y = 0.425 + i * 0.032
            rod(f"TunerPost{side}{i}", 0.0035, 0.028, (side * 0.036, y, 0),
                (side * 0.34, 0.60 + i * 0.02, 0), metal_mat, rotation=(0, math.pi / 2, 0))
            rod(f"TunerButton{side}{i}", 0.011, 0.005, (side * 0.050, y, 0),
                (side * 0.42, 0.60 + i * 0.02, 0), metal_mat, rotation=(0, math.pi / 2, 0))

    # Pickups with their pole pieces.
    for index, y in enumerate((-0.05, -0.16)):
        slab(f"Pickup{index}", (0.088, 0.022, 0.012), (0.012, y, 0.032),
             (0.20, 0.12 + index * 0.10, 0.30), dark_mat, bevel=0.004, segments=2)

        for pole in range(6):
            x = 0.012 - 0.030 + pole * 0.012
            rod(f"Pole{index}{pole}", 0.0025, 0.014, (x, y, 0.034),
                (0.20 + (x - 0.012) * 1.5, 0.22 + index * 0.10, 0.34), metal_mat,
                rotation=(math.pi / 2, 0, 0))

    slab("Pickguard", (0.13, 0.20, 0.006), (-0.02, -0.13, 0.031),
         (-0.16, -0.02, 0.42), guard_mat, bevel=0.004, segments=2)

    # Bridge and its six saddles.
    slab("Bridge", (0.10, 0.026, 0.016), (0.012, -0.285, 0.029), (0.10, -0.34, 0.28), metal_mat)
    for i in range(6):
        x = 0.012 - 0.028 + i * 0.0112
        slab(f"Saddle{i}", (0.008, 0.012, 0.010), (x, -0.283, 0.032),
             (0.10 + (x - 0.012) * 1.6, -0.40, 0.32), metal_mat)

    # Two tone knobs and a volume, with their shafts.
    for index, (x, y) in enumerate(((0.135, -0.20), (0.115, -0.27), (0.075, -0.33))):
        rod(f"Knob{index}", 0.014, 0.010, (x, y, 0.032),
            (0.30 + index * 0.03, -0.30 + index * 0.02, 0.36), dark_mat,
            rotation=(math.pi / 2, 0, 0))
        rod(f"KnobShaft{index}", 0.004, 0.016, (x, y, 0.028),
            (0.30 + index * 0.03, -0.30 + index * 0.02, 0.40), metal_mat,
            rotation=(math.pi / 2, 0, 0))

    slab("Switch", (0.008, 0.026, 0.012), (-0.048, -0.06, 0.032), (-0.30, 0.04, 0.30), metal_mat)
    rod("Jack", 0.010, 0.026, (0.150, -0.24, 0.0), (0.40, -0.24, 0.0), metal_mat,
        rotation=(0, math.pi / 2, 0))

    # Strings: each runs bridge saddle -> nut -> its own tuner post.
    gauges = (0.0011, 0.0013, 0.0016, 0.0019, 0.0023, 0.0027)
    for i, gauge in enumerate(gauges):
        x = 0.012 - 0.028 + i * 0.0112
        rod(f"String{i}", gauge, 0.63, (x, 0.03, 0.032),
            ((i - 2.5) * 0.06, 0.22, 0.44), string_mat, rotation=(math.pi / 2, 0, 0))


# --- bake ------------------------------------------------------------------


def keyframe():
    """One clip: assembled at rest, apart at frame 40, held to 60."""
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 60

    for obj in PARTS:
        home = obj["home"]
        travel = obj["travel"]
        apart = [home[axis] + travel[axis] for axis in range(3)]

        obj.location = home
        obj.keyframe_insert("location", frame=1)
        obj.keyframe_insert("location", frame=20)

        obj.location = apart
        obj.keyframe_insert("location", frame=40)
        obj.keyframe_insert("location", frame=60)

        obj.location = home

    for action in bpy.data.actions:
        for fcurve in action.fcurves:
            for point in fcurve.keyframe_points:
                point.interpolation = "BEZIER"


def export(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_animations=True,
        export_apply=True,
        use_selection=False,
    )


# --- filming ---------------------------------------------------------------
#
# A viewer supplies its own lights; a render does not. The camera is parented to
# a rotating empty and aimed with a Track To constraint, so the orbit is one
# keyframe on one object rather than a hand-computed path.


def stage():
    scene = bpy.context.scene

    world = bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes["Background"]
    background.inputs[0].default_value = (0.93, 0.90, 0.85, 1.0)
    background.inputs[1].default_value = 1.1

    pivot = bpy.data.objects.new("Pivot", None)
    bpy.context.collection.objects.link(pivot)
    pivot.location = (0, 0.06, 0)

    # Framing. The instrument is a long thin object, so a landscape frame is
    # mostly empty either side of it - which is what made the first render feel
    # tiny despite filling the height. Rolling the camera a quarter turn lays
    # the guitar across the width instead, where there is room for it, and the
    # explode then travels left-to-right the way a diagram should read.
    bpy.ops.object.camera_add(location=(0, -0.62, 2.2))
    camera = bpy.context.active_object
    camera.data.lens = 35
    camera.parent = pivot

    target = bpy.data.objects.new("Target", None)
    bpy.context.collection.objects.link(target)
    target.location = (0, 0.06, 0)

    aim = camera.constraints.new(type="TRACK_TO")
    aim.target = target
    aim.track_axis = "TRACK_NEGATIVE_Z"
    aim.up_axis = "UP_X"

    scene.camera = camera

    # Three lights, roughly a product shot: key, cool fill, warm rim.
    for location, energy, size in (((1.1, -1.0, 1.5), 220, 2.0),
                                   ((-1.5, -0.7, 0.8), 80, 2.6),
                                   ((0.3, 1.3, -1.0), 160, 1.8)):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.active_object
        light.data.energy = energy
        light.data.size = size
        light.rotation_euler = (math.radians(60), 0, math.radians(30))

    return pivot


def render_video(path, poster=None):
    scene = bpy.context.scene
    pivot = stage()

    # Explode over the first half, then turn while apart so the inside stays on
    # screen long enough to actually read.
    scene.frame_end = 120
    pivot.rotation_euler = (0, 0, 0)
    pivot.keyframe_insert("rotation_euler", frame=1)
    pivot.keyframe_insert("rotation_euler", frame=60)

    pivot.rotation_euler = (0, 0, math.radians(150))
    pivot.keyframe_insert("rotation_euler", frame=120)

    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.fps = 30

    os.makedirs(os.path.dirname(path), exist_ok=True)
    scene.render.filepath = path
    scene.render.image_settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format = "MPEG4"
    scene.render.ffmpeg.codec = "H264"
    scene.render.ffmpeg.constant_rate_factor = "HIGH"
    scene.render.ffmpeg.gopsize = 12

    # EEVEE renders far faster, but it needs a GL context that a background
    # process may not be able to create. Cycles on CPU always works.
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
        bpy.ops.render.render(animation=True)
    except Exception as error:
        print(f"EEVEE unavailable ({error}); falling back to Cycles")
        scene.render.engine = "CYCLES"
        scene.cycles.device = "CPU"
        scene.cycles.samples = 24
        scene.cycles.use_denoising = True
        bpy.ops.render.render(animation=True)

    if poster:
        scene.render.image_settings.file_format = "PNG"
        scene.frame_set(60)
        scene.render.filepath = poster
        bpy.ops.render.render(write_still=True)

    print(f"VIDEO {path}")


def main():
    clear_scene()
    build()
    keyframe()

    argv = sys.argv
    argument = argv[argv.index("--") + 1] if "--" in argv else None

    if argument and argument.endswith(".blend"):
        stage()
        bpy.ops.wm.save_as_mainfile(filepath=argument)
        print(f"BLEND {argument}")
    elif argument and argument.endswith(".mp4"):
        poster = argv[argv.index("--") + 2] if len(argv) > argv.index("--") + 2 else None
        render_video(argument, poster)
    else:
        out = argument or "/tmp/exploded_guitar.glb"
        export(out)
        print(f"EXPORTED {out} parts={len(PARTS)}")


main()
