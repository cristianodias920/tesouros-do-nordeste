import os, sys, urllib.request, zipfile, io

target_dir = os.path.expandvars(r'%APPDATA%\Godot\export_templates\4.7.2.stable')
os.makedirs(target_dir, exist_ok=True)

url = 'https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
print(f'Downloading export templates to {target_dir}...')

temp_tpz = os.path.join(target_dir, 'templates.tpz')
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as resp, open(temp_tpz, 'wb') as out_f:
    length = int(resp.headers.get('content-length', 0))
    downloaded = 0
    while True:
        chunk = resp.read(1024 * 1024)
        if not chunk:
            break
        out_f.write(chunk)
        downloaded += len(chunk)
        if length > 0:
            print(f'Progress: {downloaded / (1024*1024):.1f}MB / {length / (1024*1024):.1f}MB', end='\r')

print('\nExtracting templates...')
with zipfile.ZipFile(temp_tpz, 'r') as z:
    for member in z.infolist():
        # Member name is like 'templates/web_nothreads_release.zip'
        filename = os.path.basename(member.filename)
        if not filename:
            continue
        dest = os.path.join(target_dir, filename)
        with z.open(member) as src, open(dest, 'wb') as dst:
            dst.write(src.read())

if os.path.exists(temp_tpz):
    os.remove(temp_tpz)

print('Export templates successfully installed!')
