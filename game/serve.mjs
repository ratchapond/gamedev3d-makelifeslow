import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.join(path.dirname(fileURLToPath(import.meta.url)),'build','web');
const mime={'.html':'text/html; charset=utf-8','.js':'application/javascript','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml'};
http.createServer((req,res)=>{
 const url=new URL(req.url,'http://127.0.0.1');
 const p=path.resolve(root,'.'+decodeURIComponent(url.pathname==='/'?'/index.html':url.pathname));
 if(!p.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
 fs.stat(p,(err,stat)=>{if(err||!stat.isFile()){res.writeHead(404);res.end('Not found');return;}
 res.setHeader('Content-Type',mime[path.extname(p)]||'application/octet-stream');res.setHeader('Cache-Control','no-cache');fs.createReadStream(p).pipe(res);});
}).listen(8765,'127.0.0.1',()=>console.log('Play: http://127.0.0.1:8765'));
