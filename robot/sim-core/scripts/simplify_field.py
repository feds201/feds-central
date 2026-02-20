#!/usr/bin/env python3
"""
Converts a GLB field model (from AdvantageScope / FIRST field CAD) to a
simplified OBJ file suitable for ODE4J trimesh collision.

Usage:
    python simplify_field.py input.glb output.obj [--decimate RATIO]

Requirements:
    pip install trimesh pygltflib numpy

The script:
1. Loads the GLB file
2. Merges all meshes
3. Optionally decimates to reduce triangle count
4. Exports as OBJ (Z-up, meters)
"""

import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description='Convert GLB field to simplified OBJ')
    parser.add_argument('input', help='Input GLB file path')
    parser.add_argument('output', help='Output OBJ file path')
    parser.add_argument('--decimate', type=float, default=0.1,
                       help='Decimation ratio (0.1 = keep 10%% of faces)')
    args = parser.parse_args()

    try:
        import trimesh
    except ImportError:
        print("Error: trimesh not installed. Run: pip install trimesh pygltflib numpy")
        sys.exit(1)

    print(f"Loading {args.input}...")
    scene = trimesh.load(args.input)

    if isinstance(scene, trimesh.Scene):
        # Merge all meshes in the scene
        mesh = scene.dump(concatenate=True)
    else:
        mesh = scene

    print(f"Original: {len(mesh.faces)} faces, {len(mesh.vertices)} vertices")

    if args.decimate < 1.0:
        target_faces = int(len(mesh.faces) * args.decimate)
        mesh = mesh.simplify_quadric_decimation(target_faces)
        print(f"Decimated: {len(mesh.faces)} faces, {len(mesh.vertices)} vertices")

    mesh.export(args.output, file_type='obj')
    print(f"Exported to {args.output}")

if __name__ == '__main__':
    main()
