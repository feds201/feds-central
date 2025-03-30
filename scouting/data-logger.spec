# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['P:\\FEDS201\\Scouting_Suite\\Scout-Ops-DataChunk\\qrcode_scanner.py'],
    pathex=[],
    binaries=[('P:\\FEDS201\\Scouting_Suite\\Scout-Ops-Compiler\\Lib\\site-packages\\pyzbar\\*.dll', 'pyzbar')],
    datas=[('P:\\FEDS201\\Scouting_Suite\\Scout-Ops-DataChunk\\qqq.wav', '.'), ('P:\\FEDS201\\Scouting_Suite\\Scout-Ops-DataChunk\\woof.wav', '.')],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='Scout-Ops-DataLogger',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['P:\\FEDS201\\Scouting_Suite\\logo.ico'],
)
