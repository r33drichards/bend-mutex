import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {mkdirSync,readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
const root=resolve(import.meta.dirname,'..');
const bend=process.env.BEND || 'bend';
const kernel=process.env.BENDTT;
assert.ok(kernel,'Set BENDTT to an existing independently built kernel');
const env={...process.env,BEND_NO_TELEMETRY:'1',LEAN_STACK_SIZE_KB:'4194304'};
function run(bin,args) {
 const r=spawnSync(bin,args,{cwd:root,env,encoding:'utf8',timeout:60000});
 assert.ifError(r.error);return r;
}
mkdirSync(resolve(root,'.build'),{recursive:true});
let r=run(bend,['PROOF.bend','--verdict']);
assert.equal(r.status,0,r.stdout+r.stderr);assert.equal(r.stdout.trim(),'ALL PROOFS CHECK');
console.log('Bend --verdict with independent BendTT kernel: ALL PROOFS CHECK');
r=run(bend,['PROOF.bend','-o','.build/PROOF.bendtt']);assert.equal(r.status,0,r.stdout+r.stderr);
const good=readFileSync(resolve(root,'.build/PROOF.bendtt'),'utf8');
const before='LAWS.initial_safe : {(model.safe model.initial) == (.True, ()) : Bool}';
assert.ok(good.includes(before));
const bad=good.replace(before,before.replace('(.True, ())','(.False, ())'));
writeFileSync(resolve(root,'.build/false-claim.bendtt'),bad);
r=run(kernel,['.build/false-claim.bendtt']);
assert.notEqual(r.status,0);assert.match(r.stdout+r.stderr,/SOME PROOFS FAIL/);
console.log('Independent kernel rejects deliberately false initial-safety claim:');
console.log((r.stdout+r.stderr).trim());
