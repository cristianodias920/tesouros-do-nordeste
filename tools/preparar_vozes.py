#!/usr/bin/env python3
"""Prepara as falas do Zeca: corta silêncio do início/fim, normaliza o volume
e converte para OGG em audio/voz/<id>.ogg (mesmos ids de voz_lista.txt).
Uso: python3 tools/preparar_vozes.py /pasta/com/wavs [pasta_de_saida]   (precisa de numpy e soundfile)
   (sem pasta de saída: audio/voz; para a história use audio/historia)
Depois, reimporte no Godot e exporte a versão Web de novo."""
import sys, os, glob
import numpy as np, soundfile as sf
src = sys.argv[1] if len(sys.argv) > 1 else "voz_brutas"
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio", "voz")
os.makedirs(out, exist_ok=True)
for f in sorted(glob.glob(os.path.join(src, "*.wav"))):
    x, sr = sf.read(f)
    if x.ndim > 1: x = x.mean(1)
    thr = 0.02 * np.max(np.abs(x))
    idx = np.nonzero(np.abs(x) > thr)[0]
    y = x[max(idx[0] - int(0.04 * sr), 0):min(idx[-1] + int(0.12 * sr), len(x))]
    rms = np.sqrt(np.mean(y[np.abs(y) > thr] ** 2)); y = y * (0.2 / rms)
    pk = np.max(np.abs(y)); y = y * (0.95 / pk) if pk > 0.95 else y
    fi = int(0.01 * sr); y[:fi] *= np.linspace(0, 1, fi); y[-fi:] *= np.linspace(1, 0, fi)
    name = os.path.splitext(os.path.basename(f))[0]
    sf.write(os.path.join(out, name + ".ogg"), y, sr, format="OGG", subtype="VORBIS")
    print(name, "%.2fs" % (len(y) / sr))
