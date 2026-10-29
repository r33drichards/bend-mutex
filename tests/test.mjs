import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readFileSync, writeFileSync, readdirSync, mkdtempSync, rmSync, mkdirSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join, resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const root=resolve(import.meta.dirname,'..');
const bend=process.env.BEND || 'bend';
function cmd(args,cwd=root,bin=bend) {
 const r=spawnSync(bin,args,{cwd,encoding:'utf8',timeout:60000,env:{...process.env,BEND_NO_TELEMETRY:'1'}});
 assert.ifError(r.error);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout.trim();
}
mkdirSync(join(root,'.build'),{recursive:true});
console.log(cmd(['PROOF.bend']));
cmd(['PROOF.bend','-o','.build/PROOF.bendtt']);
cmd(['model.bend','-o','.build/model.mjs']);
cmd(['mutex.bend','-o','.build/mutex.mjs']);
const {default:M}=await import(pathToFileURL(join(root,'.build/mutex.mjs')));
const {default:S}=await import(pathToFileURL(join(root,'.build/model.mjs')));
for(const id of [0,3,4294967295]) assert.equal(M.try_lock(M.create(7),id).$,'Busy');
let pair=M.fork(M.create(7));
let a=M.try_lock(pair.fst,1);assert.equal(a.$,'Held');
let b=M.try_lock(pair.snd,2);assert.equal(b.$,'Busy');
a.guard=M.update(a.guard,x=>x+5);
assert.equal(a.guard.cells[1],12);
let rel=M.release(a.guard);assert.equal(rel.snd,true);
b=M.try_lock(b.mutex,2);assert.equal(b.$,'Held');
assert.equal(M.release(b.guard).snd,true);
const auto=M.try_update(M.create(4),1,x=>x*3);assert.equal(auto.snd,true);assert.equal(auto.fst.cells[1],12);
// Adversarial internal tests bypass the affine API deliberately to test CAS refusal.
for(const [owner,wrong] of [[1,2],[2,1]]) {
 const held=M.try_lock(M.create(0),owner).guard;
 const wrongRelease=M.release({$: 'Guard',cells:held.cells,owner:wrong});
 assert.equal(wrongRelease.snd,false);assert.equal(held.cells[0],owner);
 assert.equal(M.try_lock({$: 'Mutex',cells:held.cells},owner).$,'Busy');
 assert.equal(M.release(held).snd,true);
 assert.equal(M.release(held).snd,false); // double release before reacquisition
}
let transitions=0;
const actions=['AcquireA','AcquireB','ReleaseA','ReleaseB'];
function walk(state,depth) {
 if(!depth)return;
 for(const action of actions) {
  const owner=action.endsWith('A')?1:2;
  const cells=new Uint32Array([S.encode(state),99,0,0]);
  const r=action.startsWith('Acquire')?M.try_lock({$: 'Mutex',cells},owner):M.release({$: 'Guard',cells,owner});
  if(action.startsWith('Acquire'))assert.equal(r.$==='Held',S.encode(state)===0);
  else assert.equal(r.snd,S.encode(state)===owner);
  const next=S.step(state,{$:action});
  assert.equal(cells[0],S.encode(next));assert.equal(S.safe(next),true);
  transitions++;walk(next,depth-1);
 }
}
walk(S.initial(),8);
console.log(`PASS: guarded update/handoff, invalid owners/releases, reentrancy, ${transitions} runtime/model transitions through depth 8`);
for(const [name,file,before,after] of [
 ['grant while busy','model.bend','a || Bool.not(b)','True{}'],
 ['wrong release clears peer','model.bend','State{a, False{}}','State{False{}, False{}}'],
 ['runtime grant predicate','protocol.bend','U32.is_zero(old)','True{}'],
 ['CAS ignores expected','protocol.bend','U32.is_eq(old, expected)','True{}'],
]) {
 const dir=mkdtempSync(join(tmpdir(),'bend-mutex-mutant-'));
 try {
  for(const f of readdirSync(root).filter(f=>f.endsWith('.bend')))writeFileSync(join(dir,f),readFileSync(join(root,f)));
  const s=readFileSync(join(dir,file),'utf8');assert.ok(s.includes(before));writeFileSync(join(dir,file),s.replace(before,after));
  const r=spawnSync(bend,['PROOF.bend'],{cwd:dir,encoding:'utf8',timeout:30000,env:{...process.env,BEND_NO_TELEMETRY:'1'}});
  assert.ifError(r.error);assert.notEqual(r.status,0);assert.match(r.stdout+r.stderr,/SOME PROOFS FAIL/);
  console.log(`PASS: checker rejects ${name}`);
 } finally {rmSync(dir,{recursive:true,force:true});}
}
// The guard is affine even though the runtime implementation is outside the proof kernel.
const copied=spawnSync(bend,['tests/guard-copy-rejected.bend','-o','.build/guard-copy.mjs'],{cwd:root,encoding:'utf8',env:{...process.env,BEND_NO_TELEMETRY:'1'}});
assert.notEqual(copied.status,0);assert.match(copied.stdout+copied.stderr,/consumed more than once/);
console.log('PASS: guard duplication rejected by affine checker');
// Test sensitivity to an actual runtime release bug, outside the pure law model.
const badDir=mkdtempSync(join(tmpdir(),'bend-mutex-runtime-'));
try {
 for(const f of ['mutex.bend','protocol.bend'])writeFileSync(join(badDir,f),readFileSync(join(root,f)));
 const bad=readFileSync(join(badDir,'mutex.bend'),'utf8').replace('Array.atomic.cas(cells, 0, owner, 0)','Array.atomic.exch(cells, 0, 0)');
 writeFileSync(join(badDir,'mutex.bend'),bad);cmd(['mutex.bend','-o','bad.mjs'],badDir);
 const {default:Bad}=await import(pathToFileURL(join(badDir,'bad.mjs')));
 const guard=Bad.try_lock(Bad.create(0),1).guard;
 Bad.release({$: 'Guard',cells:guard.cells,owner:2});
 assert.notEqual(guard.cells[0],1,'mutant must violate invalid-release preservation');
 console.log('PASS: runtime invalid-release test detects unconditional-unlock mutant');
} finally {rmSync(badDir,{recursive:true,force:true});}
cmd(['tests/concurrency.bend','-o','.build/concurrency']);
let total=0,attempts=0,contended=0;
for(const threads of [1,2,4,8])for(let i=0;i<3;i++) {
 const values=cmd(['+RTS','--threads',String(threads)],root,join(root,'.build/concurrency')).split('\n').map(Number);
 assert.equal(values.length,5);const [successes,data,violations,owner,active]=values;
 assert.ok(successes>0 && successes<=20000);assert.equal(data,successes);assert.equal(violations,0);assert.equal(owner,0);assert.equal(active,0);
 total+=successes;attempts+=20000;if(successes<20000)contended++;
 console.log(`PASS: ${threads} CPU threads, ${successes}/20000 acquisitions, counter=${data}, overlap=0, released`);
}
assert.ok(contended>0,'must observe actual failed acquisition under contention');
console.log(`PASS: ${total}/${attempts} acquisitions across 12 native runs; ${contended} runs observed contention`);
