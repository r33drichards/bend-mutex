import Base
import ./model.bend as M
import ./LAWS.bend as Laws

def Laws.initial_safe(): {==}

def Laws.preservation(s, e):
  match s e:
    case M.State{False{}, False{}} M.AcquireA{}: {==}
    case M.State{False{}, False{}} M.AcquireB{}: {==}
    case M.State{False{}, False{}} M.ReleaseA{}: {==}
    case M.State{False{}, False{}} M.ReleaseB{}: {==}
    case M.State{False{}, True{}} M.AcquireA{}: {==}
    case M.State{False{}, True{}} M.AcquireB{}: {==}
    case M.State{False{}, True{}} M.ReleaseA{}: {==}
    case M.State{False{}, True{}} M.ReleaseB{}: {==}
    case M.State{True{}, False{}} M.AcquireA{}: {==}
    case M.State{True{}, False{}} M.AcquireB{}: {==}
    case M.State{True{}, False{}} M.ReleaseA{}: {==}
    case M.State{True{}, False{}} M.ReleaseB{}: {==}
    case M.State{True{}, True{}} M.AcquireA{}: {==}
    case M.State{True{}, True{}} M.AcquireB{}: {==}
    case M.State{True{}, True{}} M.ReleaseA{}: {==}
    case M.State{True{}, True{}} M.ReleaseB{}: {==}

def Laws.and_right(a, b, h):
  match a b:
    case False{} False{}: h
    case False{} True{}: {==}
    case True{} False{}: h
    case True{} True{}: {==}

def Laws.safe_step(s, e, h):
  Laws.and_right(M.safe(s), M.safe(M.step(s, e)),
    Equal.trans(Bool, M.safe(s) && M.safe(M.step(s, e)), M.safe(s), True{},
      Laws.preservation(s, e), h))

def Laws.safe_run(events, s, h):
  match events:
    case Nil{}: h
    case Con{+e, tail}: Laws.safe_run(tail, M.step(s, e), Laws.safe_step(s, e, h))

def Laws.exclusion(s):
  match s:
    case M.State{a, b}: {==}

def Laws.all_interleavings(events):
  Equal.trans(Bool,
    Bool.not(M.access_a(M.run(events, M.initial())) && M.access_b(M.run(events, M.initial()))),
    M.safe(M.run(events, M.initial())), True{},
    Laws.exclusion(M.run(events, M.initial())), Laws.safe_run(events, M.initial(), Laws.initial_safe()))

def Laws.acquisition_works(): {==}
def Laws.contender_blocked(): {==}
def Laws.invalid_release(): {==}
def Laws.handoff(): {==}

def Laws.refines_AcquireA(s):
  match s:
    case M.State{False{}, False{}}: {==}
    case M.State{False{}, True{}}: {==}
    case M.State{True{}, False{}}: {==}
    case M.State{True{}, True{}}: {==}

def Laws.refines_AcquireB(s):
  match s:
    case M.State{False{}, False{}}: {==}
    case M.State{False{}, True{}}: {==}
    case M.State{True{}, False{}}: {==}
    case M.State{True{}, True{}}: {==}

def Laws.refines_ReleaseA(s):
  match s:
    case M.State{False{}, False{}}: {==}
    case M.State{False{}, True{}}: {==}
    case M.State{True{}, False{}}: {==}
    case M.State{True{}, True{}}: {==}

def Laws.refines_ReleaseB(s):
  match s:
    case M.State{False{}, False{}}: {==}
    case M.State{False{}, True{}}: {==}
    case M.State{True{}, False{}}: {==}
    case M.State{True{}, True{}}: {==}

def Laws.grants_only_free(): {==}
