import Base

# Independent client permissions; Both is representable and forbidden by safety.
type State is Data:
  State{a: Bool, b: Bool}

type Action is Data:
  AcquireA{}
  AcquireB{}
  ReleaseA{}
  ReleaseB{}

def initial() -> State:
  State{False{}, False{}}

def safe(s: State) -> Bool:
  match s:
    case State{a, b}: Bool.not(a && b)

def access_a(s: State) -> Bool:
  match s:
    case State{a, b}: a

def access_b(s: State) -> Bool:
  match s:
    case State{a, b}: b

# A successful CAS observes zero (neither client holds permission).
# Failed/reentrant acquisition preserves the existing permissions.
# Release revokes only the caller's permission; an invalid release is a no-op.
def step(s: State, e: Action) -> State:
  match s e:
    case State{a, +b} AcquireA{}: State{a || Bool.not(b), b}
    case State{+a, b} AcquireB{}: State{a, b || Bool.not(a)}
    case State{a, b} ReleaseA{}: State{False{}, b}
    case State{a, b} ReleaseB{}: State{a, False{}}

def run(events: List<&2, Action>, s: State) -> State:
  match events:
    case Nil{}: s
    case Con{e, tail}: run(tail, step(s, e))

def encode(s: State) -> U32:
  match s:
    case State{a, b}: U32.add(Bool.pick(U32, a, 1, 0), Bool.pick(U32, b, 2, 0))
