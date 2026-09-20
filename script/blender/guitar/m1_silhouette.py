"""Milestone 1: does it read as a guitar at a glance?

The previous version failed because it was built from cubes. This builds the
body from an actual outline - a smooth spline through the landmark points of a
double-cutaway instrument - then gives it real thickness, a bevel on every rim
edge, and subdivision. Silhouette first: if the shape is wrong, no amount of
material work will save it.

Writes one still so the result can be looked at rather than assumed.
"""

import math
import os
import sys

import bpy
from mathutils import Vector

MM = 0.001


# --- outline ---------------------------------------------------------------
#
# Landmark points of a double-cutaway body, in millimetres, origin at the
# centre. +Y runs toward the neck. The bass-side horn is deliberately longer
# than the treble-side one - that asymmetry is most of what makes a Strat-shaped
# body recognisable rather than a generic blob.

OUTLINE_MM = [
    # Neck pocket shelf - deliberately flat and set back, because it is the
    # surface the neck actually bolts to.
    (-28, 176),
    (-58, 198),
    (-96, 226),      # bass-side horn tip: the long one, where the strap sits
    (-122, 202),
    (-128, 164),
    (-120, 128),
    (-113, 92),
    (-110, 40),      # waist
    (-119, 0),
    (-146, -50),
    (-161, -92),
    (-159, -142),
    (-146, -182),
    (-118, -207),
    (-70, -223),
    (0, -230),       # bottom centre
    (70, -223),
    (118, -207),
    (146, -182),
    (159, -142),
    (161, -92),
    (146, -50),
    (119, 0),
    (110, 40),       # waist
    (113, 92),
    (119, 128),
    (110, 158),
    (96, 180),
    (80, 196),       # treble-side horn tip: shorter
    (56, 190),
    (28, 176),
]


def catmull_rom(points, per_segment=10):
    """Smooth a coarse set of landmark points into a clean outline."""
    ring = []
    count = len(points)

    for index in range(count):
        p0 = points[(index - 1) % count]
        p1 = points[index]
        p2 = points[(index + 1) % count]
        p3 = points[(index + 2) % count]

        for step in range(per_segment):
            t = step / per_segment
            t2 = t * t
            t3 = t2 * t

            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t
                       + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2
                       + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t
                       + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2
                       + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)

            ring.append((x, y))

    return ring


# --- helpers ---------------------------------------------------------------


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def activate(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def apply_modifier(obj, name):
    activate(obj)
    bpy.ops.object.modifier_apply(modifier=name)


def smooth(obj, angle=38):
    activate(obj)
    bpy.ops.object.shade_smooth()
    try:
        bpy.ops.object.shade_auto_smooth(angle=math.radians(angle))
    except Exception:
        pass


# --- materials -------------------------------------------------------------
#
# Flat values are what "plastic" means to a renderer, so every material here
# varies something - roughness, colour, or a bump - across the surface.


def lacquer(name, color, roughness=0.10, peel_scale=260.0, peel=0.010, coat=0.5):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree
    bsdf = nodes.nodes["Principled BSDF"]

    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = roughness

    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = coat
        # A near-mirror coat (0.03) spread a sheet of white specular right across
        # the body and turned a deep red into pale pink. A coat that is slightly
        # rough still reads as lacquer and lets the colour through.
        bsdf.inputs["Coat Roughness"].default_value = 0.09

    # Orange peel: the fine unevenness in a sprayed finish. Without it a gloss
    # reads as moulded plastic.
    noise = nodes.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = peel_scale
    noise.inputs["Detail"].default_value = 2.0
    noise.inputs["Roughness"].default_value = 0.6

    bump = nodes.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = peel
    bump.inputs["Distance"].default_value = 0.0004

    nodes.links.new(noise.outputs["Fac"], bump.inputs["Height"])
    nodes.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    return mat


def wood(name, dark, light, scale=(1.0, 26.0, 1.0), roughness=0.32, bump=0.06):
    """Grain runs along the neck, so the noise is stretched hard in one axis."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree
    bsdf = nodes.nodes["Principled BSDF"]

    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = roughness

    coords = nodes.nodes.new("ShaderNodeTexCoord")
    mapping = nodes.nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = scale

    noise = nodes.nodes.new("ShaderNodeTexNoise")
    # Stretching the noise this hard turned grain into a barcode; real grain is
    # long but soft, so the stretch is gentler and the detail lower.
    noise.inputs["Scale"].default_value = 2.6
    noise.inputs["Detail"].default_value = 6.0
    noise.inputs["Roughness"].default_value = 0.62

    ramp = nodes.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.36
    ramp.color_ramp.elements[0].color = (*dark, 1.0)
    ramp.color_ramp.elements[1].position = 0.64
    ramp.color_ramp.elements[1].color = (*light, 1.0)

    grain_bump = nodes.nodes.new("ShaderNodeBump")
    grain_bump.inputs["Strength"].default_value = bump
    grain_bump.inputs["Distance"].default_value = 0.0006

    nodes.links.new(coords.outputs["Object"], mapping.inputs["Vector"])
    nodes.links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    nodes.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nodes.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    nodes.links.new(noise.outputs["Fac"], grain_bump.inputs["Height"])
    nodes.links.new(grain_bump.outputs["Normal"], bsdf.inputs["Normal"])

    return mat


def metal(name, color=(0.62, 0.63, 0.66), roughness=0.12):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree
    bsdf = nodes.nodes["Principled BSDF"]

    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = roughness

    # Perfect chrome is the most artificial-looking surface there is; break the
    # roughness up so it holds smudges.
    noise = nodes.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 45.0
    noise.inputs["Detail"].default_value = 3.0

    ramp = nodes.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.40
    ramp.color_ramp.elements[0].color = (roughness * 0.5, roughness * 0.5, roughness * 0.5, 1.0)
    ramp.color_ramp.elements[1].position = 0.66
    ramp.color_ramp.elements[1].color = (min(roughness * 3.0, 0.6),) * 3 + (1.0,)

    nodes.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nodes.links.new(ramp.outputs["Color"], bsdf.inputs["Roughness"])

    return mat


def bone():
    mat = bpy.data.materials.new("Nut")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.86, 0.82, 0.72, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.34
    if "Subsurface Weight" in bsdf.inputs:
        bsdf.inputs["Subsurface Weight"].default_value = 0.25
        bsdf.inputs["Subsurface Radius"].default_value = (0.012, 0.008, 0.005)
    return mat


# --- geometry --------------------------------------------------------------


def body(material):
    ring = catmull_rom(OUTLINE_MM, per_segment=10)
    outline = [(x * MM, y * MM) for x, y in ring]

    mesh = bpy.data.meshes.new("Body")
    mesh.from_pydata([(x, y, 0.0) for x, y in outline], [], [list(range(len(outline)))])
    mesh.validate()

    obj = bpy.data.objects.new("Body", mesh)
    bpy.context.collection.objects.link(obj)

    solidify = obj.modifiers.new("Solidify", "SOLIDIFY")
    solidify.thickness = 44 * MM
    solidify.offset = 0.0
    apply_modifier(obj, "Solidify")

    # Hollow it. A guitar body is a box, not a slab: from the LS16 exploded view,
    # a top plate, a back plate and ribs, with air between them. Without the air
    # a sound hole is only a hole - there is nothing inside it to resonate, which
    # is exactly why the first version read as a hole drilled through plastic.
    inner_ring = [(x * MM * 0.93, y * MM * 0.93) for x, y in ring]

    cavity_mesh = bpy.data.meshes.new("Cavity")
    cavity_mesh.from_pydata(
        [(x, y, 0.0) for x, y in inner_ring], [], [list(range(len(inner_ring)))]
    )
    cavity_mesh.validate()

    cavity = bpy.data.objects.new("Cavity", cavity_mesh)
    bpy.context.collection.objects.link(cavity)

    cavity_solid = cavity.modifiers.new("Solidify", "SOLIDIFY")
    # 44 mm outside, 32 mm inside, so the plates end up 6 mm thick.
    cavity_solid.thickness = 32 * MM
    cavity_solid.offset = 0.0
    apply_modifier(cavity, "Solidify")

    hollow = obj.modifiers.new("Hollow", "BOOLEAN")
    hollow.operation = "DIFFERENCE"
    hollow.object = cavity
    apply_modifier(obj, "Hollow")

    bpy.data.objects.remove(cavity, do_unlink=True)

    # Every real edge has a radius. This is the single biggest reason the first
    # attempt looked like plastic.
    # A 9 mm bevel plus two subsurf levels inflated the body into a pillow and
    # rounded the horns away. A real body is a flat slab with a small radius.
    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = 4.5 * MM
    bevel.segments = 3
    bevel.limit_method = "ANGLE"
    bevel.angle_limit = math.radians(30)
    apply_modifier(obj, "Bevel")

    subsurf = obj.modifiers.new("Subsurf", "SUBSURF")
    subsurf.levels = 1
    subsurf.render_levels = 1
    apply_modifier(obj, "Subsurf")

    obj.data.materials.append(material)
    smooth(obj, 40)
    return obj


def sound_hole(body_obj, radius_mm=52):
    """Cut the aperture through the TOP PLATE only, where the guard used to be.

    Two things were wrong before. It went through the whole instrument, top plate
    and back plate both, which is not a sound hole, it is a puncture - a guitar's
    back is solid. And it was placed off to one side to dodge the pickguard, when
    the pickguard is not the thing that matters: the hole goes on the face, in
    the upper bout, and the guard is what moves aside.

    So the guard is removed and the hole takes its place, and the cutter is short
    enough to bite the top plate and stop in the air behind it.
    """
    corners = [body_obj.matrix_world @ Vector(corner) for corner in body_obj.bound_box]
    top = max(c.z for c in corners)
    bottom = min(c.z for c in corners)
    plate = (top - bottom) * 0.18

    def centre_of(name):
        obj = bpy.data.objects.get(name)
        if not obj:
            return None
        corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        return sum(corners, Vector()) / 8

    # Where the guard sat, because that is where the hole was asked to go.
    spot = centre_of("Pickguard") or centre_of("Body")

    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius_mm * MM,
        depth=plate * 2.4,
        vertices=64,
        location=(spot.x, spot.y, top - plate * 0.5),
    )
    cutter = bpy.context.active_object
    cutter.name = "SoundHoleCutter"

    boolean = body_obj.modifiers.new("SoundHole", "BOOLEAN")
    boolean.operation = "DIFFERENCE"
    boolean.object = cutter
    apply_modifier(body_obj, "SoundHole")

    bpy.data.objects.remove(cutter, do_unlink=True)

    print(
        f"SOUNDHOLE r={radius_mm}mm top-plate-only at "
        f"{tuple(round(v, 3) for v in spot)} z={top - plate * 0.5:.3f}"
    )
    return body_obj


def neck(material):
    """Tapered shaft with a heavy bevel - a real neck is a rounded C, not a box."""
    bpy.ops.mesh.primitive_cube_add(size=1)
    obj = bpy.context.active_object
    obj.name = "Neck"

    length = 0.470
    obj.scale = (0.052, length, 0.022)

    activate(obj)
    bpy.ops.object.transform_apply(scale=True)

    # Taper: pull the nut end in and thin it, the way a neck narrows toward the
    # headstock and thickens at the heel.
    mesh = obj.data
    for vertex in mesh.vertices:
        taper = 1.0 - 0.22 * ((vertex.co.y / length) + 0.5)
        vertex.co.x *= taper
        vertex.co.z *= 0.86 + 0.28 * (1.0 - taper)

    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = 0.011
    bevel.segments = 6
    bevel.limit_method = "ANGLE"
    bevel.angle_limit = math.radians(25)
    apply_modifier(obj, "Bevel")

    subsurf = obj.modifiers.new("Subsurf", "SUBSURF")
    subsurf.levels = 2
    apply_modifier(obj, "Subsurf")

    # The neck starts inside the pocket, not at the body's outer edge, or it
    # reads as a plank laid next to a body rather than joined to one.
    obj.location = (0.0, 0.150 + length / 2, 0.006)
    obj.data.materials.append(material)
    smooth(obj, 40)
    return obj


def fretboard(material):
    bpy.ops.mesh.primitive_cube_add(size=1)
    obj = bpy.context.active_object
    obj.name = "Fretboard"
    obj.scale = (0.055, 0.462, 0.007)

    activate(obj)
    bpy.ops.object.transform_apply(scale=True)

    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = 0.004
    bevel.segments = 4
    apply_modifier(obj, "Bevel")

    # Spans the body joint at 150 mm to the nut at 608 mm, so the 22nd fret
    # lands exactly on the joint the way it does on a real 648 mm scale.
    obj.location = (0.0, 0.379, 0.024)
    obj.data.materials.append(material)
    smooth(obj, 45)
    return obj


def nut(material):
    bpy.ops.mesh.primitive_cube_add(size=1)
    obj = bpy.context.active_object
    obj.name = "Nut"
    obj.scale = (0.056, 0.006, 0.010)

    activate(obj)
    bpy.ops.object.transform_apply(scale=True)

    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = 0.0012
    bevel.segments = 3
    apply_modifier(obj, "Bevel")

    obj.location = (0.0, 0.608, 0.030)
    obj.data.materials.append(material)
    smooth(obj, 45)
    return obj


def ground():
    bpy.ops.mesh.primitive_plane_add(size=6)
    plane = bpy.context.active_object
    plane.name = "Ground"

    mat = bpy.data.materials.new("GroundMat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.055, 0.055, 0.062, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.48
    plane.data.materials.append(mat)

    plane.location = (0, 0.3, -0.024)
    return plane


def hardware():
    """Everything bolted to the body.

    A shaped slab is not a guitar. The guard, pickups, bridge and knobs are most
    of what the eye uses to classify the object in the first glance.
    """
    made = []

    guard = bpy.data.materials.new("Pickguard")
    guard.use_nodes = True
    guard_bsdf = guard.node_tree.nodes["Principled BSDF"]
    guard_bsdf.inputs["Base Color"].default_value = (0.90, 0.88, 0.80, 1.0)
    guard_bsdf.inputs["Roughness"].default_value = 0.26

    plastic = bpy.data.materials.new("Plastic")
    plastic.use_nodes = True
    plastic_bsdf = plastic.node_tree.nodes["Principled BSDF"]
    plastic_bsdf.inputs["Base Color"].default_value = (0.018, 0.018, 0.022, 1.0)
    plastic_bsdf.inputs["Roughness"].default_value = 0.30

    chrome = metal("Chrome", (0.70, 0.71, 0.74), roughness=0.10)

    def plate(name, size, home, mat, bevel=0.0025, segments=4):
        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = size

        activate(obj)
        bpy.ops.object.transform_apply(scale=True)

        modifier = obj.modifiers.new("Bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = segments
        apply_modifier(obj, "Bevel")

        obj.location = home
        obj.data.materials.append(mat)
        obj.select_set(False)
        made.append(obj)
        return obj

    def post(name, radius, height, home, mat, rotation=(0, 0, 0), vertices=24):
        bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=height, vertices=vertices)
        obj = bpy.context.active_object
        obj.name = name
        obj.location = home
        obj.rotation_euler = rotation
        obj.data.materials.append(mat)
        activate(obj)
        bpy.ops.object.shade_smooth()
        obj.select_set(False)
        made.append(obj)
        return obj

    top = 0.0235

    # Guard, spanning the treble side from the pocket to the bridge.
    # A 16 mm bevel on a 3 mm plate is wider than the plate is thick, which
    # bulged the guard into a blob. Keep the radius well under the thickness.
    plate("Pickguard", (0.108, 0.150, 0.0016), (0.012, 0.045, top), guard, bevel=0.006, segments=4)

    # Three single coils: bobbin and six pole pieces each.
    for index, y in enumerate((0.118, 0.048, -0.028)):
        plate(f"Pickup{index}", (0.045, 0.010, 0.0055), (0.016, y, top + 0.005),
              plastic, bevel=0.0018, segments=3)

        for pole in range(6):
            x = 0.016 - 0.032 + pole * 0.0128
            post(f"Pole{index}{pole}", 0.0021, 0.007, (x, y, top + 0.010), chrome)

    # Bridge: plate, six saddles, six intonation screws.
    plate("Bridge", (0.050, 0.013, 0.006), (0.016, -0.112, top + 0.005), chrome, bevel=0.002, segments=3)

    for i in range(6):
        x = 0.016 - 0.031 + i * 0.0124
        plate(f"Saddle{i}", (0.0055, 0.0085, 0.0045), (x, -0.110, top + 0.010),
              chrome, bevel=0.0012, segments=3)
        post(f"Intonation{i}", 0.0012, 0.012, (x, -0.126, top + 0.006), chrome,
             rotation=(math.pi / 2, 0, 0), vertices=12)

    # Three knobs with their bright caps.
    for index, (x, y) in enumerate(((0.108, -0.058), (0.096, -0.112), (0.064, -0.150))):
        post(f"Knob{index}", 0.0155, 0.011, (x, y, top + 0.007), plastic)
        post(f"KnobCap{index}", 0.006, 0.0125, (x, y, top + 0.008), chrome)

    plate("JackPlate", (0.016, 0.013, 0.0016), (0.058, -0.196, top), chrome, bevel=0.004, segments=4)

    for name, home in (("StrapTop", (-0.098, 0.214, 0.0)), ("StrapBottom", (0.0, -0.226, 0.0))):
        post(name, 0.0055, 0.010, home, chrome)

    return made


def frets(mat):
    """Twenty-two frets, placed by the rule of eighteen from the nut."""
    made = []
    nut_y = 0.608
    scale_length = 0.648

    for number in range(1, 23):
        y = nut_y - scale_length * (1 - math.pow(2, -number / 12.0))

        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.active_object
        obj.name = f"Fret{number:02d}"
        obj.scale = (0.054, 0.0013, 0.0022)

        activate(obj)
        bpy.ops.object.transform_apply(scale=True)

        modifier = obj.modifiers.new("Bevel", "BEVEL")
        modifier.width = 0.0007
        modifier.segments = 3
        apply_modifier(obj, "Bevel")

        obj.location = (0.0, y, 0.0315)
        obj.data.materials.append(mat)
        activate(obj)
        bpy.ops.object.shade_smooth()
        obj.select_set(False)
        made.append(obj)

    return made


def strings(mat):
    """Six strings at real gauges, from each saddle to near its tuner post."""
    made = []
    gauges = (0.00045, 0.00055, 0.00070, 0.00085, 0.00105, 0.00130)

    for index, radius in enumerate(gauges):
        x = 0.016 - 0.031 + index * 0.0124

        start = Vector((x, -0.108, 0.0335))
        end = Vector((x * 0.55, 0.614, 0.0400))
        direction = end - start

        bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=direction.length, vertices=12)
        obj = bpy.context.active_object
        obj.name = f"String{index}"
        obj.location = (start + end) / 2
        obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
        obj.data.materials.append(mat)

        activate(obj)
        bpy.ops.object.shade_smooth()
        obj.select_set(False)
        made.append(obj)

    return made


def headstock(mat, chrome_mat):
    """The headstock and its six tuners.

    Without this the neck just stops, which is the most obvious tell that
    something is missing.
    """
    made = []

    bpy.ops.mesh.primitive_cube_add(size=1)
    head = bpy.context.active_object
    head.name = "Headstock"
    head.scale = (0.041, 0.086, 0.011)

    activate(head)
    bpy.ops.object.transform_apply(scale=True)

    # Narrow toward the tip rather than staying a rectangle.
    for vertex in head.data.vertices:
        if vertex.co.y > 0:
            vertex.co.x *= 0.76

    modifier = head.modifiers.new("Bevel", "BEVEL")
    modifier.width = 0.005
    modifier.segments = 4
    apply_modifier(head, "Bevel")

    # The neck ends at y = 0.620 (0.150 + 0.470) and this was sitting at 0.700,
    # which left a 37 mm air gap between the stick and the head. Static, at rest,
    # before anything moves - the neck and the headstock were never joined in the
    # first place. 0.658 puts the head's base at 0.615, a few millimetres inside
    # the neck's end.
    head.location = (0.0, 0.658, 0.020)
    # Pitched back a few degrees, the way a real one is.
    head.rotation_euler = (math.radians(-6), 0, 0)
    head.data.materials.append(mat)

    activate(head)
    bpy.ops.object.shade_smooth()
    head.select_set(False)
    made.append(head)

    # Three tuners a side: post through the headstock, button on the outside.
    # Absolute, so they move with the head above - 0.042 less than they were,
    # or they would have hung off the end of a headstock that had moved under
    # them.
    for side in (-1, 1):
        for index in range(3):
            y = 0.620 + index * 0.028

            bpy.ops.mesh.primitive_cylinder_add(radius=0.0034, depth=0.030, vertices=16)
            post = bpy.context.active_object
            post.name = f"TunerPost{side}{index}"
            post.location = (side * 0.021, y, 0.026)
            post.rotation_euler = (0, math.pi / 2, 0)
            post.data.materials.append(chrome_mat)
            activate(post)
            bpy.ops.object.shade_smooth()
            post.select_set(False)
            made.append(post)

            bpy.ops.mesh.primitive_cylinder_add(radius=0.0095, depth=0.005, vertices=20)
            button = bpy.context.active_object
            button.name = f"TunerButton{side}{index}"
            button.location = (side * 0.040, y, 0.026)
            button.rotation_euler = (0, math.pi / 2, 0)
            button.data.materials.append(chrome_mat)
            activate(button)
            bpy.ops.object.shade_smooth()
            button.select_set(False)
            made.append(button)

    return made


# --- stage -----------------------------------------------------------------


PIVOT = None


def animate(parts, rest_frame=1, explode_frame=90, end_frame=170):
    """Key every part from assembled to apart, and orbit while it opens.

    Parts travel outward from the instrument's centre, scaled by what they are:
    strings lift as a set, frets fan together, the body stays put because it is
    the thing everything else is measured against.
    """
    scene = bpy.context.scene
    scene.frame_start = rest_frame
    scene.frame_end = end_frame

    corners = []
    for obj in parts:
        for corner in obj.bound_box:
            corners.append(obj.matrix_world @ Vector(corner))

    low = Vector((min(c[0] for c in corners), min(c[1] for c in corners), min(c[2] for c in corners)))
    high = Vector((max(c[0] for c in corners), max(c[1] for c in corners), max(c[2] for c in corners)))
    centre = (low + high) / 2

    weights = {
        "Body": 0.0, "Fretboard": 0.55, "Neck": 0.65, "Headstock": 0.7, "Nut": 0.8,
        "Fret": 0.9, "Pickup": 0.95, "Pole": 0.9, "Saddle": 0.95, "Intonation": 0.9,
        "Bridge": 1.05, "Tuner": 1.15, "JackPlate": 1.2, "Strap": 1.15,
        "KnobCap": 1.25, "Knob": 1.3, "Pickguard": 1.4, "String": 1.55,
    }

    for obj in parts:
        weight = next((value for key, value in weights.items() if obj.name.startswith(key)), 0.9)
        if weight == 0.0:
            continue

        home = obj.location.copy()
        direction = home - centre
        if direction.length < 1e-6:
            direction = Vector((0, 0, 1))
        direction.normalize()

        apart = home + direction * (0.16 * weight)

        obj.location = home
        obj.keyframe_insert("location", frame=rest_frame)
        obj.keyframe_insert("location", frame=40)

        obj.location = apart
        obj.keyframe_insert("location", frame=explode_frame)
        obj.keyframe_insert("location", frame=end_frame)

        obj.location = home

    # Ease so parts settle into place instead of drifting to a stop.
    for action in bpy.data.actions:
        for fcurve in action.fcurves:
            for point in fcurve.keyframe_points:
                point.interpolation = "BEZIER"
                point.easing = "EASE_IN_OUT"

    # Orbit the rig while it is open, so the inside stays on screen.
    if PIVOT is not None:
        PIVOT.rotation_euler = (0, 0, 0)
        PIVOT.keyframe_insert("rotation_euler", frame=explode_frame)
        PIVOT.rotation_euler = (0, 0, math.radians(140))
        PIVOT.keyframe_insert("rotation_euler", frame=end_frame)

    print(f"ANIMATED parts={len(parts)} frames={rest_frame}-{end_frame}")


def grade():
    """Colour grading - the difference between a render and a photograph.

    Three things: a punchy view transform, a split tone (warm highlights, cool
    shadows), and bloom on the speculars so chrome and lacquer glare the way
    polished surfaces actually do.
    """
    scene = bpy.context.scene

    for look in ("AgX - Punchy", "AgX - Medium High Contrast", "None"):
        try:
            scene.view_settings.look = look
            print(f"LOOK {look}")
            break
        except TypeError:
            continue

    scene.view_settings.exposure = -0.15

    scene.use_nodes = True
    tree = scene.node_tree
    tree.nodes.clear()

    layers = tree.nodes.new("CompositorNodeRLayers")

    balance = tree.nodes.new("CompositorNodeColorBalance")
    balance.correction_method = "LIFT_GAMMA_GAIN"
    balance.lift = (0.985, 0.995, 1.020)      # shadows cool
    balance.gamma = (1.000, 0.995, 0.972)
    balance.gain = (1.065, 1.000, 0.935)      # highlights warm

    glare = tree.nodes.new("CompositorNodeGlare")
    try:
        glare.glare_type = "BLOOM"
    except TypeError:
        glare.glare_type = "FOG_GLOW"
    glare.quality = "HIGH"
    glare.threshold = 0.82
    # Bloom at -0.74 plus a warm gain washed the whole frame into sepia. Bloom
    # should catch the chrome and the lacquer, not the background.
    glare.mix = -0.88

    # A lens-distortion node sat here for edge chromatic aberration. Its socket
    # names differ between 4.x builds - "Distort" as an input does not exist and
    # neither does a "distortion" property - and it crashed the whole grade
    # twice. Not worth two render cycles for a decorative effect; the grade is
    # the split tone and the bloom.
    composite = tree.nodes.new("CompositorNodeComposite")

    tree.links.new(layers.outputs["Image"], balance.inputs["Image"])
    tree.links.new(balance.outputs["Image"], glare.inputs["Image"])
    tree.links.new(glare.outputs["Image"], composite.inputs["Image"])

    print("GRADED split-tone + bloom + dispersion")


PIVOT_HOLDER = None


def frame_camera(camera, objects, margin=1.16, direction=(0.52, -0.70, 0.40)):
    """Point the camera at the subject and back it off until it fits.

    Guessing a camera distance is what cropped the body in the last two
    attempts. This measures the parts, takes the tighter of the two frustum
    half-angles, and solves for the distance that contains the bounding sphere.
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
    camera.location = centre + offset

    aim = centre - camera.location
    camera.rotation_euler = aim.to_track_quat("-Z", "Y").to_euler()

    # Focus on the subject, not on a hard-coded point.
    camera.data.dof.focus_distance = aim.length

    print(f"FRAMED radius={radius:.3f}m distance={distance:.3f}m centre={tuple(round(v, 3) for v in centre)}")
    return centre


def stage():
    scene = bpy.context.scene

    world = bpy.data.worlds.new("Studio")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes["Background"]
    # A dark, cool room rather than a light grey one. The old 0.30 grey world put
    # as much light on the instrument as the key did, so the sweep and the subject
    # sat at the same value and the red had nowhere to go.
    background.inputs[0].default_value = (0.055, 0.060, 0.075, 1.0)
    background.inputs[1].default_value = 0.5

    def area(location, energy, size, color=(1, 1, 1)):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.active_object
        light.data.energy = energy
        light.data.size = size
        light.data.color = color
        direction = Vector((0, 0.28, 0)) - Vector(location)
        light.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        return light

    # Energies cut hard from the first attempt (420/220/180/150 W), which blew
    # the finish out to white and made a deep red read as pale pink. Trimmed
    # again once the world stopped contributing a third of the light.
    area((1.5, 0.9, 1.9), 90, 2.2)
    area((-1.8, -0.4, 1.1), 34, 2.6, (0.86, 0.90, 1.0))
    area((0.2, -1.9, 1.5), 50, 1.8, (1.0, 0.94, 0.86))
    area((-0.4, 1.8, 0.9), 38, 1.6, (1.0, 0.97, 0.92))

    bpy.ops.object.camera_add(location=(0.62, -0.72, 0.44))
    camera = bpy.context.active_object
    camera.data.lens = 85

    # The camera hangs off an empty at the origin so the orbit is one keyframe
    # on one object rather than a hand-computed path.
    global PIVOT
    pivot = bpy.data.objects.new("CameraPivot", None)
    bpy.context.collection.objects.link(pivot)
    camera.parent = pivot
    PIVOT = pivot

    camera.data.dof.use_dof = True
    # f/4 at this distance left only a thin band in focus. A product shot of a
    # guitar is shot stopped well down.
    camera.data.dof.aperture_fstop = 11.0
    scene.camera = camera

    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    # 128 with denoise holds up for checking shape and light, and keeps the
    # iteration loop short - 220 samples cost 3m32s per still on this CPU.
    scene.cycles.samples = 128
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 8

    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.film_transparent = False

    try:
        scene.view_settings.view_transform = "AgX"
    except TypeError:
        scene.view_settings.view_transform = "Filmic"

    # Look names differ between versions, and a bad one raises rather than
    # falling back - which is how the first attempt produced no still at all.
    for look in ("AgX - Medium High Contrast", "AgX - Punchy", "None"):
        try:
            scene.view_settings.look = look
            break
        except TypeError:
            continue

    return camera


def render(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    scene = bpy.context.scene
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print(f"STILL {path}")


def bake_colour():
    """Bake each material's procedural colour down to a bitmap.

    This is the only way the grain survives the trip. A node graph cannot be
    exported, so the choice is between a flat colour and a baked image, and a
    maple neck with no figure in it is what makes a good mesh look like a toy.
    Cycles does the evaluating here, once, and the exporter ships the pixels.
    """
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 1

    # Colour only: direct and indirect light would bake the studio's lighting
    # into the instrument's own texture, and the browser lights it itself.
    scene.render.bake.use_pass_direct = False
    scene.render.bake.use_pass_indirect = False
    scene.render.bake.use_pass_color = True
    scene.render.bake.margin = 8

    for mat in bpy.data.materials:
        if not mat.use_nodes:
            continue

        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if not bsdf:
            continue

        users = [
            obj for obj in bpy.data.objects
            if obj.type == "MESH" and any(slot.material == mat for slot in obj.material_slots)
        ]
        if not users:
            continue

        image = bpy.data.images.new(f"{mat.name}_baked", 1024, 1024)
        node = mat.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = image
        mat.node_tree.nodes.active = node
        node.select = True

        # Always unwrap, even when a UV layer is already there. Solidify and
        # bevel generate one, and it is degenerate: every island collapsed to a
        # point, so the bake writes a single texel and the whole surface samples
        # black. Checking "has UVs?" is not the same as "has usable UVs".
        for obj in users:
            activate(obj)
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
            bpy.ops.object.mode_set(mode="OBJECT")

        bpy.ops.object.select_all(action="DESELECT")
        for obj in users:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = users[0]

        bpy.ops.object.bake(type="DIFFUSE")

        for link in list(bsdf.inputs["Base Color"].links):
            mat.node_tree.links.remove(link)
        mat.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])

        print(f"BAKED {mat.name} onto {len(users)} objects")


def flatten_materials():
    """Reduce every material to what glTF can actually carry.

    The still render gets its wood from noise into a colour ramp, and its lacquer
    from a coat layer. glTF carries none of that: a procedural graph arrives in
    the browser unevaluated, so the neck and the board came out the colour of
    paper while the body, which is a flat colour underneath, was fine.

    Name-matched rather than read off the graph, because the graph is exactly
    what cannot be exported.
    """
    tints = [
        ("body", (0.52, 0.045, 0.035), 0.0, 0.28),
        ("maple", (0.74, 0.55, 0.30), 0.0, 0.36),
        ("rosewood", (0.14, 0.065, 0.05), 0.0, 0.50),
        ("hardware", (0.72, 0.73, 0.76), 0.9, 0.22),
        ("fret", (0.78, 0.79, 0.81), 0.9, 0.30),
        ("string", (0.86, 0.86, 0.88), 1.0, 0.28),
        ("bone", (0.93, 0.91, 0.84), 0.0, 0.45),
        ("nut", (0.93, 0.91, 0.84), 0.0, 0.45),
    ]

    for mat in bpy.data.materials:
        if not mat.use_nodes:
            continue

        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if not bsdf:
            continue

        tint = next((entry for entry in tints if entry[0] in mat.name.lower()), None)
        _colour, metallic, roughness = tint[1:] if tint else ((0.5, 0.5, 0.5), 0.0, 0.4)

        # Base Color is deliberately untouched: it now carries a baked image,
        # which is the one form of colour the exporter can actually ship. Only
        # the scalars need pinning, and the normal input has to go because the
        # bump graph feeding it is still a graph.
        for socket in ("Metallic", "Roughness", "Normal"):
            if socket in bsdf.inputs:
                for link in list(bsdf.inputs[socket].links):
                    mat.node_tree.links.remove(link)

        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness


def export_glb(path, parts):
    """The web scene wants the parts and nothing else.

    No lights, no camera, no ground and no keyframes: the browser does its own
    lighting and drives the explode from its own travel rules. What it needs is
    the geometry, under names it can group by - body, pickguard, fret, string.

    This exists because the GLB used to come from exploded_guitar.py, which
    builds the instrument out of beveled cubes and cylinders. That is the boxy
    model with no neck pocket, and no amount of lighting fixes a body that is a
    rounded rectangle.
    """
    for obj in list(bpy.data.objects):
        # The guard is dropped because the sound hole took its place. A solid
        # body has a pickguard and no hole; an acoustic has a hole and no
        # pickguard on the face. Keeping both is the hybrid that read wrong.
        if obj.type in {"LIGHT", "CAMERA"} or obj.name in {"Ground", "Pickguard"}:
            bpy.data.objects.remove(obj, do_unlink=True)

    bake_colour()
    flatten_materials()

    if os.path.dirname(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)

    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_apply=True,
        export_animations=False,
        use_selection=False,
    )

    print(f"GLB {path} parts={len(parts)}")


def main():
    argv = sys.argv
    out = argv[argv.index("--") + 1] if "--" in argv else "D:/Program Apps/AI Pop Music/Blender/renders/m1-body.png"
    exporting = out.endswith(".glb")

    clear()

    red = lacquer("BodyRed", (0.30, 0.030, 0.020), roughness=0.09)
    maple = wood("Maple", (0.28, 0.16, 0.07), (0.60, 0.40, 0.20), scale=(1.0, 9.0, 1.0))
    rosewood = wood("Rosewood", (0.028, 0.014, 0.011), (0.070, 0.034, 0.026),
                    scale=(1.0, 12.0, 1.0), roughness=0.42, bump=0.05)

    parts = [ body(red), neck(maple), fretboard(rosewood), nut(bone()) ]

    chrome = metal("Hardware", (0.70, 0.71, 0.74), roughness=0.10)
    parts += headstock(maple, chrome)
    parts += hardware()

    # After the guard exists, because the hole is placed to avoid it.
    sound_hole(parts[0])
    parts += frets(metal("FretWire", (0.74, 0.75, 0.77), roughness=0.16))
    parts += strings(metal("StringSteel", (0.80, 0.80, 0.82), roughness=0.20))

    ground()

    if exporting:
        export_glb(out, parts)
        return

    camera = stage()
    # Margin covers the exploded spread, not the assembled instrument - framing
    # on the resting state let every part fly out of shot. 1.25 then cropped the
    # body's own corner, so this keeps a little air around the rest pose too.
    frame_camera(camera, parts, margin=1.42)

    animate(parts)
    grade()

    if out.endswith(".blend"):
        # Save the scene instead of a picture, so the rig can be inspected and
        # scrubbed by hand in the GUI.
        bpy.ops.wm.save_as_mainfile(filepath=out)
        print(f"BLEND {out} parts={len(parts)}")
    elif out.endswith(".mp4"):
        scene = bpy.context.scene
        scene.render.resolution_x = 1280
        scene.render.resolution_y = 720
        scene.render.fps = 30
        # Deliberately lighter than the stills - a sequence at 128 samples
        # would run for hours on this CPU.
        scene.cycles.samples = 64
        scene.render.image_settings.file_format = "FFMPEG"
        scene.render.ffmpeg.format = "MPEG4"
        scene.render.ffmpeg.codec = "H264"
        scene.render.ffmpeg.constant_rate_factor = "HIGH"
        os.makedirs(os.path.dirname(out), exist_ok=True)
        scene.render.filepath = out
        bpy.ops.render.render(animation=True)
        print(f"VIDEO {out}")
    else:
        # A still of the open state, so the animation and the grade are both
        # visible in one frame.
        bpy.context.scene.frame_set(90)
        render(out)


main()
