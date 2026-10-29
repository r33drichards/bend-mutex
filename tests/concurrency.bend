import Base
import ../mutex.bend as M

@unsafe
def mark(pair: Array<U32> & U32, owner: U32) -> M.Guard:
  (cells, active) = pair
  M.Guard{Array.set.fin(U32, Array.atomic.add(cells, 3, active)), owner}

@unsafe
def entered(g: M.Guard) -> M.Guard:
  match g:
    case M.Guard{cells, owner}: mark(Array.atomic.add(cells, 2, 1), owner)

@unsafe
def leaving(g: M.Guard) -> M.Guard:
  match g:
    case M.Guard{cells, owner}:
      M.Guard{Array.set.fin(U32, Array.atomic.add(cells, 2, 4294967295)), owner}

@unsafe
def attempt(r: M.Attempt) -> M.Mutex & Bool:
  match r:
    case M.Busy{m}: (m, False{})
    case M.Held{g}: M.release(leaving(M.update(entered(g), x => U32.add(x, 1))))

@unsafe
def worker(n: Nat, m: M.Mutex, +owner: U32, count: U32) -> M.Mutex & U32:
  match n:
    case 0n: (m, count)
    case 1n+p: again(p, attempt(M.try_lock(m, owner)), owner, count)

@unsafe
def again(n: Nat, pair: M.Mutex & Bool, owner: U32, count: U32) -> M.Mutex & U32:
  (m, ok) = pair
  worker(n, m, owner, U32.add(count, Bool.pick(U32, ok, 1, 0)))

@unsafe
def merged(l: M.Mutex & U32, r: M.Mutex & U32) -> M.Mutex & U32:
  (lm, lc) = l
  (rm, rc) = r
  (M.join(lm, rm), U32.add(lc, rc))

@unsafe
def launch(pair: M.Mutex & M.Mutex) -> M.Mutex & U32:
  (a, b) = pair
  l r = worker(10000n, a, 1, 0) worker(10000n, b, 2, 0)
  merged(l, r)

@unsafe
def report_cells(cells: Array<U32>, count: U32) -> IO(Unit):
  report_read(Array.atomic.add(cells, 1, 0), count)

@unsafe
def report_read(pair: Array<U32> & U32, count: U32) -> IO(Unit):
  (cells, value) = pair
  do IO<Unit>:
    IO.print(U32.show(count))
    IO.print(U32.show(value))
    report_errors(Array.atomic.add(cells, 3, 0))

@unsafe
def report_errors(pair: Array<U32> & U32) -> IO(Unit):
  (cells, errors) = pair
  do IO<Unit>:
    IO.print(U32.show(errors))
    report_idle(Array.atomic.add(cells, 0, 0))

@unsafe
def report_idle(pair: Array<U32> & U32) -> IO(Unit):
  (cells, owner) = pair
  do IO<Unit>:
    IO.print(U32.show(owner))
    report_active(Array.atomic.add(cells, 2, 0))

@unsafe
def report_active(pair: Array<U32> & U32) -> IO(Unit):
  (cells, active) = pair
  IO.print(U32.show(active))

@unsafe
def report(pair: M.Mutex & U32) -> IO(Unit):
  (m, count) = pair
  report_mutex(m, count)

@unsafe
def report_mutex(m: M.Mutex, count: U32) -> IO(Unit):
  match m:
    case M.Mutex{cells}: report_cells(cells, count)

@unsafe
def main() -> IO(Unit):
  report(launch(M.fork(M.create(0))))
