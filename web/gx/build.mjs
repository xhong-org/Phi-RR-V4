// Windows build entry: always package OperaGX YYC using the configured emsdk.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { syncBridges } from './sync-bridges.mjs';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const sdk = path.resolve(process.argv[2] || path.join(root, '.build/gx-emsdk'));
const out = path.resolve(process.argv[3] || path.join(root, '.build/gx-pages'));
const cli = path.join(process.env.APPDATA, 'npm/node_modules/@gamemaker/gm-cli/dist/cli.js');
if (process.platform !== 'win32') throw Error('This build procedure is verified on Windows.');
if (!fs.existsSync(path.join(sdk, 'upstream/emscripten/emcc.py'))) throw Error('Supply an installed and activated emsdk 3.1.47 directory.');
if (JSON.parse(fs.readFileSync(path.join(sdk,'upstream/emscripten/emscripten-version.txt'),'utf8')) !== '3.1.47') throw Error('GameMaker 2026.0.0.23 requires emsdk 3.1.47 for this build.');
if (!fs.existsSync(cli)) throw Error('The existing global gm-cli installation is required.');
fs.mkdirSync(path.join(root,'.build'),{recursive:true});
syncBridges(root);
// YYC caches can retain anonymous-function references after GML offsets change.
// Preserve the old target cache and compile afresh when the source changes.
const signatureFile = path.join(root,'.gmcache/gx-source-signature.json');
const hashInputs = [];
function collect(dir) {
  for(const entry of fs.readdirSync(dir,{withFileTypes:true})) {
    const file=path.join(dir,entry.name);
    if(entry.isDirectory())collect(file);
    else if(file.endsWith('.gml'))hashInputs.push(file);
  }
}
collect(path.join(root,'scripts'));collect(path.join(root,'objects'));
hashInputs.push(path.join(root,'PhigrosLoader-sample.yyp'),path.join(root,'web/gx/runtime-export.js'));
const {createHash}=await import('node:crypto');
const signatureHash=createHash('sha256');
for(const file of hashInputs.sort())signatureHash.update(file).update(fs.readFileSync(file));
const signature=signatureHash.digest('hex');
let previous;try{previous=JSON.parse(fs.readFileSync(signatureFile,'utf8')).signature;}catch{}
const cache=path.resolve(root,'.gmcache/build-gms2-operagx-YYC');
if(previous!==signature && fs.existsSync(cache)) {
  if(!cache.startsWith(path.resolve(root,'.gmcache')+path.sep)||fs.lstatSync(cache).isSymbolicLink())throw Error('Unexpected cache path');
  const backup=path.join(root,'.gmcache/gx-yyc-before-'+Date.now());
  fs.renameSync(cache,backup);console.log('Previous target cache preserved at '+backup);
}
const archive = path.join(root,'.build/gx-remote.zip');
const options = JSON.stringify({operagx:{emscriptenSdk:sdk,packageType:'zip'}});
const extraFlags = (process.env.EMCC_CFLAGS || '') + ' --post-js "' + path.join(root,'web/gx/runtime-export.js') + '"';
const run = spawnSync(process.execPath,[cli,'package',path.join(root,'PhigrosLoader-sample.yyp'),'--target=operagx','--runtime=native','--toolchain-options',options,'--output',archive,'--verbose'],{cwd:root,stdio:'inherit',windowsHide:true,env:{...process.env,EMCC_CFLAGS:extraFlags}});
if (run.status !== 0) process.exit(run.status || 1);
fs.writeFileSync(signatureFile,JSON.stringify({signature})+'\n');
// Expand only a package generated successfully by the command above.
const escaped = value => "'"+value.replaceAll("'","''")+"'";
const expand = spawnSync('powershell.exe',['-NoProfile','-Command',`Expand-Archive -LiteralPath ${escaped(archive)} -DestinationPath ${escaped(out)} -Force`],{cwd:root,stdio:'inherit',windowsHide:true});
if (expand.status !== 0) process.exit(expand.status || 1);
const prepare = spawnSync(process.execPath,[path.join(root,'web/gx/prepare.mjs'),out],{cwd:root,stdio:'inherit',windowsHide:true});
process.exitCode = prepare.status || 0;
