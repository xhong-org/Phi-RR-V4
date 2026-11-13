// Keep the extension's embedded fallback and Included Files on the same API.
import fs from 'node:fs';
import path from 'node:path';
export function syncBridges(root) {
  const extension = path.join(root,'extensions/I_HTML5');
  const video = fs.readFileSync(path.join(extension,'gx_video_boot.js'),'utf8');
  const dropFile = path.join(extension,'I_GXDrop.js');
  let drop = fs.readFileSync(dropFile,'utf8');
  const start = drop.indexOf('    (function installGxVideo(g) {');
  const shaderStart = drop.indexOf('    (function installGxShader(g) {',start);
  if(start < 0 || shaderStart < start) throw Error('Missing GX video/shader boundary.');
  const tail = /\}\)\(typeof globalThis !== "undefined" \? globalThis : window\);\s*$/;
  if(!tail.test(video)) throw Error('Unexpected standalone video wrapper.');
  const fallback = video.slice(video.indexOf('(function (g) {'))
    .replace('(function (g) {','(function installGxVideo(g) {')
    .replace('function bind(name, fn) {','function bind(name, fn) {\n        exportGx(name, fn);')
    .replace(tail,'})(global);')
    .trimEnd().split('\n').map(line=>line.trim() ? '    '+line.trimEnd() : '').join('\n');
  drop = drop.slice(0,start)+fallback+'\n\n'+drop.slice(shaderStart);
  if(fs.readFileSync(dropFile,'utf8')!==drop) fs.writeFileSync(dropFile,drop);
  fs.copyFileSync(path.join(extension,'gx_video_boot.js'),path.join(root,'datafiles/gx_video_boot.js'));
  fs.copyFileSync(dropFile,path.join(root,'datafiles/gx_drop.js'));
}
