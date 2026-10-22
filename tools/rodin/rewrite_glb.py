"""Scratch: rebuild a Rodin glb with new triangle indices (from Godot, winding flipped back), no images or
materials, compact buffer, and bone renames. Usage: rewrite_glb.py SRC IDX_BIN DST"""
import json, struct, sys
import numpy as np

src, idx_path, dst = sys.argv[1:4]
b = open(src, 'rb').read()
n = struct.unpack('<I', b[12:16])[0]
j = json.loads(b[20:20 + n])
bin0 = 20 + n + 8
blob = b[bin0:]

idx = np.frombuffer(open(idx_path, 'rb').read(), dtype=np.int32).reshape(-1, 3)[:, [0, 2, 1]]
idx16 = idx.astype(np.uint16 if idx.max() < 65535 else np.uint32).tobytes()

prim = j['meshes'][0]['primitives'][0]
prim.pop('material', None)
for key in ('images', 'textures', 'samplers', 'materials'):
    j.pop(key, None)
for node in j['nodes']:
    if node.get('name') == 'head':
        node['name'] = 'Head'

# Feet to y = 0: lift the vertices, the skeleton's root joint and fold the shift into the inverse bind matrices.
def acc_data(i):
    a = j['accessors'][i]; v = j['bufferViews'][a['bufferView']]
    start = v.get('byteOffset', 0) + a.get('byteOffset', 0)
    comps = {'VEC3': 3, 'MAT4': 16}[a['type']]
    return np.frombuffer(blob, dtype=np.float32, count=a['count'] * comps, offset=start).reshape(a['count'], comps).copy()
pos_i = prim['attributes']['POSITION']
pos = acc_data(pos_i)
lift = -float(pos[:, 1].min())
pos[:, 1] += lift
skin = j['skins'][0]
ibm = acc_data(skin['inverseBindMatrices'])
ibm[:, 12:15] -= lift * ibm[:, 4:7]  # column-major: col3 -= h * col1
root = j['nodes'][skin['joints'][0]]
t = root.get('translation', [0, 0, 0]); root['translation'] = [t[0], t[1] + lift, t[2]]
replaced = {pos_i: pos.tobytes(), skin['inverseBindMatrices']: ibm.tobytes()}
j['accessors'][pos_i]['min'][1] += lift; j['accessors'][pos_i]['max'][1] += lift
print('lift', lift)

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
