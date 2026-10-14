// Reassemble compressed engine/game assets as streams, preserving virtual filenames.
(() => {
 const files = {"index.wasm":{"parts":["index.wasm.gz"],"bytes":39514754},"game-49b1dbe9e4bd9103.pck":{"parts":["game-49b1dbe9e4bd9103.pck.gz.part00","game-49b1dbe9e4bd9103.pck.gz.part01","game-49b1dbe9e4bd9103.pck.gz.part02"],"bytes":45266300}};
 const fetchAsset = window.fetch.bind(window);
 window.fetch = async (input, options) => {
  const url = new URL(input instanceof Request ? input.url : input, location.href);
  const name = url.pathname.split('/').pop();
  if (url.origin !== location.origin || !files[name]) return fetchAsset(input, options);
  const asset = files[name];let next = 0;let reader = null;
  const compressed = new ReadableStream({
   async pull(controller) {
    try {
     while (true) {
      if (!reader) {
       if (next >= asset.parts.length) { controller.close();return; }
       const response = await fetchAsset(new URL(asset.parts[next++], url), options);
       if (!response.ok) throw new Error(`Game download failed (${response.status})`);
       reader = response.body.getReader();
      }
      const chunk = await reader.read();
      if (chunk.done) { reader.releaseLock();reader = null;continue; }
      controller.enqueue(chunk.value);return;
     }
    } catch (error) { controller.error(error); }
   },
   async cancel(reason) { if (reader) await reader.cancel(reason); }
  });
  return new Response(compressed.pipeThrough(new DecompressionStream('gzip')), {headers: {
   'Content-Type': name.endsWith('.wasm') ? 'application/wasm' : 'application/octet-stream',
   'Content-Length': String(asset.bytes)
  }});
 };
})();
