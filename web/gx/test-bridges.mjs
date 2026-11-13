import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {syncBridges} from './sync-bridges.mjs';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'phi-gx-bridges-'));
try {
  fs.mkdirSync(path.join(temporary,'extensions/I_HTML5'),{recursive:true});
  fs.mkdirSync(path.join(temporary,'datafiles'));
  for(const name of ['I_GXDrop.js','gx_video_boot.js']) {
    fs.copyFileSync(path.join(root,'extensions/I_HTML5',name),path.join(temporary,'extensions/I_HTML5',name));
  }
  const bridge=path.join(temporary,'extensions/I_HTML5/I_GXDrop.js');
  const before=fs.readFileSync(bridge,'utf8');
  const shaderStart=before.indexOf('    (function installGxShader(g) {');
  const shaderEnd=before.indexOf('    })(global);',shaderStart)+'    })(global);'.length;
  assert.ok(shaderStart>=0&&shaderEnd>shaderStart,'Complete shader bridge required');
  const shader=before.slice(shaderStart,shaderEnd);
  syncBridges(temporary);
  const once=fs.readFileSync(bridge,'utf8');
  syncBridges(temporary);
  assert.equal(fs.readFileSync(bridge,'utf8'),once,'Repeated sync must preserve every byte');
  assert.ok(once.includes(shader),'Sync must preserve the entire shader bridge');
  assert.equal(once.split('(function installGxShader(g)').length,2);
  assert.equal(once.split('(function installGxVideo(g)').length,2);
  assert.equal(fs.readFileSync(path.join(temporary,'datafiles/gx_drop.js'),'utf8'),once);
  assert.equal(fs.readFileSync(path.join(temporary,'datafiles/gx_video_boot.js'),'utf8'),fs.readFileSync(path.join(root,'extensions/I_HTML5/gx_video_boot.js'),'utf8'));
  console.log('PASS: repeated bridge sync preserves shaders and matches Included Files');
} finally {
  // This path comes directly from mkdtemp; never remove a caller-supplied path.
  fs.rmSync(temporary,{recursive:true,force:true});
}
