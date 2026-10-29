import Base
import ../mutex.bend as M

def copy_guard(g: M.Guard) -> M.Guard & M.Guard:
  (g, g)
