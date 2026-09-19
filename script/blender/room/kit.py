"""(b) The room - shared primitives and materials.

Everything in this package works in metres, because the room is a space you
walk into and the instruments have to look like they belong to a person. The
guitar work in ../guitar/ is the reference for the material reasoning: a flat
Principled value is what "plastic" means to a renderer, so nothing here is
allowed to be one solid colour with one roughness.
"""

import math

import bpy

MM = 0.001


# --- object plumbing --------------------------------------------------------


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def activate(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def apply_modifier(obj, name):
    """Kept for single-modifier use; prefer apply_modifiers in a build loop."""
    activate(obj)
    bpy.ops.object.modifier_apply(modifier=name)


def apply_modifiers(obj):
    """Apply every modifier in one evaluation and drop them.

    bpy.ops.object.modifier_apply re-evaluates the whole scene per call, and in a
    room of 750 objects that cost roughly a second each. Evaluating the object
    once and taking the resulting mesh is the same geometry for a fraction of the
    work - and unlike the ops version it never leaves a live modifier behind.
    """
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    mesh = bpy.data.meshes.new_from_object(evaluated)

    obj.modifiers.clear()

    original = obj.data
    obj.data = mesh
    if original.users == 0:
        bpy.data.meshes.remove(original)

    return obj


def smooth(obj, angle=38):
    """Shade smooth, without a modifier left on the object.

    shade_auto_smooth() adds a geometry-nodes modifier for the angle split. It
    looks harmless and then re-evaluates on *every* later operation, so a scene
    of 750 objects turns each new object into seconds of work - which is what
    made one guitar take two minutes and the whole room thirteen.

    Everything that asks for smoothing here is a cylinder, a sphere or a bevelled
    slab, and the bevel already provides the geometry that a hard edge would, so
    flat-out smooth shading is both correct and free.
    """
    mesh = obj.data
    mesh.polygons.foreach_set("use_smooth", [True] * len(mesh.polygons))
    mesh.update()


def bevel(obj, width, segments=3, angle=30):
    modifier = obj.modifiers.new("Bevel", "BEVEL")
    modifier.width = width
    modifier.segments = segments
    modifier.limit_method = "ANGLE"
    modifier.angle_limit = math.radians(angle)
    # Hidden right away: an unevaluated modifier still has to be re-evaluated by
    # every depsgraph update that touches the object, so a room of 750 objects
    # turns each new object into a second of work - which is what made the first
    # build take thirteen minutes.
    modifier.show_viewport = False
    modifier.show_render = True


def finish(obj):
    """Bake every modifier left on the object and drop them.

    Primitives stack up to three modifiers (bevel) while the room is built from
    raw mesh data; this converts them to final geometry in one evaluation instead
    of one operator apply per modifier, which re-evaluates the whole scene per
    call and costs a second per object once the room gets big.
    """
    if not obj.modifiers:
        return obj

    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    mesh = bpy.data.meshes.new_from_object(evaluated)

    obj.modifiers.clear()

    original = obj.data
    obj.data = mesh
    if original.users == 0:
        bpy.data.meshes.remove(original)

    return obj


def kit_finish(obj, home, rotation, mat):
    """The part of every primitive that is pure object state, not mesh work.

    Location, rotation and material are assignments, not evaluations - but they
    are also exactly what is forgotten when a new primitive is added without
    them, so they live here rather than at the bottom of each function. The
    modifiers baked in at the same time, while the object count is still low
    enough for the evaluation to be cheap.
    """
    finish(obj)
    obj.location = home
    obj.rotation_euler = rotation
    obj.data.materials.append(mat)
    if obj.type != "EMPTY":
        smooth(obj, 40)
    return obj


def box(name, size, home, mat, bevel_width=0.0015, segments=3, rotation=(0, 0, 0)):
    """A slab with a radius on every edge. Real objects do not have knife edges.

    Built as raw mesh data with the scale already in the vertices, because the
    operator version needs a context plus a scale-apply plus a bevel - three
    evaluations per box, and there are hundreds of them.
    """
    vertices = [(
        -size[0] / 2 if x else size[0] / 2,
        -size[1] / 2 if y else size[1] / 2,
        -size[2] / 2 if z else size[2] / 2,
    ) for x, y, z in (
        (0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0),
        (0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1),
    )]

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(
        vertices, [],
        [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (2, 6, 7, 3), (1, 5, 6, 2), (0, 3, 7, 4)],
    )
    mesh.validate()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    if bevel_width > 0:
        bevel(obj, min(bevel_width, min(size) * 0.45), segments)

    kit_finish(obj, home, rotation, mat)
    return obj


def cyl(name, radius, depth, home, mat, vertices=24, rotation=(0, 0, 0), cap_bevel=0.0008):
    """A cylinder from raw mesh data.

    The operator version needs a context and, in a room of 750 objects, costs
    about a second per cylinder even before the scene gets big. Vertices here
    are laid out the way the operator does: a ring on the bottom cap, a ring on
    the top cap, then the cap fans and the side wall.
    """
    side = [(
        radius * math.cos((index / vertices) * math.tau),
        radius * math.sin((index / vertices) * math.tau),
        -depth / 2 if z else depth / 2,
    ) for z in (1, 0) for index in range(vertices)]
    mesh_vertices = [(0.0, 0.0, -depth / 2), (0.0, 0.0, depth / 2)] + side

    bottom = list(range(2, 2 + vertices))
    top = list(range(2 + vertices, 2 + 2 * vertices))
    faces = [bottom[::-1], top]
    faces += [(2 + i, 2 + (i + 1) % vertices, 2 + vertices + (i + 1) % vertices, 2 + vertices + i)
              for i in range(vertices)]

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(mesh_vertices, [], faces)
    mesh.validate()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    if cap_bevel > 0:
        bevel(obj, min(cap_bevel, radius * 0.3, depth * 0.3), 2)

    kit_finish(obj, home, rotation, mat)
    return obj


def ring(name, major, minor, home, mat, rotation=(0, 0, 0), major_segments=32, minor_segments=10):
    """A torus from raw mesh data.

    Same reasoning as the cylinder: the operator carries a context cost that is
    small once and large 750 times. Laid out in rings around the axis, with one
    quad face between each pair of neighbouring rings.
    """
    vertices = []
    for major_index in range(major_segments):
        centre = (major_index / major_segments) * math.tau
        for minor_index in range(minor_segments):
            tube = (minor_index / minor_segments) * math.tau
            vertices.append((
                (major + minor * math.cos(tube)) * math.cos(centre),
                (major + minor * math.cos(tube)) * math.sin(centre),
                minor * math.sin(tube),
            ))

    def at(major_index, minor_index):
        return (major_index % major_segments) * minor_segments + (minor_index % minor_segments)

    faces = [(
        at(major_index, minor_index), at(major_index, minor_index + 1),
        at(major_index + 1, minor_index + 1), at(major_index + 1, minor_index),
    ) for major_index in range(major_segments) for minor_index in range(minor_segments)]

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.validate()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    kit_finish(obj, home, rotation, mat)
    return obj


def sphere(name, radius, home, mat, segments=20, rings=12, scale=(1, 1, 1)):
    """A sphere from raw mesh data, with the scale in the vertices.

    The operator version needs a context plus a transform-apply, and there are
    forty of them - the dust caps and the mic grille alone account for a minute.
    A squash along one axis is just a scale baked into the vertex positions.
    """
    vertices = [(0.0, 0.0, -radius * scale[2])]
    for ring_index in range(1, rings):
        belt = (ring_index / rings) * math.pi
        for segment_index in range(segments):
            angle = (segment_index / segments) * math.tau
            vertices.append((
                radius * scale[0] * math.sin(belt) * math.cos(angle),
                radius * scale[1] * math.sin(belt) * math.sin(angle),
                radius * scale[2] * math.cos(belt),
            ))
    vertices.append((0.0, 0.0, radius * scale[2]))

    faces = []
    faces += [(0, 2 + i, 2 + (i + 1) % segments) for i in range(segments)]
    for ring_index in range(rings - 2):
        base = 2 + ring_index * segments
        faces += [(base + i, base + segments + i, base + segments + (i + 1) % segments, base + (i + 1) % segments)
                  for i in range(segments)]
    cap = 2 + (rings - 1) * segments
    faces += [(cap, cap - segments + (i + 1) % segments, cap - segments + i) for i in range(segments)]

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.validate()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    kit_finish(obj, home, (0, 0, 0), mat)
    return obj


def disc(name, radius, depth, home, mat, rotation=(0, 0, 0), vertices=48, bow=0.0):
    """A cymbal, a drum head, a speaker cone - a shallow cone, not a flat card.

    A perfectly flat disc catches light like paper. `bow` gives it the slight
    dish every real cymbal and drum head has. From raw mesh data like the rest,
    for the same reason: the operator's context cost per call is what made the
    cymbals take as long as the guitars.
    """
    bottom = [(radius * math.cos((i / vertices) * math.tau),
               radius * math.sin((i / vertices) * math.tau), -depth / 2)
              for i in range(vertices)]
    top_radius = radius * (1.0 - bow)
    top = [(top_radius * math.cos((i / vertices) * math.tau),
            top_radius * math.sin((i / vertices) * math.tau), depth / 2)
           for i in range(vertices)]
    mesh_vertices = [(0.0, 0.0, -depth / 2), (0.0, 0.0, depth / 2)] + bottom + top

    base = 2
    faces = [list(range(base, base + vertices))[::-1], list(range(base + vertices, base + 2 * vertices))]
    faces += [(base + i, base + (i + 1) % vertices,
               base + vertices + (i + 1) % vertices, base + vertices + i)
              for i in range(vertices)]

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(mesh_vertices, [], faces)
    mesh.validate()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    kit_finish(obj, home, rotation, mat)
    return obj


# --- materials --------------------------------------------------------------


def _principled(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    return mat, mat.node_tree, mat.node_tree.nodes["Principled BSDF"]


def solid(name, color, roughness=0.5, metallic=0.0):
    mat, _, bsdf = _principled(name)
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


def lacquer(name, color, roughness=0.10, peel_scale=240.0, peel=0.010, coat=1.0):
    """Sprayed finish: the orange peel is what separates gloss from moulded plastic."""
    mat, nodes, bsdf = _principled(name)
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = roughness

    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = coat
        bsdf.inputs["Coat Roughness"].default_value = 0.03

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


def wood(name, dark, light, scale=(1.0, 24.0, 1.0), roughness=0.34, bump=0.05):
    mat, nodes, bsdf = _principled(name)
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = roughness

    coords = nodes.nodes.new("ShaderNodeTexCoord")
    mapping = nodes.nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = scale

    noise = nodes.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 2.6
    noise.inputs["Detail"].default_value = 6.0
    noise.inputs["Roughness"].default_value = 0.62

    ramp = nodes.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.36
    ramp.color_ramp.elements[0].color = (*dark, 1.0)
    ramp.color_ramp.elements[1].position = 0.64
    ramp.color_ramp.elements[1].color = (*light, 1.0)

    grain = nodes.nodes.new("ShaderNodeBump")
    grain.inputs["Strength"].default_value = bump
    grain.inputs["Distance"].default_value = 0.0006

    nodes.links.new(coords.outputs["Object"], mapping.inputs["Vector"])
    nodes.links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    nodes.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nodes.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    nodes.links.new(noise.outputs["Fac"], grain.inputs["Height"])
    nodes.links.new(grain.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def metal(name, color=(0.62, 0.63, 0.66), roughness=0.12, smudge=45.0):
    mat, nodes, bsdf = _principled(name)
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = roughness

    noise = nodes.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = smudge
    noise.inputs["Detail"].default_value = 3.0

    ramp = nodes.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.40
    ramp.color_ramp.elements[0].color = (roughness * 0.5,) * 3 + (1.0,)
    ramp.color_ramp.elements[1].position = 0.66
    ramp.color_ramp.elements[1].color = (min(roughness * 3.0, 0.6),) * 3 + (1.0,)

    nodes.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nodes.links.new(ramp.outputs["Color"], bsdf.inputs["Roughness"])
    return mat


def weave(name, color, roughness=0.72, grid=520.0, depth=0.0012):
    """Grill cloth, tolex, rug - woven things read as weave only when they bump."""
    mat, nodes, bsdf = _principled(name)
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = roughness

    wave_x = nodes.nodes.new("ShaderNodeTexWave")
    wave_x.wave_type = "BANDS"
    wave_x.bands_direction = "X"
    wave_x.inputs["Scale"].default_value = grid
    wave_x.inputs["Distortion"].default_value = 1.4

    wave_y = nodes.nodes.new("ShaderNodeTexWave")
    wave_y.wave_type = "BANDS"
    wave_y.bands_direction = "Y"
    wave_y.inputs["Scale"].default_value = grid
    wave_y.inputs["Distortion"].default_value = 1.4

    # A Math node rather than MixRGB: MixRGB is the legacy node and the wave
    # outputs are scalars anyway, so multiplying them is the whole operation.
    mix = nodes.nodes.new("ShaderNodeMath")
    mix.operation = "MULTIPLY"

    bump = nodes.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.35
    bump.inputs["Distance"].default_value = depth

    nodes.links.new(wave_x.outputs["Fac"], mix.inputs[0])
    nodes.links.new(wave_y.outputs["Fac"], mix.inputs[1])
    nodes.links.new(mix.outputs["Value"], bump.inputs["Height"])
    nodes.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def flake(name, color, base_roughness=0.24, flake_scale=900.0):
    """Drum wrap: a metallic flake under clear coat, so it sparkles at a distance."""
    mat, nodes, bsdf = _principled(name)
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.35
    bsdf.inputs["Roughness"].default_value = base_roughness

    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.6
        bsdf.inputs["Coat Roughness"].default_value = 0.08

    noise = nodes.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = flake_scale
    noise.inputs["Detail"].default_value = 2.0

    rough = nodes.nodes.new("ShaderNodeValToRGB")
    rough.color_ramp.elements[0].position = 0.42
    rough.color_ramp.elements[0].color = (base_roughness * 0.6,) * 3 + (1.0,)
    rough.color_ramp.elements[1].position = 0.62
    rough.color_ramp.elements[1].color = (min(base_roughness * 2.2, 0.7),) * 3 + (1.0,)

    nodes.links.new(noise.outputs["Fac"], rough.inputs["Fac"])
    nodes.links.new(rough.outputs["Color"], bsdf.inputs["Roughness"])
    return mat


def lather(name, color, roughness=0.20, scale=180.0):
    """Lathed bronze - the concentric tool marks under a cymbal's patina."""
    mat, nodes, bsdf = _principled(name)
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = roughness

    noise = nodes.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = 4.0
    noise.inputs["Roughness"].default_value = 0.7

    rough = nodes.nodes.new("ShaderNodeValToRGB")
    rough.color_ramp.elements[0].position = 0.44
    rough.color_ramp.elements[0].color = (roughness * 0.75,) * 3 + (1.0,)
    rough.color_ramp.elements[1].position = 0.60
    rough.color_ramp.elements[1].color = (roughness * 1.8,) * 3 + (1.0,)

    nodes.links.new(noise.outputs["Fac"], rough.inputs["Fac"])
    nodes.links.new(rough.outputs["Color"], bsdf.inputs["Roughness"])
    return mat


def bone(name="Nut"):
    mat, _, bsdf = _principled(name)
    bsdf.inputs["Base Color"].default_value = (0.86, 0.82, 0.72, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.34
    if "Subsurface Weight" in bsdf.inputs:
        bsdf.inputs["Subsurface Weight"].default_value = 0.25
        bsdf.inputs["Subsurface Radius"].default_value = (0.012, 0.008, 0.005)
    return mat


# --- hierarchy --------------------------------------------------------------


def station(name, home=(0, 0, 0), rotation=(0, 0, 0)):
    """An empty the instrument's parts hang off.

    One node per instrument is what lets the web viewer pick the room apart and
    move whole instruments around; it also exports as the glTF group.

    Takes a floor position as either two or three values, because every call
    site is placing something on the floor and a mandatory z of zero is noise.
    """
    empty = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(empty)
    empty.empty_display_size = 0.2
    empty.location = (home[0], home[1], home[2] if len(home) > 2 else 0.0)
    empty.rotation_euler = rotation
    return empty


def adopt(parts, empty):
    """Parent parts to a station, in the station's own coordinates.

    Deliberately *not* preserving world position: every builder works around its
    instrument's local origin, so the station's location and rotation are the
    whole placement. Preserving world position instead is what silently stacked
    all four guitars on top of the drum kit.
    """
    for part in parts:
        part.parent = empty

    bpy.context.view_layer.update()
    return parts
