import Base
import ./protocol.bend as P

# Constructors are internal by API convention; Bend modules are not a security boundary.
# Only handles may be forked. Guards must never be copied or forged.
type Mutex is Type:
  Mutex{cells: Array<U32>}
type Guard is Type:
  Guard{cells: Array<U32>, owner: U32}
type Attempt is Type:
  Busy{mutex: Mutex}
  Held{guard: Guard}

def create(value: U32) -> Mutex:
  Mutex{Array.set(U32, Array.new(U32, 2n, 0), 1, value)}

@unsafe
def fork_result(pair: Array<U32> & Array<U32>) -> Mutex & Mutex:
  (a, b) = pair
  (Mutex{a}, Mutex{b})

@unsafe
def fork(m: Mutex) -> Mutex & Mutex:
  match m:
    case Mutex{cells}:
      fork_result(Array.fork(U32, cells))

@unsafe
def join(a: Mutex, b: Mutex) -> Mutex:
  match a b:
    case Mutex{ac} Mutex{bc}: Mutex{Array.join(U32, ac, bc)}

@unsafe
def acquired(ok: Bool, cells: Array<U32>, owner: U32) -> Attempt:
  match ok:
    case False{}: Busy{Mutex{cells}}
    case True{}: Held{Guard{cells, owner}}

@unsafe
def acquire_result(pair: Array<U32> & U32, owner: U32) -> Attempt:
  (cells, old) = pair
  acquired(P.granted(old), cells, owner)

@unsafe
def acquire_valid(valid: Bool, m: Mutex, +owner: U32) -> Attempt:
  match valid m:
    case False{} Mutex{cells}: Busy{Mutex{cells}}
    case True{} Mutex{cells}: acquire_result(Array.atomic.cas(cells, 0, 0, owner), owner)

# Owners 1 and 2 identify the two clients covered by the model.
# One nonblocking attempt: no spin loop or fairness claim.
@unsafe
def try_lock(m: Mutex, +owner: U32) -> Attempt:
  acquire_valid(P.valid_owner(owner), m, owner)

@unsafe
def updated(pair: Array<U32> & U32, owner: U32) -> Guard:
  (cells, old) = pair
  Guard{cells, owner}

@unsafe
def update_read(pair: Array<U32> & U32, owner: U32, f: U32 -> U32) -> Guard:
  (cells, value) = pair
  updated(Array.atomic.exch(cells, 1, f(value)), owner)

# The callback receives a value, never the shared cell address.
@unsafe
def update(g: Guard, f: U32 -> U32) -> Guard:
  match g:
    case Guard{cells, owner}: update_read(Array.atomic.add(cells, 1, 0), owner, f)

@unsafe
def release_result(pair: Array<U32> & U32, +owner: U32) -> Mutex & Bool:
  (cells, old) = pair
  (Mutex{cells}, U32.is_eq(old, owner))

# CAS leaves the lock unchanged if the guard does not own it.
# Legal callers cannot retain a guard after this consuming operation.
@unsafe
def release(g: Guard) -> Mutex & Bool:
  match g:
    case Guard{cells, +owner}: release_result(Array.atomic.cas(cells, 0, owner, 0), owner)

@unsafe
def with_result(r: Attempt, f: U32 -> U32) -> Mutex & Bool:
  match r:
    case Busy{m}: (m, False{})
    case Held{g}: release(update(g, f))

@unsafe
def try_update(m: Mutex, owner: U32, f: U32 -> U32) -> Mutex & Bool:
  with_result(try_lock(m, owner), f)
