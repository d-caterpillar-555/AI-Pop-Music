"""(b) The room - the guitars.

Ported from ../guitar/m1_silhouette.py, which is the version that finally read as
an instrument. The difference is that this builds them in a local frame with a
name prefix, so four of them can stand in the same room without colliding and
the web viewer can find each one.

Local frame, shared by every guitar here: the top face points at +Z, the
instrument runs along +Y from the bottom of the body to the headstock, and the
origin sits on the face of the body. The caller stands it up.
"""

import math

import bpy

import kit
from kit import MM, box, cyl, metal, ring, sphere

# --- outlines ---------------------------------------------------------------

# Landmark points of a double-cutaway body in millimetres, origin at the centre.
# The bass-side horn is deliberately longer than the treble-side one; that
# asymmetry is most of what makes the shape recognisable rather than a blob.
OUTLINE_ELECTRIC = [
    (-28, 176), (-58, 198), (-96, 226), (-122, 202), (-128, 164), (-120, 128),
    (-113, 92), (-110, 40), (-119, 0), (-146, -50), (-161, -92), (-159, -142),
    (-146, -182), (-118, -207), (-70, -223), (0, -230), (70, -223), (118, -207),
    (146, -182), (159, -142), (161, -92), (146, -50), (119, 0), (110, 40),
    (113, 92), (119, 128), (110, 158), (96, 180), (80, 196), (56, 190), (28, 176),
]

# The same instrument scaled up and stretched: a bass body is a bigger slab with
# a longer upper horn to reach the 12th fret, which is what keeps it on a strap.
OUTLINE_BASS = [
    (-30, 190), (-64, 214), (-116, 252), (-146, 230), (-152, 186), (-142, 146),
    (-133, 104), (-128, 46), (-136, 0), (-166, -56), (-181, -102), (-178, -156),
    (-162, -198), (-130, -224), (-76, -240), (0, -247), (76, -240), (130, -224),
    (162, -198), (178, -156), (181, -102), (166, -56), (136, 0), (128, 46),
    (133, 104), (138, 138), (126, 170), (108, 192), (88, 206), (62, 200), (30, 190),
]

# A dreadnought: one wide lower bout, a pinched waist, a narrower upper bout.
# Nothing like the solid body - this outline carries the whole instrument.
OUTLINE_ACOUSTIC = [
    (-52, 250), (-84, 262), (-118, 254), (-136, 226), (-140, 180), (-132, 132),
    (-118, 86), (-112, 40), (-122, 0), (-150, -52), (-172, -110), (-180, -166),
    (-166, -214), (-132, -244), (-76, -262), (0, -268), (76, -262), (132, -244),
    (166, -214), (180, -166), (172, -110), (150, -52), (122, 0), (112, 40),
    (118, 86), (132, 132), (140, 180), (136, 226), (118, 254), (84, 262), (52, 250),
]


def catmull_rom(points, per_segment=10):
    """Smooth a coarse set of landmark points into a clean outline."""
    ring_points = []
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

            ring_points.append((x, y))

    return ring_points


# --- shared parts -----------------------------------------------------------


def _slab(prefix, name, outline, thickness, mat, bevel_width, subsurf=1):
    ring_points = catmull_rom(outline, per_segment=10)
    points = [(x * MM, y * MM) for x, y in ring_points]

    mesh = bpy.data.meshes.new(f"{prefix}_{name}")
    mesh.from_pydata([(x, y, 0.0) for x, y in points], [], [list(range(len(points)))])
    mesh.validate()

    obj = bpy.data.objects.new(f"{prefix}_{name}", mesh)
    bpy.context.collection.objects.link(obj)

    solidify = obj.modifiers.new("Solidify", "SOLIDIFY")
    solidify.thickness = thickness
    solidify.offset = 0.0
    solidify.show_viewport = False

    kit.bevel(obj, bevel_width, 3, angle=20)
    for modifier in obj.modifiers:
        modifier.show_viewport = False

    if subsurf:
        modifier = obj.modifiers.new("Subsurf", "SUBSURF")
        modifier.levels = subsurf
        modifier.render_levels = subsurf
        modifier.show_viewport = False

    # One evaluation for everything stacked above - solidify, bevel and subsurf
    # together - instead of one operator call per modifier.
    kit.apply_modifiers(obj)

    obj.data.materials.append(mat)
    kit.smooth(obj, 40)
    return obj


def _tapered_box(prefix, name, size, taper, mat, bevel_width, location, subsurf=2, rotation=(0, 0, 0)):
    """A box that narrows toward one end - necks, headstocks, piano keys' mouldings.

    Raw vertices, like kit's box: the operator plus transform-apply plus bevel was
    the slowest shape in the room, and the subsurf is baked at build time so
    nothing it touches has to be re-evaluated later.
    """
    half = [dimension / 2 for dimension in size]
    corners = [(
        -half[0] if x else half[0],
        -half[1] if y else half[1],
        -half[2] if z else half[2],
    ) for x, y, z in (
        (0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0),
        (0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1),
    )]

    mesh = bpy.data.meshes.new(f"{prefix}_{name}")
    mesh.from_pydata(
        corners, [],
        [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (2, 6, 7, 3), (1, 5, 6, 2), (0, 3, 7, 4)],
    )
    mesh.validate()

    length = size[1]
    for vertex in mesh.vertices:
        factor = 1.0 - taper * ((vertex.co.y / length) + 0.5)
        vertex.co.x *= factor
        vertex.co.z *= 0.86 + 0.28 * (1.0 - factor)

    obj = bpy.data.objects.new(f"{prefix}_{name}", mesh)
    bpy.context.collection.objects.link(obj)

    kit.bevel(obj, bevel_width, 4, angle=25)

    if subsurf:
        # The subsurf is baked at build time, so nothing it produces has to be
        # re-evaluated by everything built afterwards.
        modifier = obj.modifiers.new("Subsurf", "SUBSURF")
        modifier.levels = subsurf
        modifier.render_levels = subsurf
        modifier.show_viewport = False
        kit.apply_modifiers(obj)

    obj.location = location
    obj.rotation_euler = rotation
    obj.data.materials.append(mat)
    kit.smooth(obj, 40)
    return obj


def _frets(prefix, mat, nut_y, scale_length, width, count=22):
    """Frets placed by the rule of eighteen from the nut - the real spacing."""
    made = []

    for number in range(1, count + 1):
        y = nut_y - scale_length * (1 - math.pow(2, -number / 12.0))
        made.append(box(
            f"{prefix}_Fret{number:02d}", (width, 0.0013, 0.0022), (0.0, y, 0.0315),
            mat, bevel_width=0.0007, segments=3,
        ))

    for fret in made:
        kit.smooth(fret, 40)
    return made


def _strings(prefix, mat, gauges, spacing, start, end, x_centre=0.0, head_scale=0.55):
    """Six strings as tilted cylinders, raw rather than operator-built.

    A string is a cylinder between two points, which is exactly what kit's
    cylinder is plus a rotation - so each string is built from the same vertex
    layout with a matrix applied before it is linked.
    """
    from mathutils import Matrix, Vector

    made = []
    count = len(gauges)

    for index, radius in enumerate(gauges):
        x = x_centre - spacing * (count - 1) / 2 + index * spacing

        start_point = Vector((x, start[1], start[2]))
        end_point = Vector((x * head_scale, end[1], end[2]))
        direction = end_point - start_point

        part = cyl(
            "scratch", radius, direction.length, (0, 0, 0), mat,
            vertices=8, cap_bevel=0.0,
        )

        part.location = (start_point + end_point) / 2
        part.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
        part.name = f"{prefix}_String{index}"
        part.data.name = f"{prefix}_String{index}"
        made.append(part)

    for string in made:
        kit.smooth(string, 40)
    return made


def _inline_tuners(prefix, chrome, first_y, pitch, head_z=0.026, posts=6):
    """Six in a row down one side - the Fender arrangement."""
    made = []

    for index in range(posts):
        y = first_y + index * pitch
        made.append(cyl(f"{prefix}_TunerPost{index}", 0.0034, 0.030, (0.021, y, head_z),
                        chrome, vertices=16, rotation=(0, math.pi / 2, 0)))
        made.append(cyl(f"{prefix}_TunerButton{index}", 0.0095, 0.005, (0.040, y, head_z),
                        chrome, vertices=20, rotation=(0, math.pi / 2, 0)))
        made.append(cyl(f"{prefix}_TunerFerrule{index}", 0.0055, 0.002, (0.0215, y, head_z + 0.011),
                        chrome, vertices=16))

    return made


def _split_tuners(prefix, chrome, ys, head_z=0.026, drops=(0.0, -0.012, -0.024)):
    """Three a side, staggered - the Gibson and acoustic arrangement."""
    made = []

    for index, y in enumerate(ys):
        for side in (-1, 1):
            made.append(cyl(f"{prefix}_TunerPost{side}{index}", 0.0034, 0.030,
                            (side * 0.020, y + drops[index] * 0.5, head_z),
                            chrome, vertices=16, rotation=(0, math.pi / 2, 0)))
            made.append(cyl(f"{prefix}_TunerButton{side}{index}", 0.0095, 0.005,
                            (side * 0.039, y + drops[index] * 0.5, head_z),
                            chrome, vertices=20, rotation=(0, math.pi / 2, 0)))

    return made


def _guitar_stand(prefix, chrome, dark, home=(0, 0, 0), height=0.42):
    """A stand, because an instrument leaning on nothing is an instrument floating."""
    made = []
    x = home[0]
    y = home[1]

    for side in (-1, 1):
        made.append(cyl(f"{prefix}_StandLeg{side}", 0.014, 0.028,
                        (x + side * 0.165, y - 0.06, 0.014), dark, vertices=20,
                        rotation=(0, 0, 0)))
        made.append(cyl(f"{prefix}_StandTube{side}", 0.0115, height,
                        (x + side * 0.150, y - 0.05, height / 2), chrome, vertices=18))
        made.append(cyl(f"{prefix}_StandArm{side}", 0.011, 0.070,
                        (x + side * 0.150, y - 0.02, height * 0.86),
                        chrome, vertices=18, rotation=(math.radians(64), 0, 0)))

    made.append(cyl(f"{prefix}_StandYoke", 0.0115, 0.30, (x, y - 0.075, height * 0.52),
                    chrome, vertices=18, rotation=(0, math.pi / 2, 0)))

    # The back rest is what the instrument actually leans on, so it sits behind
    # the body and far enough up to be doing something.
    made.append(cyl(f"{prefix}_StandRest", 0.011, 0.26, (x, y + 0.115, height * 1.02),
                    chrome, vertices=18, rotation=(0, math.pi / 2, 0)))
    made.append(cyl(f"{prefix}_StandRestStem", 0.010, 0.20, (x, y + 0.075, height * 0.82),
                    chrome, vertices=14, rotation=(math.radians(-38), 0, 0)))

    return made


# --- instruments ------------------------------------------------------------


def electric(prefix, finish, guard_mat, chrome, board_mat, neck_mat, fret_mat,
             string_mat, knob_mat, outline=OUTLINE_ELECTRIC, scale_length=0.648,
             gauges=(0.00045, 0.00055, 0.00070, 0.00085, 0.00105, 0.00130),
             thickness=0.044, strings=6):
    """A solid body, in the local frame described at the top of the file."""
    made = []

    made.append(_slab(prefix, "Body", outline, thickness, finish, 4.5 * MM))

    top = 0.0235
    board_width = 0.055 if strings == 6 else 0.062
    nut_y = 0.608 if strings == 6 else 0.640
    neck_length = 0.470 if strings == 6 else 0.560

    made.append(_tapered_box(
        prefix, "Neck", (0.052 if strings == 6 else 0.060, neck_length, 0.022), 0.22,
        neck_mat, 0.011, (0.0, 0.150 + neck_length / 2, 0.006),
    ))
    made.append(_tapered_box(
        prefix, "Fretboard", (board_width, 0.462 if strings == 6 else 0.550, 0.007), 0.04,
        board_mat, 0.004, (0.0, 0.379 if strings == 6 else 0.402, 0.024), subsurf=1,
    ))
    made.append(box(f"{prefix}_Nut", (board_width + 0.002, 0.006, 0.010),
                    (0.0, nut_y, 0.030), kit.bone(f"{prefix}_NutMat"),
                    bevel_width=0.0012, segments=3))

    head_y = 0.700 if strings == 6 else 0.745
    head = box(f"{prefix}_Headstock", (0.041, 0.086, 0.011), (0.0, head_y, 0.020),
               neck_mat, bevel_width=0.005, segments=4,
               rotation=(math.radians(-6), 0, 0))
    for vertex in head.data.vertices:
        if vertex.co.y > 0:
            vertex.co.x *= 0.76
    kit.smooth(head, 40)
    made.append(head)

    made += _inline_tuners(prefix, chrome, head_y - 0.038, 0.028, posts=strings)

    # Guard, pickups, bridge: a shaped slab is not a guitar until it is bolted
    # together. This is the layer the eye uses to classify the object.
    made.append(box(f"{prefix}_Pickguard", (0.108, 0.150, 0.0016), (0.012, 0.045, top),
                    guard_mat, bevel_width=0.006, segments=4))

    pickup_y = (0.118, 0.048, -0.028) if strings == 6 else (0.130, 0.010)
    for index, y in enumerate(pickup_y):
        made.append(box(f"{prefix}_Pickup{index}", (0.045, 0.010, 0.0055),
                        (0.016, y, top + 0.005), knob_mat,
                        bevel_width=0.0018, segments=3))
        for pole in range(strings):
            x = 0.016 - 0.016 * (strings - 1) / 3 + pole * (0.032 / (strings - 1))
            made.append(cyl(f"{prefix}_Pole{index}{pole}", 0.0021, 0.007,
                            (x, y, top + 0.010), chrome, vertices=12))

    made.append(box(f"{prefix}_Bridge", (0.050, 0.013, 0.006), (0.016, -0.112, top + 0.005),
                    chrome, bevel_width=0.002, segments=3))

    spacing = 0.0105 if strings == 4 else 0.0124
    for index in range(strings):
        x = 0.016 - spacing * (strings - 1) / 2 + index * spacing
        made.append(box(f"{prefix}_Saddle{index}", (0.0055, 0.0085, 0.0045),
                        (x, -0.110, top + 0.010), chrome, bevel_width=0.0012, segments=3))
        made.append(cyl(f"{prefix}_Intonation{index}", 0.0012, 0.012,
                        (x, -0.126, top + 0.006), chrome, vertices=10,
                        rotation=(math.pi / 2, 0, 0)))

    knob_count = 3 if strings == 6 else 2
    knob_spots = ((0.108, -0.058), (0.096, -0.112), (0.064, -0.150))[:knob_count]
    for index, (x, y) in enumerate(knob_spots):
        made.append(cyl(f"{prefix}_Knob{index}", 0.0155, 0.011, (x, y, top + 0.007),
                        knob_mat, vertices=20))
        made.append(cyl(f"{prefix}_KnobCap{index}", 0.006, 0.0125, (x, y, top + 0.008),
                        chrome, vertices=16))

    made.append(box(f"{prefix}_JackPlate", (0.016, 0.013, 0.0016), (0.058, -0.196, top),
                    chrome, bevel_width=0.004, segments=4))
    made.append(cyl(f"{prefix}_StrapTop", 0.0055, 0.010, (-0.098, 0.214, 0.0), chrome, vertices=16))
    made.append(cyl(f"{prefix}_StrapBottom", 0.0055, 0.010, (0.0, -0.226, 0.0), chrome, vertices=16))

    made += _frets(prefix, fret_mat, nut_y, scale_length, board_width - 0.001,
                   count=22 if strings == 6 else 20)

    made += _strings(
        prefix, string_mat, gauges,
        spacing=spacing, start=(0.0, -0.108, 0.0335), end=(0.0, nut_y + 0.006, 0.0400),
        x_centre=0.016,
    )

    made += _guitar_stand(prefix, chrome, knob_mat, home=(0.0, 0.02), height=0.42)
    return made


def acoustic(prefix, top_mat, back_mat, chrome, board_mat, neck_mat, fret_mat,
             string_mat, bridge_mat):
    """A dreadnought. The outline is the whole instrument, so it gets the attention."""
    made = []

    made.append(_slab(prefix, "Body", OUTLINE_ACOUSTIC, 0.105, top_mat, 6.0 * MM, subsurf=1))

    # The soundhole is a dark cavity, not a hole - a black disc just under the
    # surface reads identically from every angle this room is ever seen from,
    # and a boolean here costs a rebuild of the top's topology for nothing.
    hole = cyl(f"{prefix}_Soundhole", 0.0505, 0.02, (0.0, 0.045, 0.050),
               kit.solid(f"{prefix}_Cavity", (0.012, 0.010, 0.009), 0.85), vertices=48)
    made.append(hole)
    made.append(ring(f"{prefix}_Rosette", 0.056, 0.0022, (0.0, 0.045, 0.0525),
                     kit.wood(f"{prefix}_RosetteWood", (0.05, 0.02, 0.012), (0.16, 0.08, 0.05),
                              scale=(1, 60, 1), roughness=0.4),
                     rotation=(0, 0, 0), major_segments=48, minor_segments=6))

    made.append(_tapered_box(
        prefix, "Neck", (0.048, 0.500, 0.023), 0.20, neck_mat, 0.010,
        (0.0, 0.170 + 0.250, 0.030),
    ))
    made.append(_tapered_box(
        prefix, "Fretboard", (0.056, 0.500, 0.006), 0.04, board_mat, 0.004,
        (0.0, 0.415, 0.048), subsurf=1,
    ))
    made.append(box(f"{prefix}_Nut", (0.058, 0.006, 0.010), (0.0, 0.650, 0.054),
                    kit.bone(f"{prefix}_NutMat"), bevel_width=0.0012, segments=3))

    head = box(f"{prefix}_Headstock", (0.048, 0.100, 0.013), (0.0, 0.735, 0.044),
               back_mat, bevel_width=0.005, segments=4, rotation=(math.radians(-5), 0, 0))
    for vertex in head.data.vertices:
        if vertex.co.y > 0:
            vertex.co.x *= 0.80
    kit.smooth(head, 40)
    made.append(head)

    made += _split_tuners(prefix, chrome, (0.700, 0.732, 0.764), head_z=0.050)

    # Bridge, saddle and the six pins that hold the ball ends - the detail that
    # says "acoustic" from across a room.
    made.append(box(f"{prefix}_Bridge", (0.078, 0.038, 0.011), (0.0, -0.150, 0.056),
                    bridge_mat, bevel_width=0.003, segments=3))
    made.append(box(f"{prefix}_Saddle", (0.072, 0.003, 0.004), (0.0, -0.140, 0.064),
                    kit.bone(f"{prefix}_SaddleMat"), bevel_width=0.0008, segments=2))
    for index in range(6):
        x = -0.0275 + index * 0.011
        made.append(cyl(f"{prefix}_Pin{index}", 0.0028, 0.008, (x, -0.163, 0.058),
                        kit.solid(f"{prefix}_PinMat", (0.85, 0.82, 0.76), 0.32), vertices=12))
        made.append(cyl(f"{prefix}_PinDot{index}", 0.0016, 0.0016, (x, -0.163, 0.0625),
                        kit.solid(f"{prefix}_PinDotMat", (0.06, 0.05, 0.05), 0.25), vertices=10))

    # A pickguard, then the fretboard extension over the top bout.
    made.append(box(f"{prefix}_Pickguard", (0.052, 0.062, 0.0018), (-0.052, 0.070, 0.0528),
                    kit.solid(f"{prefix}_Guard", (0.045, 0.030, 0.026), 0.24),
                    bevel_width=0.006, segments=4))

    made += _frets(prefix, fret_mat, 0.650, 0.645, 0.054, count=20)

    made += _strings(
        prefix, string_mat,
        (0.0005, 0.0006, 0.00075, 0.0009, 0.0011, 0.00135),
        spacing=0.011, start=(0.0, -0.152, 0.066), end=(0.0, 0.652, 0.056),
    )

    made += _guitar_stand(prefix, chrome, kit.solid(f"{prefix}_StandMat", (0.02, 0.02, 0.024), 0.5),
                          home=(0.0, 0.02), height=0.44)
    return made
