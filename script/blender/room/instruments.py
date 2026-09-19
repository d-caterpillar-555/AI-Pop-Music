"""(b) The room - everything that is not a guitar.

Same conventions as guitars.py: built in metres in a local frame with the floor
at z = 0 and the instrument facing -Y, parts named with the station's prefix so
the web viewer can pick a whole instrument up and move it.

Materials arrive as a palette dict from room_build.py rather than being created
here, because two calls to the same material builder produce two different
Blender materials and the room would end up with a dozen near-identical chromes.
"""

import math

import bpy

import kit
from kit import MM, box, cyl, disc, ring, sphere


def _lugs(prefix, radius, y, count, mat, spacing=0.035):
    """The bolts around a drum head. Small, and most of what says 'drum'."""
    made = []
    for index in range(count):
        angle = (index / count) * math.tau
        made.append(box(
            f"{prefix}_Lug{int(y * 1000)}_{index}", (0.016, 0.030, 0.020),
            (radius * math.cos(angle) * 0.99, y, radius * math.sin(angle) * 0.99),
            mat, bevel_width=0.003, segments=2,
            rotation=(0, -angle + math.pi / 2, 0),
        ))
    return made


def _drum(prefix, radius, depth, home, shell_mat, head_mat, chrome, lugs=8, axis="Y"):
    """A shell with two heads, two hoops and a ring of lugs."""
    made = []
    rotation = (math.pi / 2, 0, 0) if axis == "Y" else (0, 0, 0)

    made.append(cyl(f"{prefix}_Shell", radius, depth, home, shell_mat,
                    vertices=40, rotation=rotation, cap_bevel=0.0))

    for side in (-1, 1):
        offset = (0, side * (depth / 2 + 0.002), 0) if axis == "Y" else (0, 0, side * (depth / 2 + 0.002))
        centre = (home[0] + offset[0], home[1] + offset[1], home[2] + offset[2])

        made.append(disc(f"{prefix}_Head{side}", radius * 0.995, 0.004, centre,
                         head_mat, rotation=rotation, vertices=40, bow=0.0))
        made.append(ring(f"{prefix}_Hoop{side}", radius + 0.008, 0.0075, centre,
                         chrome, rotation=rotation, major_segments=40, minor_segments=8))
        made += _lugs(f"{prefix}{side}", radius, home[1] + side * (depth / 2 - 0.030),
                      lugs, chrome) if axis == "Y" else []

    return made


def _tripod(prefix, chrome, x, y, top, spread=0.22, leg_radius=0.008):
    """Three legs, a hub and a tube - every stand in the room is this."""
    made = []
    made.append(cyl(f"{prefix}_Hub", 0.020, 0.030, (x, y, 0.030), chrome, vertices=16))

    for index in range(3):
        angle = (index / 3) * math.tau + 0.4
        made.append(cyl(
            f"{prefix}_Foot{index}", 0.007, spread * 1.9,
            (x + math.cos(angle) * spread * 0.5, y + math.sin(angle) * spread * 0.5, 0.012),
            chrome, vertices=10,
            rotation=(math.radians(74) * math.sin(angle), math.radians(74) * math.cos(angle), 0),
        ))

    made.append(cyl(f"{prefix}_Tube", leg_radius, top, (x, y, top / 2), chrome, vertices=14))
    return made


# --- 01 drums ---------------------------------------------------------------


def drums(prefix, M, home=(0, 0, 0)):
    """A five-piece kit with hats, a crash and a ride, and the throne behind it."""
    made = []
    ox, oy = home[0], home[1]

    kick = (ox, oy + 0.16, 0.29)
    made += _drum(f"{prefix}_Kick", 0.280, 0.460, kick, M["wrap"], M["head_clear"], M["chrome"], lugs=10)

    # The port hole in the front head. Every kit in a rehearsal room has one,
    # and at a distance it is what tells you which way the drum is facing.
    made.append(disc(f"{prefix}_KickPort", 0.072, 0.004, (ox + 0.115, oy - 0.074, 0.245),
                     M["black"], rotation=(math.pi / 2, 0, 0), vertices=28))
    made.append(ring(f"{prefix}_KickPortRing", 0.074, 0.005, (ox + 0.115, oy - 0.076, 0.245),
                     M["chrome"], rotation=(math.pi / 2, 0, 0), major_segments=28, minor_segments=6))

    # Spurs: the legs that stop a kick drum walking across the floor.
    for side in (-1, 1):
        made.append(cyl(f"{prefix}_Spur{side}", 0.009, 0.34,
                        (ox + side * 0.26, oy + 0.30, 0.16), M["chrome"], vertices=12,
                        rotation=(math.radians(-28), 0, math.radians(-side * 18))))
        made.append(box(f"{prefix}_SpurFoot{side}", (0.030, 0.030, 0.014),
                        (ox + side * 0.36, oy + 0.38, 0.007), M["black"],
                        bevel_width=0.004, segments=2))

    # Beater pedal on the player's side.
    made.append(box(f"{prefix}_Pedal", (0.075, 0.140, 0.028), (ox, oy + 0.450, 0.016),
                    M["metal_dark"], bevel_width=0.004, segments=3))
    made.append(box(f"{prefix}_PedalPlate", (0.065, 0.100, 0.014), (ox, oy + 0.470, 0.036),
                    M["chrome"], bevel_width=0.004, segments=3,
                    rotation=(math.radians(-12), 0, 0)))

    snare = (ox - 0.40, oy - 0.06, 0.62)
    made += _tripod(f"{prefix}_SnareStand", M["chrome"], snare[0], snare[1], 0.60, spread=0.20)
    made += _drum(f"{prefix}_Snare", 0.178, 0.140, snare, M["snare_shell"], M["head_coat"],
                  M["chrome"], lugs=8)
    made.append(box(f"{prefix}_Strainer", (0.020, 0.030, 0.040),
                    (snare[0] + 0.185, snare[1], snare[2] - 0.02), M["chrome"],
                    bevel_width=0.004, segments=3))

    for index, (radius, depth, x, y, z, tilt) in enumerate((
        (0.127, 0.200, -0.20, 0.30, 0.94, 20),
        (0.152, 0.235, 0.16, 0.32, 0.96, 16),
    )):
        made += _drum(f"{prefix}_Tom{index}", radius, depth, (ox + x, oy + y, z),
                      M["wrap"], M["head_clear"], M["chrome"], lugs=6)
        made += _tripod(f"{prefix}_TomArm{index}", M["chrome"], ox + x, oy + y - 0.14, z - 0.10,
                        spread=0.10, leg_radius=0.010)

    made += _drum(f"{prefix}_FloorTom", 0.178, 0.360, (ox + 0.56, oy - 0.02, 0.44),
                  M["wrap"], M["head_clear"], M["chrome"], lugs=8)
    for index in range(3):
        angle = (index / 3) * math.tau + 0.8
        made.append(cyl(f"{prefix}_FloorLeg{index}", 0.008, 0.44,
                        (ox + 0.56 + math.cos(angle) * 0.16, oy - 0.02 + math.sin(angle) * 0.16, 0.22),
                        M["chrome"], vertices=10))
        made.append(box(f"{prefix}_FloorFoot{index}", (0.024, 0.024, 0.010),
                        (ox + 0.56 + math.cos(angle) * 0.16, oy - 0.02 + math.sin(angle) * 0.16, 0.005),
                        M["black"], bevel_width=0.003, segments=2))

    # Hi-hat: two cymbals, a rod and a clutch, on its own stand.
    hats = (ox - 0.62, oy + 0.10)
    made += _tripod(f"{prefix}_HatStand", M["chrome"], hats[0], hats[1], 0.92, spread=0.18)
    for index, z in enumerate((0.94, 0.98)):
        made.append(disc(f"{prefix}_Hat{index}", 0.178, 0.0016, (hats[0], hats[1], z),
                         M["cymbal"], vertices=44, bow=0.06))
    made.append(cyl(f"{prefix}_Clutch", 0.010, 0.030, (hats[0], hats[1], 1.01), M["chrome"], vertices=14))

    crash = (ox - 0.66, oy + 0.52)
    made += _tripod(f"{prefix}_CrashStand", M["chrome"], crash[0], crash[1], 1.24, spread=0.22)
    made.append(cyl(f"{prefix}_CrashBoom", 0.008, 0.34, (crash[0] + 0.05, crash[1] - 0.10, 1.28),
                    M["chrome"], vertices=12, rotation=(math.radians(58), 0, math.radians(20))))
    made.append(disc(f"{prefix}_Crash", 0.203, 0.0016, (crash[0] + 0.12, crash[1] - 0.20, 1.32),
                     M["cymbal"], rotation=(math.radians(19), 0, math.radians(-8)),
                     vertices=44, bow=0.05))
    made.append(cyl(f"{prefix}_CrashBell", 0.030, 0.010, (crash[0] + 0.12, crash[1] - 0.20, 1.325),
                    M["cymbal"], vertices=20))

    ride = (ox + 0.66, oy + 0.30)
    made += _tripod(f"{prefix}_RideStand", M["chrome"], ride[0], ride[1], 1.14, spread=0.22)
    made.append(disc(f"{prefix}_Ride", 0.254, 0.0020, (ride[0], ride[1] - 0.02, 1.16),
                     M["cymbal"], rotation=(math.radians(12), 0, 0), vertices=48, bow=0.04))
    made.append(cyl(f"{prefix}_RideBell", 0.040, 0.014, (ride[0], ride[1] - 0.02, 1.168),
                    M["cymbal"], vertices=20))

    throne = (ox - 0.02, oy + 0.74)
    made.append(cyl(f"{prefix}_Seat", 0.165, 0.055, (throne[0], throne[1], 0.60), M["black"], vertices=28))
    made.append(cyl(f"{prefix}_ThronePost", 0.020, 0.58, (throne[0], throne[1], 0.30), M["chrome"], vertices=16))
    for index in range(3):
        angle = (index / 3) * math.tau + 0.3
        made.append(cyl(f"{prefix}_ThroneLeg{index}", 0.009, 0.30,
                        (throne[0] + math.cos(angle) * 0.11, throne[1] + math.sin(angle) * 0.11, 0.10),
                        M["chrome"], vertices=10,
                        rotation=(math.radians(72) * math.sin(angle), math.radians(72) * math.cos(angle), 0)))

    return made


# --- 02 keys ----------------------------------------------------------------


def keys(prefix, M, home=(0, 0, 0)):
    """A 61-key synth on an X-stand - five octaves, control panel, end cheeks."""
    made = []
    ox, oy = home[0], home[1]
    height = 0.72

    white_width = 0.0225
    white_depth = 0.135
    key_top = height + 0.045
    bed_width = 36 * white_width

    made.append(box(f"{prefix}_Chassis", (0.95, 0.30, 0.085), (ox, oy, height), M["plastic_dark"],
                    bevel_width=0.006, segments=4))
    made.append(box(f"{prefix}_Bed", (bed_width + 0.01, white_depth + 0.01, 0.012),
                    (ox, oy - 0.062, key_top - 0.012), M["black"], bevel_width=0.002, segments=2))

    black_pitch = {1, 3, 6, 8, 10}
    white_index = 0
    ledger = []
    for semitone in range(61):
        pitch = semitone % 12
        if pitch in black_pitch:
            ledger.append((True, white_index - 0.5, semitone))
        else:
            ledger.append((False, white_index, semitone))
            white_index += 1

    for is_black, slot, semitone in ledger:
        x = ox - bed_width / 2 + (slot + 0.5) * white_width

        if is_black:
            made.append(box(f"{prefix}_BlackKey{semitone}", (0.0125, 0.092, 0.011),
                            (x, oy - 0.082, key_top + 0.003), M["key_black"],
                            bevel_width=0.002, segments=2))
        else:
            made.append(box(f"{prefix}_WhiteKey{semitone}", (white_width - 0.0012, white_depth, 0.010),
                            (x, oy - 0.060, key_top - 0.001), M["key_white"],
                            bevel_width=0.0018, segments=2))

    panel_y = oy + 0.118
    made.append(box(f"{prefix}_Panel", (0.90, 0.055, 0.010), (ox, panel_y, key_top + 0.004),
                    M["metal_dark"], bevel_width=0.002, segments=2))

    for index in range(8):
        x = ox - 0.33 + index * 0.058
        made.append(cyl(f"{prefix}_Knob{index}", 0.011, 0.014, (x, panel_y, key_top + 0.014),
                        M["plastic_dark"], vertices=18))
        made.append(cyl(f"{prefix}_KnobMark{index}", 0.0022, 0.004, (x, panel_y - 0.007, key_top + 0.020),
                        M["accent"], vertices=8))

    for index in range(4):
        x = ox + 0.18 + index * 0.045
        made.append(box(f"{prefix}_Fader{index}", (0.006, 0.030, 0.012), (x, panel_y, key_top + 0.012),
                        M["chrome"], bevel_width=0.0015, segments=2))
        made.append(box(f"{prefix}_FaderSlot{index}", (0.010, 0.038, 0.003), (x, panel_y, key_top + 0.006),
                        M["black"], bevel_width=0.001, segments=1))

    made.append(box(f"{prefix}_Display", (0.070, 0.030, 0.004), (ox - 0.40, panel_y, key_top + 0.010),
                    M["screen"], bevel_width=0.0012, segments=2))

    for index, (x, side) in enumerate(((ox - 0.63, -1), (ox + 0.63, 1))):
        made.append(box(f"{prefix}_Wheel{index}", (0.011, 0.048, 0.026), (x, oy - 0.050, key_top + 0.012),
                        M["plastic_dark"], bevel_width=0.0018, segments=2))

    for side in (-1, 1):
        made.append(box(f"{prefix}_Cheek{side}", (0.030, 0.300, 0.105), (ox + side * 0.482, oy, height),
                        M["wood_end"], bevel_width=0.006, segments=4))

    # X-stand: two crossed pairs, which is what a synth actually sits on.
    for side in (-1, 1):
        for lean in (-1, 1):
            made.append(cyl(f"{prefix}_StandLeg{side}{lean}", 0.011, 0.86,
                            (ox + side * 0.40, oy + lean * 0.02, height / 2 - 0.02),
                            M["metal_dark"], vertices=14,
                            rotation=(math.radians(lean * 16), 0, 0)))
    for side in (-1, 1):
        made.append(cyl(f"{prefix}_StandRail{side}", 0.012, 0.30, (ox + side * 0.40, oy, 0.32),
                        M["metal_dark"], vertices=14, rotation=(0, math.pi / 2, 0)))
    made.append(cyl(f"{prefix}_StandStrap", 0.006, 0.86, (ox, oy - 0.02, 0.30),
                    M["black"], vertices=10))

    return made


# --- 03 amp stack -----------------------------------------------------------


def amp_stack(prefix, M, home=(0, 0, 0)):
    """A 4x12 with a head on top, and the speaker cones behind the cloth."""
    made = []
    ox, oy = home[0], home[1]

    made.append(box(f"{prefix}_Cab", (0.760, 0.360, 0.720), (ox, oy, 0.360), M["tolex"],
                    bevel_width=0.008, segments=3))

    for x in (-0.19, 0.19):
        for z in (0.185, 0.535):
            # Recessed behind the cloth. The first pass had the cones and their
            # dust caps proud of the baffle, which put four white eggs on the
            # front of the cabinet.
            made.append(disc(f"{prefix}_Cone{x:+.2f}_{z:.2f}", 0.157, 0.036,
                             (ox + x, oy - 0.150, z), M["speaker"],
                             rotation=(math.pi / 2, 0, 0), vertices=40, bow=0.22))
            made.append(sphere(f"{prefix}_Dust{x:+.2f}_{z:.2f}", 0.032,
                               (ox + x, oy - 0.162, z), M["chrome"], segments=18, rings=10,
                               scale=(1, 0.55, 1)))

    made.append(box(f"{prefix}_Grill", (0.718, 0.010, 0.678), (ox, oy - 0.183, 0.360),
                    M["grill"], bevel_width=0.002, segments=2))
    made.append(box(f"{prefix}_Badge", (0.090, 0.004, 0.022), (ox, oy - 0.187, 0.660),
                    M["chrome"], bevel_width=0.0015, segments=2))

    for index, x in enumerate((-0.375, 0.375), start=1):
        for z in (0.200, 0.520):
            made.append(box(f"{prefix}_Corner{index}{int(z * 100)}", (0.030, 0.070, 0.030),
                            (ox + x, oy - 0.140, z), M["black"], bevel_width=0.004, segments=3))
    for side in (-1, 1):
        made.append(cyl(f"{prefix}_Handle{side}", 0.014, 0.150, (ox + side * 0.385, oy, 0.500),
                        M["metal_dark"], vertices=14, rotation=(math.pi / 2, 0, 0)))
    for index, (x, y) in enumerate(((-0.28, -0.12), (0.28, -0.12), (-0.28, 0.12), (0.28, 0.12))):
        made.append(cyl(f"{prefix}_Caster{index}", 0.026, 0.020, (ox + x, oy + y, 0.022),
                        M["black"], vertices=16, rotation=(math.pi / 2, 0, 0)))

    # Head: shorter and shallower than the cab, as a real one is.
    made.append(box(f"{prefix}_Head", (0.700, 0.280, 0.240), (ox, oy, 0.840), M["tolex"],
                    bevel_width=0.007, segments=3))
    made.append(box(f"{prefix}_Faceplate", (0.640, 0.008, 0.150), (ox, oy - 0.142, 0.848),
                    M["brass"], bevel_width=0.0015, segments=2))

    for index in range(7):
        x = ox - 0.25 + index * 0.048
        made.append(cyl(f"{prefix}_AmpKnob{index}", 0.011, 0.016, (x, oy - 0.150, 0.870),
                        M["black"], vertices=16, rotation=(math.pi / 2, 0, 0)))
    for index in range(3):
        x = ox + 0.20 + index * 0.036
        made.append(cyl(f"{prefix}_Jack{index}", 0.006, 0.014, (x, oy - 0.150, 0.812),
                        M["chrome"], vertices=12, rotation=(math.pi / 2, 0, 0)))
    made.append(box(f"{prefix}_Switch", (0.022, 0.010, 0.030), (ox + 0.315, oy - 0.150, 0.848),
                    M["chrome"], bevel_width=0.003, segments=2))
    made.append(box(f"{prefix}_Vent", (0.420, 0.004, 0.060), (ox, oy + 0.142, 0.940),
                    M["black"], bevel_width=0.0015, segments=2))

    made.append(box(f"{prefix}_HeadRest", (0.520, 0.040, 0.012), (ox, oy, 0.966), M["metal_dark"],
                    bevel_width=0.003, segments=2))

    # Speaker cable from head to cab, lying on top of the cab.
    made.append(cyl(f"{prefix}_Cable", 0.007, 0.360, (ox - 0.30, oy - 0.070, 0.726),
                    M["black"], vertices=10, rotation=(0, math.pi / 2, 0)))

    return made


# --- 04 vocal mic -----------------------------------------------------------


def mic(prefix, M, home=(0, 0, 0)):
    """A boom stand with a dynamic mic on it, aimed back into the room."""
    made = []
    ox, oy = home[0], home[1]
    height = 1.52

    made += _tripod(f"{prefix}_Stand", M["chrome"], ox, oy, height, spread=0.28, leg_radius=0.013)

    made.append(cyl(f"{prefix}_BoomJoint", 0.024, 0.060, (ox, oy, height), M["chrome"], vertices=18))
    made.append(cyl(f"{prefix}_BoomWeight", 0.026, 0.130, (ox, oy + 0.140, height - 0.06),
                    M["metal_dark"], vertices=18, rotation=(math.radians(70), 0, 0)))
    made.append(cyl(f"{prefix}_Boom", 0.0115, 0.760, (ox, oy - 0.240, height - 0.180),
                    M["chrome"], vertices=16, rotation=(math.radians(72), 0, 0)))

    mic_pos = (ox, oy - 0.560, height - 0.360)
    made.append(cyl(f"{prefix}_Clip", 0.020, 0.030, (mic_pos[0], mic_pos[1] + 0.015, mic_pos[2]),
                    M["black"], vertices=16, rotation=(math.radians(58), 0, 0)))
    made.append(cyl(f"{prefix}_MicBody", 0.0245, 0.130, (mic_pos[0], mic_pos[1] - 0.045, mic_pos[2] - 0.020),
                    M["metal_dark"], vertices=22, rotation=(math.radians(58), 0, 0)))
    made.append(sphere(f"{prefix}_MicGrille", 0.0255, (mic_pos[0], mic_pos[1] - 0.118, mic_pos[2] - 0.062),
                       M["grille"], segments=20, rings=12, scale=(1, 1, 1.15)))
    made.append(ring(f"{prefix}_MicBand", 0.0250, 0.0022,
                     (mic_pos[0], mic_pos[1] - 0.100, mic_pos[2] - 0.052),
                     M["chrome"], rotation=(math.radians(58), 0, 0), major_segments=22, minor_segments=6))
    made.append(cyl(f"{prefix}_Cable", 0.0055, 0.900, (ox + 0.06, oy + 0.10, 0.020),
                    M["black"], vertices=10, rotation=(math.radians(88), 0, math.radians(24))))

    return made


# --- 05 pedalboard ----------------------------------------------------------


def pedalboard(prefix, M, home=(0, 0, 0)):
    """A board with six pedals, patched, powered, and cabled to the amp."""
    made = []
    ox, oy = home[0], home[1]
    tilt = math.radians(-7)

    made.append(box(f"{prefix}_Board", (0.640, 0.360, 0.030), (ox, oy, 0.052), M["wood_end"],
                    bevel_width=0.004, segments=3, rotation=(tilt, 0, 0)))
    for side in (-1, 1):
        made.append(box(f"{prefix}_Rail{side}", (0.022, 0.360, 0.060),
                        (ox + side * 0.330, oy, 0.058), M["metal_dark"],
                        bevel_width=0.003, segments=3, rotation=(tilt, 0, 0)))

    for index in range(6):
        column = index % 3
        row = index // 3
        x = ox - 0.190 + column * 0.190
        y = oy - 0.070 + row * 0.135
        z = 0.072 + row * 0.020

        made.append(box(f"{prefix}_Pedal{index}", (0.070, 0.120, 0.036), (x, y, z),
                        M["pedal_a"] if index % 2 == 0 else M["pedal_b"],
                        bevel_width=0.003, segments=3, rotation=(tilt, 0, 0)))
        for knob in range(3):
            made.append(cyl(f"{prefix}_PedalKnob{index}{knob}", 0.0075, 0.010,
                            (x - 0.020 + knob * 0.020, y + 0.030, z + 0.022),
                            M["chrome"], vertices=14, rotation=(tilt, 0, 0)))
        made.append(cyl(f"{prefix}_PedalSwitch{index}", 0.008, 0.012,
                        (x, y - 0.036, z + 0.018), M["chrome"], vertices=14, rotation=(tilt, 0, 0)))
        made.append(cyl(f"{prefix}_PedalLed{index}", 0.0035, 0.006,
                        (x + 0.026, y + 0.030, z + 0.022), M["led"], vertices=10))

    # Patch cables between the pedals, and two runs off the board.
    for index in range(5):
        column = index % 3
        row = index // 3
        x = ox - 0.190 + column * 0.190 + 0.040
        y = oy - 0.070 + row * 0.135
        if column == 2:
            x = ox - 0.190 - 0.100
            y = oy - 0.070 + 0.150
        made.append(cyl(f"{prefix}_Patch{index}", 0.0045, 0.075, (x, y, 0.100),
                        M["black"], vertices=8, rotation=(math.radians(80), 0, math.radians(90))))

    made.append(cyl(f"{prefix}_ToAmp", 0.0055, 0.900, (ox + 0.180, oy + 0.300, 0.030),
                    M["black"], vertices=8, rotation=(math.radians(86), 0, math.radians(6))))
    made.append(cyl(f"{prefix}_FromGuitar", 0.0055, 0.900, (ox - 0.180, oy - 0.300, 0.030),
                    M["black"], vertices=8, rotation=(math.radians(86), 0, math.radians(-8))))

    made.append(box(f"{prefix}_Supply", (0.140, 0.080, 0.028), (ox + 0.230, oy + 0.130, 0.024),
                    M["metal_dark"], bevel_width=0.003, segments=2))

    return made
