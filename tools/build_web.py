"""Export the editable Godot project and prepare assets for GitHub Pages hosting."""
from pathlib import Path
import subprocess,os,re,json,hashlib,gzip,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs';TMP=ROOT/'game/build';TMP.mkdir(exist_ok=True)
env=os.environ.copy();env.update({'XDG_DATA_HOME':'/tmp/slow-life-data','XDG_CACHE_HOME':'/tmp/godot-cache','XDG_CONFIG_HOME':'/tmp/godot-config'})
for args in [['--editor','--import','--quit'],['--export-pack','Web',str(TMP/'game.pck')]]:
 result=subprocess.run(['godot','--headless','--path',str(ROOT/'game')]+args,env=env,capture_output=True,text=True)
 if result.returncode or any(e in result.stdout+result.stderr for e in ['SCRIPT ERROR','Parse Error']):
  raise RuntimeError(result.stdout[-4000:]+result.stderr[-4000:])
pack=(TMP/'game.pck').read_bytes();name='game-'+hashlib.sha256(pack).hexdigest()[:16]+'.pck';packed=gzip.compress(pack,compresslevel=9,mtime=0)
# Versioned filenames prevent an older browser pack from being reused.
for p in OUT.glob('game-*.pck*'):p.unlink()
chunks=[]
chunk_size=16*1024*1024
for index,offset in enumerate(range(0,len(packed),chunk_size)):
 part=name+f'.gz.part{index:02d}';(OUT/part).write_bytes(packed[offset:offset+chunk_size]);chunks.append(part)
html_path=OUT/'index.html';html=html_path.read_text();m=re.search(r'const GODOT_CONFIG = (.*);',html);config=json.loads(m[1]);config['mainPack']=name;config['fileSizes']={'index.wasm':39514754,name:len(pack)}
html_path.write_text(html[:m.start(1)]+json.dumps(config,separators=(',',':'))+html[m.end(1):])
assets={'index.wasm':{'parts':['index.wasm.gz'],'bytes':39514754},name:{'parts':chunks,'bytes':len(pack)}}
loader="// Reassemble compressed engine/game assets as streams, preserving virtual filenames.\n(() => {\n const files = __ASSETS__;\n const fetchAsset = window.fetch.bind(window);\n window.fetch = async (input, options) => {\n  const url = new URL(input instanceof Request ? input.url : input, location.href);\n  const name = url.pathname.split('/').pop();\n  if (url.origin !== location.origin || !files[name]) return fetchAsset(input, options);\n  const asset = files[name];let next = 0;let reader = null;\n  const compressed = new ReadableStream({\n   async pull(controller) {\n    try {\n     while (true) {\n      if (!reader) {\n       if (next >= asset.parts.length) { controller.close();return; }\n       const response = await fetchAsset(new URL(asset.parts[next++], url), options);\n       if (!response.ok) throw new Error(`Game download failed (${response.status})`);\n       reader = response.body.getReader();\n      }\n      const chunk = await reader.read();\n      if (chunk.done) { reader.releaseLock();reader = null;continue; }\n      controller.enqueue(chunk.value);return;\n     }\n    } catch (error) { controller.error(error); }\n   },\n   async cancel(reason) { if (reader) await reader.cancel(reason); }\n  });\n  return new Response(compressed.pipeThrough(new DecompressionStream('gzip')), {headers: {\n   'Content-Type': name.endsWith('.wasm') ? 'application/wasm' : 'application/octet-stream',\n   'Content-Length': String(asset.bytes)\n  }});\n };\n})();\n"
(OUT/'wasm-loader.js').write_text(loader.replace('__ASSETS__',json.dumps(assets,separators=(',',':'))))
assert gzip.decompress(packed)==pack
large=[p.name for p in OUT.iterdir() if p.is_file() and p.stat().st_size>=25*1024*1024]
assert not large,large
print(json.dumps({'pack':name,'uncompressed_bytes':len(pack),'hosted_bytes':len(packed),'largest_asset_bytes':max(p.stat().st_size for p in OUT.iterdir() if p.is_file())}))
