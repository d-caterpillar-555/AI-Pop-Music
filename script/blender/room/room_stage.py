"""(b) Staging a built room.

The geometry build costs about eight minutes and the lighting costs seconds, so
they are separate: room_build.py -- "<path>.blend" geometry saves the bare room,
and this script opens that file, lights it, frames it and renders or exports.

    blender.exe --background D:/apm-work/room/geometry.blend \
        --python D:/apm-work/room/room_stage.py -- D:/apm-shots/b-room.png samples=48

Output extension picks the mode: .png still, .mp4 turntable, .glb export,
.blend save. `frame=room` frames the walls instead of the instruments.
"""

import os
import sys
import time

import bpy
from mathutils import Vector

try:
    HERE = os.path.dirname(os.path.abspath(__file__))
except NameError:  # pragma: no cover
    HERE = os.path.dirname(os.path.abspath(sys.argv[sys.argv.index("--python") + 1]))
sys.path.insert(0, HERE)

import room_build  # noqa: E402

SHELL = ("Floor", "BackWall", "LeftWall", "WindowGlass", "Rug")


def subjects(frame_room=False):
    if frame_room:
        return [obj for obj in bpy.data.objects if obj.type == "MESH"]
    return [
        obj for obj in bpy.data.objects
        if obj.type == "MESH" and obj.name not in SHELL
    ]


def main():
    started = time.time()

    argv = sys.argv
    args = argv[argv.index("--") + 1:] if "--" in argv else []
    out = args[0] if args else "D:/apm-shots/b-room.png"

    samples = 48
    size = None
    frame_room = False
    for arg in args[1:]:
        if arg.startswith("samples="):
            samples = int(arg.split("=", 1)[1])
        elif arg.startswith("size="):
            width, height = arg.split("=", 1)[1].lower().split("x")
            size = (int(width), int(height))
        elif arg == "frame=room":
            frame_room = True

    camera = room_build.stage()
    room_build.frame_camera(camera, subjects(frame_room))
    room_build.grade()
    print(f"STAGED in {time.time() - started:.0f}s")

    if size is not None:
        bpy.context.scene.render.resolution_x, bpy.context.scene.render.resolution_y = size

    if out.endswith(".glb"):
        room_build.export_glb(out)
    elif out.endswith(".blend"):
        bpy.ops.wm.save_as_mainfile(filepath=out)
        print(f"BLEND {out}")
    elif out.endswith(".mp4"):
        room_build.render_video(out, samples, 120, (1024, 576))
    else:
        room_build.render(out, samples)

    print(f"DONE in {time.time() - started:.0f}s")


if __name__ == "__main__":
    main()
