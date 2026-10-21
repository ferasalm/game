class_name ModelSource
extends VisualSource
## Stub for the live 3D model source (B4 fills it in; docs/design/characters-3d.md): a skinned glTF from a ModelDef,
## clips retargeted at import, yaw facing, BoneAttachment3D anchors, clip events from ModelDef timing. Until then it
## draws nothing and answers every VisualSource call with the harmless default, so a rules def with
## `"default_source": "model"` is already a valid, invisible character.
