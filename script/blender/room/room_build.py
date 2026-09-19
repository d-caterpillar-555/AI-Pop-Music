"""(b) The room - build it, light it, render it, export it.

Nine stations arranged as a band sets up: a kit at the back, the amps behind
the guitars, the guitars on stands down one side, keys on the other, the vocal
mic out front with the pedalboard at its feet.

Run headless:

    blender.exe --background --python room_build.py -- D:/apm-shots/b-room.png
    blender.exe --background --python room_build.py -- D:/apm-shots/b-room.mp4
    blender.exe --background --python room_build.py -- "<project>/public/models/band_room.glb"

The output extension picks the mode. Blender exits 0 even when the script raises,
so nothing here trusts the exit code - the caller checks that the file exists.
"""

import math
import os
import sys
import time

import bpy
from mathutils import Vector

try:
    HERE = os.path.dirname(os.path.abspath(__file__))
except NameError:  # pragma: no cover - only when run without __file__
    HERE = os.path.dirname(os.path.abspath(sys.argv[sys.argv.index("--python") + 1]))
sys.path.insert(0, HERE)

import guitars  # noqa: E402
import instruments  # noqa: E402
import kit  # noqa: E402

MM = kit.MM

# The room, in metres. Walls only on the back and the left, because the camera
# looks in from the open front-right corner and a box would put a wall between
# the lens and the band.
ROOM = {"half_x": 3.5, "half_y": 2.6, "height": 3.1}

# Blender buffers Python's stdout when it is redirected, so a build that takes
# minutes reports nothing until it is over. Every phase writes a line here as it
# goes, which is the only way to see where the time actually went.
PROGRESS = "D:/apm-shots/room-progress.log"
STARTED = time.time()


def mark(message):
    line = f"{time.time() - STARTED:7.1f}s {message}"
    print(line, flush=True)
    try:
        with open(PROGRESS, "a", encoding="utf-8") as handle:
            handle.write(line + "\n")
    except OSError:
        pass


# --- palette ----------------------------------------------------------------


def emissive(name, color, strength, roughness=0.4):
    mat = kit.solid(name, color, roughness)
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    if "Emission Color" in bsdf.inputs:
        bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return mat


def plaster():
    """Painted plaster: rough, and not quite flat, or the walls read as cardboard."""
    mat, nodes, bsdf = kit._principled("Wall")
    bsdf.inputs["Base Color"].default_value = (0.150, 0.142, 0.138, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.88
    bsdf.inputs["Metallic"].default_value = 0.0

    noise = nodes.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 22.0
    noise.inputs["Detail"].default_value = 5.0
    noise.inputs["Roughness"].default_value = 0.6

    bump = nodes.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.18
    bump.inputs["Distance"].default_value = 0.0022

    nodes.links.new(noise.outputs["Fac"], bump.inputs["Height"])
    nodes.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def palette():
    return {
        "chrome": kit.metal("Chrome", (0.70, 0.71, 0.74), roughness=0.10),
        "silver": kit.metal("Nickel", (0.58, 0.585, 0.60), roughness=0.16),
        "black": kit.solid("BlackPlastic", (0.020, 0.020, 0.024), 0.30),
        "metal_dark": kit.metal("BlackMetal", (0.05, 0.05, 0.055), roughness=0.30, smudge=90.0),
        "wrap": kit.flake("DrumWrap", (0.185, 0.030, 0.030), base_roughness=0.22),
        "snare_shell": kit.flake("SnareShell", (0.40, 0.39, 0.37), base_roughness=0.30),
        "head_clear": kit.solid("HeadClear", (0.78, 0.78, 0.76), 0.34),
        "head_coat": kit.solid("HeadCoated", (0.88, 0.87, 0.83), 0.55),
        "cymbal": kit.lather("Cymbal", (0.66, 0.52, 0.26), roughness=0.22),
        "plastic_dark": kit.solid("PlasticDark", (0.045, 0.045, 0.050), 0.36),
        "key_white": kit.solid("KeyWhite", (0.90, 0.89, 0.86), 0.28),
        "key_black": kit.solid("KeyBlack", (0.030, 0.030, 0.034), 0.26),
        "screen": emissive("Screen", (0.35, 0.60, 0.85), 2.2, roughness=0.2),
        "accent": kit.lacquer("AccentRed", (0.42, 0.045, 0.040), roughness=0.14),
        "led": emissive("Led", (1.0, 0.35, 0.20), 4.0, roughness=0.3),
        "wood_end": kit.wood("DarkWood", (0.055, 0.030, 0.020), (0.150, 0.085, 0.055),
                             scale=(1.0, 18.0, 1.0), roughness=0.40),
        "brass": kit.metal("Brass", (0.62, 0.49, 0.24), roughness=0.24, smudge=120.0),
        "tolex": kit.weave("Tolex", (0.035, 0.035, 0.038), roughness=0.62, grid=760.0, depth=0.0009),
        "grill": kit.weave("GrillCloth", (0.30, 0.28, 0.25), roughness=0.80, grid=430.0, depth=0.0016),
        "grille": kit.metal("MicGrille", (0.30, 0.31, 0.33), roughness=0.42, smudge=220.0),
        "speaker": kit.solid("Speaker", (0.030, 0.028, 0.028), 0.60),
        "pedal_a": kit.lacquer("PedalA", (0.05, 0.25, 0.30), roughness=0.22),
        "pedal_b": kit.lacquer("PedalB", (0.34, 0.10, 0.05), roughness=0.24),
    }


# --- the room ---------------------------------------------------------------


def shell(M):
    parts = []

    floor = kit.box("Floor", (ROOM["half_x"] * 2, ROOM["half_y"] * 2, 0.10),
                    (0, 0, -0.05), kit.wood("FloorWood", (0.075, 0.048, 0.030), (0.22, 0.145, 0.090),
                                            scale=(1.0, 1.0, 22.0), roughness=0.42, bump=0.04),
                    bevel_width=0.0)
    parts.append(floor)

    back = kit.box("BackWall", (ROOM["half_x"] * 2, 0.12, ROOM["height"]),
                   (0, ROOM["half_y"] + 0.06, ROOM["height"] / 2), M["wall"],
                   bevel_width=0.0)
    parts.append(back)

    left = kit.box("LeftWall", (0.12, ROOM["half_y"] * 2, ROOM["height"]),
                   (-ROOM["half_x"] - 0.06, 0, ROOM["height"] / 2), M["wall"],
                   bevel_width=0.0)
    parts.append(left)

    for name, size, home in (
        ("SkirtingBack", (ROOM["half_x"] * 2, 0.030, 0.140), (0, ROOM["half_y"] - 0.015, 0.070)),
        ("SkirtingLeft", (0.030, ROOM["half_y"] * 2, 0.140), (-ROOM["half_x"] + 0.015, 0, 0.070)),
    ):
        parts.append(kit.box(name, size, home, M["wood_end"], bevel_width=0.004, segments=2))

    # The window: an emissive panel, which is what actually lights the room from
    # the left and gives every instrument a cool rim.
    window_x = -ROOM["half_x"] + 0.02
    parts.append(kit.box("WindowGlass", (0.020, 1.70, 1.25), (window_x, -0.55, 1.72),
                         emissive("Daylight", (0.85, 0.92, 1.05), 2.6, roughness=0.35),
                         bevel_width=0.0))
    parts.append(kit.box("WindowFrameTop", (0.060, 1.78, 0.070), (window_x, -0.55, 2.38),
                         M["wood_end"], bevel_width=0.004, segments=2))
    parts.append(kit.box("WindowFrameBottom", (0.060, 1.78, 0.070), (window_x, -0.55, 1.06),
                         M["wood_end"], bevel_width=0.004, segments=2))
    for side in (-1, 1):
        parts.append(kit.box(f"WindowFrameSide{side}", (0.060, 0.070, 1.39),
                             (window_x, -0.55 + side * 0.855, 1.72), M["wood_end"],
                             bevel_width=0.004, segments=2))
    parts.append(kit.box("WindowMullion", (0.050, 0.045, 1.25), (window_x, -0.55, 1.72),
                         M["wood_end"], bevel_width=0.003, segments=2))

    parts.append(kit.box("Rug", (2.90, 1.90, 0.016), (0.30, 1.30, 0.008),
                         kit.weave("Rug", (0.135, 0.105, 0.095), roughness=0.86,
                                   grid=95.0, depth=0.0040),
                         bevel_width=0.006, segments=2))

    cable = kit.ring("FloorCable", 0.24, 0.007, (1.55, -1.35, 0.010), M["black"],
                     rotation=(math.pi / 2, 0, 0), major_segments=28, minor_segments=8)
    parts.append(cable)
    parts.append(kit.cyl("CableRun", 0.006, 1.70, (1.30, -0.55, 0.008), M["black"],
                         vertices=10, rotation=(math.radians(90), 0, math.radians(28))))

    return parts


# --- stations ---------------------------------------------------------------


def seat(parts, empty, angle_deg, yaw_deg=0.0, clearance=0.0):
    """Stand an instrument up and drop it onto the floor.

    The guitar is modelled lying on its back with the origin on the face, so
    standing it up is a rotation about X and then however far down the lowest
    corner lands. Computing that from the real bounds beats guessing a lift.
    """
    empty.rotation_euler = (math.radians(angle_deg), 0, math.radians(yaw_deg))
    bpy.context.view_layer.update()

    lowest = None
    for part in parts:
        for corner in part.bound_box:
            world = part.matrix_world @ Vector(corner)
            if lowest is None or world.z < lowest:
                lowest = world.z

    empty.location.z = -(lowest or 0.0) + clearance
    bpy.context.view_layer.update()
    return empty


def guitar_station(key, parts, home, yaw, lean=76.0):
    """A guitar leaning in a stand: two stations, because the stand does not lean.

    Both stations sit at the same spot on the floor. The guitar leans; the stand
    stands up, which is the whole reason they cannot share one node.
    """
    guitar = kit.station(key, home=(home[0], home[1], 0))
    kit.adopt([p for p in parts if "_Stand" not in p.name], guitar)
    seat([p for p in parts if "_Stand" not in p.name], guitar, lean, yaw, clearance=0.004)

    stand = kit.station(f"{key}_Stand", home=(home[0], home[1], 0), rotation=(0, 0, math.radians(yaw)))
    kit.adopt([p for p in parts if "_Stand" in p.name], stand)
    return guitar, stand


def build():
    kit.clear()
    M = palette()
    M["wall"] = plaster()

    stations = []
    timings = []

    def timed(name, function):
        mark(f"start {name}")
        started = time.time()
        result = function()
        seconds = time.time() - started
        timings.append((name, seconds))
        mark(f"done  {name} ({seconds:.0f}s)")
        return result

    room = kit.station("Room")
    kit.adopt(timed("room", lambda: shell(M)), room)
    stations.append(room)

    # 01 Drums, centre back, on the rug. Every builder works around its own
    # origin, so the station is the placement.
    stations.append(timed("drums", lambda: kit.adopt(
        instruments.drums("Drums", M), kit.station("Drums", home=(0.30, 1.30)))))

    # 02-05 The guitars, down the left wall and one on the right for balance.
    specs = (
        ("Elec1", (-2.45, 0.35), 28.0),
        ("Elec2", (-2.60, -0.85), 16.0),
        ("Bass", (-2.30, -1.95), 6.0),
    )

    finishes = {
        "Elec1": (M["accent"], kit.solid("GuardCream", (0.86, 0.83, 0.72), 0.26),
                  kit.wood("Rosewood1", (0.028, 0.014, 0.011), (0.070, 0.034, 0.026),
                           scale=(1.0, 12.0, 1.0), roughness=0.42, bump=0.05)),
        "Elec2": (kit.lacquer("BlondeBody", (0.46, 0.335, 0.145), roughness=0.11),
                  kit.solid("GuardBlack", (0.030, 0.030, 0.034), 0.28),
                  kit.wood("Maple1", (0.30, 0.20, 0.115), (0.56, 0.42, 0.26),
                           scale=(1.0, 9.0, 1.0), roughness=0.36)),
        "Bass": (kit.lacquer("BassBody", (0.115, 0.045, 0.022), roughness=0.10),
                 kit.solid("GuardTort", (0.155, 0.055, 0.030), 0.24),
                 kit.wood("Rosewood2", (0.024, 0.013, 0.010), (0.060, 0.030, 0.024),
                          scale=(1.0, 12.0, 1.0), roughness=0.44, bump=0.05)),
    }

    for key, home, yaw in specs:
        finish, guard, board = finishes[key]
        string_count = 4 if key == "Bass" else 6
        parts = timed(key, lambda key=key, finish=finish, guard=guard, board=board,
                      string_count=string_count: guitars.electric(
            key, finish, guard, M["chrome"], board,
            kit.wood("MapleNeck", (0.29, 0.185, 0.100), (0.62, 0.455, 0.275),
                     scale=(1.0, 9.0, 1.0), roughness=0.34),
            M["silver"], kit.metal("SteelString", (0.78, 0.78, 0.80), roughness=0.20),
            M["black"],
            outline=guitars.OUTLINE_BASS if key == "Bass" else guitars.OUTLINE_ELECTRIC,
            scale_length=0.864 if key == "Bass" else 0.648,
            thickness=0.048 if key == "Bass" else 0.044,
            strings=string_count,
        ))
        stations += guitar_station(key, parts, home, yaw)

    acoustic_parts = timed("Acoustic", lambda: guitars.acoustic(
        "Acoustic",
        top_mat=kit.wood("Spruce", (0.34, 0.235, 0.135), (0.72, 0.545, 0.330),
                         scale=(1.0, 7.0, 1.0), roughness=0.30, bump=0.035),
        back_mat=kit.wood("AcousticBack", (0.070, 0.030, 0.020), (0.190, 0.090, 0.055),
                          scale=(1.0, 20.0, 1.0), roughness=0.38),
        chrome=M["chrome"], board_mat=kit.wood("Ebony", (0.012, 0.011, 0.012),
                                               (0.032, 0.028, 0.028),
                                               scale=(1.0, 14.0, 1.0), roughness=0.46),
        neck_mat=kit.wood("Mahogany", (0.090, 0.040, 0.024), (0.230, 0.115, 0.062),
                          scale=(1.0, 10.0, 1.0), roughness=0.40),
        fret_mat=M["silver"],
        string_mat=kit.metal("BronzeString", (0.72, 0.58, 0.34), roughness=0.28),
        bridge_mat=M["wood_end"],
    ))
    stations += guitar_station("Acoustic", acoustic_parts, (2.75, -0.05), -22.0)

    # 06-09 Keys against the open side, the amp in the back corner, the vocal
    # mic out front, the pedalboard at the singer's feet.
    stations.append(timed("keys", lambda: kit.adopt(
        instruments.keys("Keys", M),
        kit.station("Keys", home=(2.35, 1.35), rotation=(0, 0, math.radians(-34))))))

    stations.append(timed("amp", lambda: kit.adopt(
        instruments.amp_stack("Amp", M),
        kit.station("Amp", home=(-2.55, 1.85), rotation=(0, 0, math.radians(34))))))

    stations.append(timed("mic", lambda: kit.adopt(
        instruments.mic("Mic", M),
        kit.station("Mic", home=(0.55, -0.75), rotation=(0, 0, math.radians(165))))))

    stations.append(timed("board", lambda: kit.adopt(
        instruments.pedalboard("Board", M),
        kit.station("Board", home=(-0.75, -1.55), rotation=(0, 0, math.radians(12))))))

    furniture = kit.station("Furniture")
    kit.adopt(timed("props", lambda: props(M)), furniture)
    stations.append(furniture)

    for name, seconds in timings:
        print(f"TIMING {name:10s} {seconds:6.1f}s")

    return stations


def props(M):
    """The clutter that says a band actually uses this room.

    An empty floor reads as a showroom. A case against the wall, a stool and a
    couple of cable runs cost four objects and change what the room is.
    """
    parts = []

    case = kit.box("GuitarCase", (1.12, 0.42, 0.155), (-2.85, 1.15, 0.078),
                   M["tolex"], bevel_width=0.008, segments=3,
                   rotation=(0, 0, math.radians(96)))
    parts.append(case)
    parts.append(kit.box("GuitarCaseLid", (1.12, 0.42, 0.014), (-2.85, 1.15, 0.163),
                         M["tolex"], bevel_width=0.004, segments=2,
                         rotation=(0, 0, math.radians(96))))
    for index, y in enumerate((0.90, 1.40)):
        parts.append(kit.box(f"GuitarCaseLatch{index}", (0.030, 0.055, 0.020),
                             (-2.79, y, 0.163), M["chrome"], bevel_width=0.003, segments=2))

    parts.append(kit.cyl("StoolSeat", 0.165, 0.055, (-1.15, 0.55, 0.60), M["black"], vertices=26))
    parts.append(kit.cyl("StoolPost", 0.020, 0.58, (-1.15, 0.55, 0.30), M["chrome"], vertices=14))
    for index in range(3):
        angle = (index / 3) * math.tau + 0.9
        parts.append(kit.cyl(f"StoolLeg{index}", 0.009, 0.30,
                             (-1.15 + math.cos(angle) * 0.11, 0.55 + math.sin(angle) * 0.11, 0.10),
                             M["chrome"], vertices=10,
                             rotation=(math.radians(72) * math.sin(angle),
                                       math.radians(72) * math.cos(angle), 0)))

    parts.append(kit.ring("SpareCoil", 0.20, 0.008, (1.30, -1.85, 0.012), M["black"],
                          rotation=(math.pi / 2, 0, 0), major_segments=26, minor_segments=8))
    parts.append(kit.ring("SpareCoil2", 0.15, 0.007, (1.62, -1.62, 0.010), M["black"],
                          rotation=(math.pi / 2, 0, 0), major_segments=24, minor_segments=8))

    return parts


# --- stage ------------------------------------------------------------------

PIVOT = None


def stage():
    scene = bpy.context.scene

    world = bpy.data.worlds.new("Room")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes["Background"]
    background.inputs[0].default_value = (0.048, 0.055, 0.070, 1.0)
    background.inputs[1].default_value = 0.25

    def area(name, location, energy, size, color=(1, 1, 1), aim=(0, 0.8, 0.4)):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.active_object
        light.name = name
        light.data.energy = energy
        light.data.size = size
        light.data.color = color
        direction = Vector(aim) - Vector(location)
        light.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        return light

    # The window does the key; everything else is accent. The first pass ran at
    # 420/180/150/90/120 W with the exposure up half a stop, which blew the walls
    # to white and turned a lit room into an empty box.
    area("Key", (-2.2, -0.55, 1.75), 165, 2.2, (0.86, 0.92, 1.05), aim=(0.4, 1.4, 0.5))
    area("PracticalBack", (0.9, 2.1, 2.55), 95, 1.4, (1.0, 0.84, 0.66), aim=(0.2, 1.2, 0.4))
    area("PracticalLeft", (-1.9, 1.5, 2.50), 70, 1.2, (1.0, 0.88, 0.72), aim=(-2.2, 1.7, 0.6))
    area("Fill", (2.6, -1.9, 1.35), 48, 2.0, (0.92, 0.94, 1.0), aim=(0.2, 0.8, 0.6))
    area("Rim", (1.6, 0.4, 2.30), 62, 1.0, (0.98, 0.90, 0.86), aim=(0.3, 0.6, 0.2))

    bpy.ops.object.camera_add(location=(6.0, -7.0, 3.2))
    camera = bpy.context.active_object
    camera.name = "Camera"
    camera.data.lens = 42

    global PIVOT
    pivot = bpy.data.objects.new("CameraPivot", None)
    bpy.context.collection.objects.link(pivot)
    pivot.location = (0.0, 0.6, 0.85)
    camera.parent = pivot
    PIVOT = pivot

    camera.data.dof.use_dof = True
    camera.data.dof.aperture_fstop = 8.0
    scene.camera = camera

    scene.render.engine = "CYCLES"
    scene.cycles.samples = 96
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 4
    scene.cycles.caustics_reflective = False
    scene.cycles.caustics_refractive = False
    # At low sample counts the adaptive sampler's default threshold spends most
    # of the budget polishing pixels nobody will look at.
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.adaptive_threshold = 0.05
    scene.cycles.device = choose_device(scene)

    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.film_transparent = False

    try:
        scene.view_settings.view_transform = "AgX"
    except TypeError:
        scene.view_settings.view_transform = "Filmic"

    for look in ("AgX - Medium High Contrast", "AgX - Punchy", "None"):
        try:
            scene.view_settings.look = look
            break
        except TypeError:
            continue

    scene.view_settings.exposure = 0.0
    return camera


def choose_device(scene):
    """Render on the GPU when there is one.

    The previous session rendered this project on the CPU at roughly three
    minutes a frame, which makes iteration impossible. The card in this machine
    is a 6 GB RTX 4050, so OptiX first, CUDA second, CPU as the floor. A room
    that overflows 6 GB will raise mid-render and fall back in render().
    """
    preferences = bpy.context.preferences.addons.get("cycles")
    if preferences is None:
        print("DEVICE cpu (no cycles addon preferences)")
        return "CPU"

    for compute_type in ("OPTIX", "CUDA"):
        try:
            preferences.preferences.compute_device_type = compute_type
            preferences.preferences.get_devices()
        except Exception as error:
            print(f"DEVICE {compute_type} unavailable: {error}")
            continue

        for device in preferences.preferences.devices:
            device.use = device.type == compute_type
            print(f"DEVICE {device.name} type={device.type} use={device.use}")

        if any(device.use for device in preferences.preferences.devices):
            print(f"DEVICE selected {compute_type}")
            return "GPU"

    print("DEVICE cpu (no GPU devices)")
    return "CPU"


def grade():
    """Split tone and bloom - the same reasoning as the guitar, tuned brighter.

    A lit room has a much bigger dynamic range than a product still, so the
    bloom threshold sits higher and the gain is gentler.
    """
    scene = bpy.context.scene
    scene.use_nodes = True
    tree = scene.node_tree
    tree.nodes.clear()

    layers = tree.nodes.new("CompositorNodeRLayers")

    balance = tree.nodes.new("CompositorNodeColorBalance")
    balance.correction_method = "LIFT_GAMMA_GAIN"
    balance.lift = (0.975, 0.990, 1.020)
    balance.gamma = (1.000, 0.996, 0.976)
    balance.gain = (1.050, 1.005, 0.955)

    glare = tree.nodes.new("CompositorNodeGlare")
    try:
        glare.glare_type = "BLOOM"
    except TypeError:
        glare.glare_type = "FOG_GLOW"
    glare.quality = "HIGH"
    glare.threshold = 0.92
    glare.mix = -0.90

    composite = tree.nodes.new("CompositorNodeComposite")

    tree.links.new(layers.outputs["Image"], balance.inputs["Image"])
    tree.links.new(balance.outputs["Image"], glare.inputs["Image"])
    tree.links.new(glare.outputs["Image"], composite.inputs["Image"])
    print("GRADED split-tone + bloom")


def frame_camera(camera, objects, margin=1.08, direction=(0.72, -1.0, 0.42)):
    """Solve the camera distance from the subject's real bounds.

    Guessing the distance is what cropped the guitar twice; the same solve is
    what keeps a 7 m room in frame from a lens that is not a fisheye.
    """
    corners = []
    for obj in objects:
        for corner in obj.bound_box:
            corners.append(obj.matrix_world @ Vector(corner))

    low = Vector((min(c[0] for c in corners), min(c[1] for c in corners), min(c[2] for c in corners)))
    high = Vector((max(c[0] for c in corners), max(c[1] for c in corners), max(c[2] for c in corners)))
    centre = (low + high) / 2
    radius = (high - low).length / 2

    scene = bpy.context.scene
    aspect = scene.render.resolution_x / scene.render.resolution_y
    sensor = camera.data.sensor_width

    half_vertical = math.atan((sensor / 2) / camera.data.lens)
    half_horizontal = math.atan((sensor * aspect / 2) / camera.data.lens)
    half_angle = min(half_vertical, half_horizontal)

    distance = (radius * margin) / math.sin(half_angle)
    offset = Vector(direction).normalized() * distance
    world_position = centre + offset

    # The camera hangs off the pivot, so its location is an offset from it -
    # writing a world position straight into location would double the pivot's
    # own translation. The pivot is unrotated at this point, so a subtraction is
    # the whole conversion and the aim vector stays a world vector.
    if camera.parent is not None:
        camera.location = world_position - camera.parent.location
    else:
        camera.location = world_position

    aim = centre - world_position
    camera.rotation_euler = aim.to_track_quat("-Z", "Y").to_euler()
    camera.data.dof.focus_distance = aim.length

    print(f"FRAMED radius={radius:.2f}m distance={distance:.2f}m centre={tuple(round(v, 2) for v in centre)}")
    return centre


# --- output -----------------------------------------------------------------


def render(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    scene = bpy.context.scene
    scene.cycles.samples = samples
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = path

    # A 6 GB card is not guaranteed to hold a room full of subdivided
    # instruments, and an out-of-memory render raises rather than degrading.
    try:
        bpy.ops.render.render(write_still=True)
    except Exception as error:
        print(f"RENDER FAILED on {scene.cycles.device}: {error}")
        scene.cycles.device = "CPU"
        bpy.ops.render.render(write_still=True)

    print(f"STILL {path} device={scene.cycles.device}")


def fast_probe():
    """Count every modifier still live in the room, by type and owner.

    A build that leaves hidden modifiers on every object ships a scene that is
    slow to save, slow to load and slow to export. This prints the bill instead
    of assuming there is none.
    """
    modifier_counts = {}
    owners = 0
    for obj in bpy.data.objects:
        for modifier in obj.modifiers:
            if isinstance(modifier, bpy.types.BevelModifier):
                key = f"Bevel s{modifier.segments} w{modifier.width:.4f}"
            else:
                key = modifier.type
            modifier_counts[key] = modifier_counts.get(key, 0) + 1
            owners += 1

    if not modifier_counts:
        print("MODIFIERS none - the room is baked")
    else:
        for key in sorted(modifier_counts):
            print(f"MODIFIER {modifier_counts[key]:4d} x {key}")
        print(f"MODIFIERS on {owners} objects")

    print(f"PROBE objects={len(bpy.data.objects)} meshes={len(bpy.data.meshes)}")
    print(f"PROBE faces={sum(len(mesh.polygons) for mesh in bpy.data.meshes)}")


def probe():
    """Print what was actually built, so placement is checked rather than assumed."""
    print(f"PROBE objects={len(bpy.data.objects)} meshes={len(bpy.data.meshes)}")
    print(f"PROBE faces={sum(len(mesh.polygons) for mesh in bpy.data.meshes)}")

    fast_probe()
    return

    stations = [obj for obj in bpy.data.objects if obj.type == "EMPTY"]
    for station in sorted(stations, key=lambda item: item.name):
        children = [obj for obj in bpy.data.objects if obj.parent == station]
        if not children:
            print(f"STATION {station.name:16s} children=0")
            continue

        lows, highs = [], []
        for child in children:
            for corner in child.bound_box:
                world = child.matrix_world @ Vector(corner)
                lows.append(world)
                highs.append(world)

        low = Vector((min(v.x for v in lows), min(v.y for v in lows), min(v.z for v in lows)))
        high = Vector((max(v.x for v in highs), max(v.y for v in highs), max(v.z for v in highs)))
        print(
            f"STATION {station.name:16s} children={len(children):4d} "
            f"x=[{low.x:6.2f},{high.x:6.2f}] y=[{low.y:6.2f},{high.y:6.2f}] z=[{low.z:6.2f},{high.z:6.2f}]"
        )


def render_video(path, samples, frames, size):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.render.fps = 30
    scene.cycles.samples = samples
    scene.frame_start = 1
    scene.frame_end = frames
    scene.render.image_settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format = "MPEG4"
    scene.render.ffmpeg.codec = "H264"
    scene.render.ffmpeg.constant_rate_factor = "HIGH"
    scene.render.filepath = path

    if PIVOT is not None:
        # A slow drift across the open side of the room. The band does not move;
        # the camera does, which is what makes a still room feel inhabited.
        PIVOT.rotation_euler = (0, 0, 0)
        PIVOT.keyframe_insert("rotation_euler", frame=1)
        PIVOT.rotation_euler = (0, 0, math.radians(26))
        PIVOT.keyframe_insert("rotation_euler", frame=frames)

        for action in bpy.data.actions:
            for fcurve in action.fcurves:
                for point in fcurve.keyframe_points:
                    point.interpolation = "BEZIER"
                    point.easing = "EASE_IN_OUT"

    bpy.ops.render.render(animation=True)
    print(f"VIDEO {path} frames={frames}")


def export_glb(path):
    """Export the room for the browser.

    Cameras and lights are left out - the page lights the scene itself, and an
    exported camera would fight the viewer's own.
    """
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_apply=True,
        export_cameras=False,
        export_lights=False,
        export_yup=True,
    )
    size = os.path.getsize(path) if os.path.exists(path) else 0
    print(f"GLB {path} bytes={size}")


def main():
    open(PROGRESS, "w").close()
    mark("build start")
    build()
    mark(f"built objects={len(bpy.data.objects)}")

    if "probe" in sys.argv:
        probe()
        return

    argv = sys.argv
    args = argv[argv.index("--") + 1:] if "--" in argv else []
    out = args[0] if args else "D:/apm-shots/b-room.png"

    if "geometry" in sys.argv:
        # The build costs eight minutes and the lighting does not, so the two are
        # separable: save the bare room, then stage it from room_stage.py as many
        # times as it takes.
        mark(f"saving geometry to {out}")
        bpy.ops.wm.save_as_mainfile(filepath=out)
        mark(f"saved geometry objects={len(bpy.data.objects)}")
        return

    camera = stage()
    mark("staged")

    parts = [obj for obj in bpy.data.objects if obj.type == "MESH" and obj.name not in
             ("Floor", "BackWall", "LeftWall", "WindowGlass", "Rug")]
    frame_camera(camera, parts)
    grade()
    mark("framed and graded")

    samples = 96
    size = None
    for arg in args[1:]:
        if arg.startswith("samples="):
            samples = int(arg.split("=", 1)[1])
        elif arg.startswith("size="):
            width, height = arg.split("=", 1)[1].lower().split("x")
            size = (int(width), int(height))

    if size is not None:
        bpy.context.scene.render.resolution_x, bpy.context.scene.render.resolution_y = size

    if out.endswith(".glb"):
        mark("exporting glb")
        export_glb(out)
    elif out.endswith(".blend"):
        bpy.ops.wm.save_as_mainfile(filepath=out)
        mark(f"saved {out} objects={len(bpy.data.objects)}")
    elif out.endswith(".mp4"):
        render_video(out, samples, 120, (1024, 576))
    else:
        mark(f"rendering {out} samples={samples}")
        render(out, samples)

    mark("done")


if __name__ == "__main__":
    main()
