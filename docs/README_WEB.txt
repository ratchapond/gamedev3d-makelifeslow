Make Life Slower — current playtest

Serve this directory over HTTP(S). Open index.html.
The loader streams and decompresses index.wasm.gz and the versioned .pck.gz parts.
Keep every pack part together with wasm-loader.js and index.html.

Source and editable art: ../game/ and ../art-source/
Rebuild from the repository root: python3 tools/build_web.py

Current features: refined people/animals, clear roadside foliage, half-density
flowers, Thai-layout E interactions, milking minigame and wandering visitors.
No additional model redesign is included in this snapshot.
