"""Rebuild a Rodin glb with new triangle indices (from Godot, winding flipped back; IDX_BIN '-' keeps its own), no
images or materials, compact buffer, and bone renames. A skinned model has its feet lifted to y=0; a rigid one can be
placed instead. Regions are boxes in the source's mesh space: x0,y0,z0,x1,y1,z1.
Usage: rewrite_glb.py SRC IDX_BIN DST [--cut BOX | --keep BOX] [--press BOX] [--place OX,OY,OZ,YAW_DEG,SCALE]
  --cut drops the triangles whose centroid is inside BOX, --keep drops the others (split a piece into two files),
  --press flattens the vertices inside BOX onto its back face z0 (removes a baked bump without opening a hole),
  --place sets the mesh node so OX,OY,OZ lands on the origin, turned YAW_DEG about y and scaled (rigid parts)."""
import argparse, json, struct
import numpy as np

ap = argparse.ArgumentParser()
ap.add_argument('src'); ap.add_argument('idx'); ap.add_argument('dst')
ap.add_argument('--cut'); ap.add_argument('--keep'); ap.add_argument('--press'); ap.add_argument('--place')
args = ap.parse_args()
def floats(text, count):
    values = [float(v) for v in text.split(',')]
    assert len(values) == count, text
    return np.array(values)
src, idx_path, dst = args.src, args.idx, args.dst
b = open(src, 'rb').read()
n = struct.unpack('<I', b[12:16])[0]
j = json.loads(b[20:20 + n])
bin0 = 20 + n + 8
blob = b[bin0:]

prim = j['meshes'][0]['primitives'][0]
prim.pop('material', None)
for key in ('images', 'textures', 'samplers', 'materials'):
    j.pop(key, None)
for node in j['nodes']:
    if node.get('name') == 'head':
        node['name'] = 'Head'

def acc_data(i):
    a = j['accessors'][i]; v = j['bufferViews'][a['bufferView']]
    start = v.get('byteOffset', 0) + a.get('byteOffset', 0)
    comps = {'SCALAR': 1, 'VEC3': 3, 'MAT4': 16}[a['type']]
    dtype = {5126: np.float32, 5125: np.uint32, 5123: np.uint16}[a['componentType']]
    return np.frombuffer(blob, dtype=dtype, count=a['count'] * comps, offset=start).reshape(a['count'], comps).copy()
pos_i = prim['attributes']['POSITION']
pos = acc_data(pos_i)
if idx_path == '-':
    idx = acc_data(prim['indices']).reshape(-1, 3).astype(np.int64)
else:
    idx = np.frombuffer(open(idx_path, 'rb').read(), dtype=np.int32).reshape(-1, 3)[:, [0, 2, 1]]
def inside(points, box):
    return np.all((points >= box[:3]) & (points <= box[3:]), axis=-1)
for flag, keep in ((args.cut, False), (args.keep, True)):
    if flag:
        hit = inside(pos[idx].mean(1), floats(flag, 6))
        idx = idx[hit] if keep else idx[~hit]
        print('triangles left', len(idx))
if args.press:
    box = floats(args.press, 6); hit = inside(pos, box)
    pos[hit, 2] = box[2]
    print('pressed', int(hit.sum()))
idx16 = idx.astype(np.uint16 if idx.max() < 65535 else np.uint32).tobytes()
replaced = {pos_i: pos.tobytes()}

if 'skins' in j:
    # Feet to y = 0: lift the vertices, the skeleton's root joint and fold the shift into the inverse bind matrices.
    lift = -float(pos[:, 1].min())
    pos[:, 1] += lift
    skin = j['skins'][0]
    ibm = acc_data(skin['inverseBindMatrices'])
    ibm[:, 12:15] -= lift * ibm[:, 4:7]  # column-major: col3 -= h * col1
    root = j['nodes'][skin['joints'][0]]
    t = root.get('translation', [0, 0, 0]); root['translation'] = [t[0], t[1] + lift, t[2]]
    replaced = {pos_i: pos.tobytes(), skin['inverseBindMatrices']: ibm.tobytes()}
    print('lift', lift)
elif args.place:
    ox, oy, oz, yaw, scale = floats(args.place, 5)
    half = np.radians(yaw) / 2.0
    rot = [0.0, float(np.sin(half)), 0.0, float(np.cos(half))]
    c, s_ = np.cos(np.radians(yaw)), np.sin(np.radians(yaw))
    o = np.array([ox, oy, oz]) * scale  # T = -R(scale * o), R about y: (x, y, z) -> (x c + z s, y, -x s + z c)
    node = next(nd for nd in j['nodes'] if 'mesh' in nd)
    node.update(translation=[float(-(o[0] * c + o[2] * s_)), float(-o[1]), float(-(-o[0] * s_ + o[2] * c))],
                rotation=rot, scale=[float(scale)] * 3)
j['accessors'][pos_i]['min'] = pos.min(0).tolist(); j['accessors'][pos_i]['max'] = pos.max(0).tolist()

out = bytearray()
views = []
def add_view(data: bytes, target=None) -> int:
    while len(out) % 4:
        out.append(0)
    view = {'buffer': 0, 'byteOffset': len(out), 'byteLength': len(data)}
    if target:
        view['target'] = target
    out.extend(data)
    views.append(view)
    return len(views) - 1

for i, acc in enumerate(j['accessors']):
    if i == prim['indices']:
        acc['bufferView'] = add_view(idx16, 34963)
        acc['count'] = idx.size
        acc['componentType'] = 5123 if idx.max() < 65535 else 5125
        acc.pop('byteOffset', None)
        continue
    if 'bufferView' not in acc:
        continue
    v = j['bufferViews'][acc['bufferView']]
    start = v.get('byteOffset', 0)
    if i in replaced:
        assert 'byteStride' not in v and acc.get('byteOffset', 0) == 0
        acc['bufferView'] = add_view(replaced[i], v.get('target'))
        continue
    acc['bufferView'] = add_view(blob[start:start + v['byteLength']], v.get('target'))
    if 'byteStride' in v:
        views[-1]['byteStride'] = v['byteStride']
j['bufferViews'] = views
while len(out) % 4:
    out.append(0)
j['buffers'] = [{'byteLength': len(out)}]
js = json.dumps(j, separators=(',', ':')).encode()
js += b' ' * ((4 - len(js) % 4) % 4)
total = 12 + 8 + len(js) + 8 + len(out)
with open(dst, 'wb') as f:
    f.write(struct.pack('<III', 0x46546C67, 2, total))
    f.write(struct.pack('<II', len(js), 0x4E4F534A) + js)
    f.write(struct.pack('<II', len(out), 0x004E4942) + bytes(out))
print('tris', len(idx), 'bytes', total)
