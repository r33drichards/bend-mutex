import Base
import ./protocol.bend as P
import ./model.bend as M

law initial_safe:
  {M.safe(M.initial()) == True{} : Bool}

law preservation:
  for +s: M.State
  for +e: M.Action
  {M.safe(s) && M.safe(M.step(s, e)) == M.safe(s) : Bool}

law and_right:
  for +a: Bool
  for +b: Bool
  for h: {a && b == True{} : Bool}
  {b == True{} : Bool}

law safe_step:
  for +s: M.State
  for +e: M.Action
  for h: {M.safe(s) == True{} : Bool}
  {M.safe(M.step(s, e)) == True{} : Bool}

law safe_run:
  for events: List<&2, M.Action>
  for +s: M.State
  for h: {M.safe(s) == True{} : Bool}
  {M.safe(M.run(events, s)) == True{} : Bool}

law exclusion:
  for +s: M.State
  {Bool.not(M.access_a(s) && M.access_b(s)) == M.safe(s) : Bool}

law all_interleavings:
  for +events: List<&2, M.Action>
  {Bool.not(M.access_a(M.run(events, M.initial())) && M.access_b(M.run(events, M.initial()))) == True{} : Bool}

law acquisition_works:
  {M.access_a(M.step(M.initial(), M.AcquireA{})) == True{} : Bool}
law contender_blocked:
  {M.step(M.State{True{}, False{}}, M.AcquireB{}) == M.State{True{}, False{}} : M.State}
law invalid_release:
  {M.step(M.State{True{}, False{}}, M.ReleaseB{}) == M.State{True{}, False{}} : M.State}
law handoff:
  {M.run([M.AcquireA{}, M.ReleaseA{}, M.AcquireB{}], M.initial()) == M.State{False{}, True{}} : M.State}

law refines_AcquireA:
  for +s: M.State
  {M.safe(s) && U32.is_eq(M.encode(M.step(s, M.AcquireA{})), P.cas(M.encode(s), 0, 1)) == M.safe(s) : Bool}

law refines_AcquireB:
  for +s: M.State
  {M.safe(s) && U32.is_eq(M.encode(M.step(s, M.AcquireB{})), P.cas(M.encode(s), 0, 2)) == M.safe(s) : Bool}

law refines_ReleaseA:
  for +s: M.State
  {M.safe(s) && U32.is_eq(M.encode(M.step(s, M.ReleaseA{})), P.cas(M.encode(s), 1, 0)) == M.safe(s) : Bool}

law refines_ReleaseB:
  for +s: M.State
  {M.safe(s) && U32.is_eq(M.encode(M.step(s, M.ReleaseB{})), P.cas(M.encode(s), 2, 0)) == M.safe(s) : Bool}

law grants_only_free:
  {P.granted(0) && Bool.not(P.granted(1)) && Bool.not(P.granted(2)) == True{} : Bool}
