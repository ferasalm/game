"""Blender side of the free recolour (tools/art/recolour.py does the colour maths; route: 3d-model skill).
Run: blender -b --factory-startup -P tools/art/recolour_bake.py -- bake <model.glb> <size> <out dir>
       -> <out>/pos.npy, nrm.npy (world, Z up, front = -Y), lit.npy (lit by a sun from the front = visible from it)
     blender -b --factory-startup -P tools/art/recolour_bake.py -- render <model.glb> <texture.png> <out prefix>
       -> <prefix>_front.png, _back.png, _q34.png (flat, unlit texture colour: judges the texture, not the light)
"""
import math
import os
import sys

import bpy
import numpy as np


def load_model(glb):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=glb)
    meshes = [o for o in bpy.data.objects if o.type == "MESH" and len(o.data.polygons) > 1000]
    for o in bpy.data.objects:
        if o.type == "MESH" and o not in meshes:
            o.hide_render = True  # the stray Rodin icosphere
    assert len(meshes) == 1, "expected one character mesh, got %s" % [o.name for o in meshes]
    return meshes[0]


def emission_material(obj):
    mat = bpy.data.materials.new("recolour"); mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(emit.outputs[0], out.inputs[0])
    obj.data.materials.clear(); obj.data.materials.append(mat)
    return nt, emit, out


def bake_to_array(nt, kind, size, **kw):
    img = bpy.data.images.new("bake_" + kind, size, size, float_buffer=True, alpha=False)
    node = nt.nodes.new("ShaderNodeTexImage"); node.image = img
    nt.nodes.active = node
    bpy.ops.object.bake(type=kind, margin=4, use_clear=True, **kw)
    px = np.empty(size * size * 4, dtype=np.float32); img.pixels.foreach_get(px)
    return px.reshape(size, size, 4)[::-1, :, :3].copy()  # Blender rows run bottom-up; flip to image order


def bake(glb, size, out_dir):
    obj = load_model(glb)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 4; sc.cycles.use_denoising = False
    for o in bpy.data.objects:
        o.select_set(False)  # the importer leaves the armature selected; bake takes selected objects
    bpy.context.view_layer.objects.active = obj; obj.select_set(True)
    nt, emit, out = emission_material(obj)
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    os.makedirs(out_dir, exist_ok=True)
    for name, socket in (("pos", "Position"), ("nrm", "Normal")):
        link = nt.links.new(geo.outputs[socket], emit.inputs["Color"])
        np.save(os.path.join(out_dir, name + ".npy"), bake_to_array(nt, "EMIT", size))
        nt.links.remove(link)
    diffuse = nt.nodes.new("ShaderNodeBsdfDiffuse")
    diffuse.inputs["Color"].default_value = (1, 1, 1, 1)
    nt.links.new(diffuse.outputs[0], out.inputs[0])
    sun = bpy.data.objects.new("front_sun", bpy.data.lights.new("front_sun", "SUN"))
    sun.data.angle = 0.0; sun.rotation_euler = (math.pi / 2, 0, 0)  # light travels +Y: from the camera into the model
    sc.collection.objects.link(sun)
    lit = bake_to_array(nt, "DIFFUSE", size, pass_filter={"DIRECT"})[:, :, 0]
    np.save(os.path.join(out_dir, "lit.npy"), lit)
    print("RECOLOUR baked %dpx to %s" % (size, out_dir))


def render(glb, tex, prefix):
    obj = load_model(glb)
    nt, emit, _ = emission_material(obj)
    node = nt.nodes.new("ShaderNodeTexImage"); node.image = bpy.data.images.load(tex)
    nt.links.new(node.outputs[0], emit.inputs["Color"])
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 4; sc.cycles.use_denoising = False
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 400, 720
    world = bpy.data.worlds.new("w"); sc.world = world
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.35, 0.35, 0.37, 1)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 2.2
    for tag, yaw in (("front", 0.0), ("back", 180.0), ("q34", 45.0)):
        a = math.radians(yaw)
        cam.location = (5 * math.sin(a), -5 * math.cos(a), 0.95)
        cam.rotation_euler = (math.pi / 2, 0, a)
        sc.render.filepath = "%s_%s.png" % (prefix, tag)
        bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    if argv[0] == "bake":
        bake(argv[1], int(argv[2]), argv[3])
    elif argv[0] == "render":
        render(argv[1], argv[2], argv[3])
    else:
        raise SystemExit("mode must be bake or render")


main()
