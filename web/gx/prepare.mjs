// Turn a self-contained emsdk export into a static Pages directory.
// This does not commit, push, or clear browser storage.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const out = path.resolve(process.argv[2] || path.join(root,'.build/gx-pages'));
const files = fs.readdirSync(out);
const wasm = files.find(f=>f.endsWith('.wasm') && !f.startsWith('runner'));
if (!wasm) throw Error('Refusing a local runner export: project-specific emsdk WASM is required.');
const stem = wasm.slice(0,-5);
for (const name of [stem+'.js',stem+'.data']) if(!fs.existsSync(path.join(out,name))) throw Error('Incomplete emsdk output: '+name);
// The generic emsdk HTML lacks GX's manifest, async and window callbacks.
// Keep the official GX shell; replace only its shared local runner reference.
const htmlFile = 'runner.html';
if(!fs.existsSync(path.join(out,htmlFile))) throw Error('Missing official GX launch template.');
let html = fs.readFileSync(path.join(out,htmlFile),'utf8');
if (!html.includes('manifestFiles()') || !html.includes('var Module')) throw Error('Incomplete GX launch template.');
html = html.replace(/src="runner\.js"/g,`src="${stem}.js"`);
html = html.replace(/<script\b[^>]*\bsrc\s*=\s*(?:"https:\/\/pagead2[^"]*"|'https:\/\/pagead2[^']*'|https:\/\/pagead2[^\s>]+)[^>]*>[\s\S]*?<\/script>/gi,'');
html = html.replace(/<script\b[^>]*>\s*window\.adsbygoogle\s*=\s*window\.adsbygoogle\s*\|\|\s*\[\][\s\S]*?<\/script>/gi,'');
html = html.replace(/<img\b[^>]*\bid="QR2?Code"[^>]*>/g,'');
html = html.replace(/<title>[^<]*<\/title>/,'<title>Phi-RR</title>');
html = html.replace('canvasElement.style.width = newWidth + "px";',
  'canvasElement.style.width = newWidth + "px";\n        if (window.PhiGX) PhiGX.resizeCanvas();');
html = html.replace('</head>','<style>#output-container{display:none}body{justify-content:center}canvas#canvas{flex:none}</style></head>');
const stampHash = crypto.createHash('sha256');
for (const name of ['I_GXDrop.js','gx_shell.js','gx_audio_boot.js','gx_video_boot.js']) {
  stampHash.update(fs.readFileSync(name === 'I_GXDrop.js' ? path.join(root,'extensions/I_HTML5',name) : path.join(root,'datafiles',name)));
}
const stamp = stampHash.digest('hex').slice(0,12);
const bootstrap = `<script id="pls-gx-static-build">window.__plsGXRemoteBuild=true;var plsFirstFrame=onFirstFrameRendered;onFirstFrameRendered=function(){plsFirstFrame();if(window.PhiGX)PhiGX.runtimeReady();};</script>\n`
  + ['gx_shell.js','gx_audio_boot.js','gx_drop.js','gx_video_boot.js'].map(name=>`<script src="${name}?v=${stamp}"></script>`).join('\n')+'\n';
html = html.replace(/<script\b[^>]*\bsrc\s*=\s*(?:"([^"]+)"|'([^']+)'|([^\s>]+))[^>]*>\s*<\/script>/gi,
  (tag,a,b,c) => (a||b||c).split('?')[0] === stem+'.js' ? bootstrap+tag : tag);
if(!html.includes('window.__plsGXRemoteBuild=true')) throw Error('Could not insert static GX bootstrap.');
if(/deleteDatabase\(|caches\.delete\(/.test(html)) throw Error('Refusing a page that clears user storage on startup.');
fs.writeFileSync(path.join(out,'index.html'),html);
fs.writeFileSync(path.join(out,stem+'.html'),html);
for(const name of ['gx_shell.js','gx_audio_boot.js','gx_video_boot.js','gx_import.html'])fs.copyFileSync(path.join(root,'datafiles',name),path.join(out,name));
fs.copyFileSync(path.join(root,'extensions/I_HTML5/I_GXDrop.js'),path.join(out,'gx_drop.js'));
fs.writeFileSync(path.join(out,'.nojekyll'),'');
const hashes={};
for(const name of [stem+'.wasm',stem+'.js',stem+'.data','index.html','gx_drop.js','gx_shell.js','gx_audio_boot.js','gx_video_boot.js'])hashes[name]=crypto.createHash('sha256').update(fs.readFileSync(path.join(out,name))).digest('hex');
fs.writeFileSync(path.join(out,'gx-build.json'),JSON.stringify({target:'operagx',runtime:'YYC',mode:'remote',emsdk:'3.1.47',created:new Date().toISOString(),files:hashes},null,2)+'\n');
console.log('GX remote static output: '+out);
