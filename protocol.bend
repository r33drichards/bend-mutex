import Base

# Pure specification of the runtime's strong CAS return/update contract.
def cas(+old: U32, expected: U32, desired: U32) -> U32:
  Bool.pick(U32, U32.is_eq(old, expected), desired, old)

def granted(old: U32) -> Bool:
  U32.is_zero(old)

def valid_owner(+owner: U32) -> Bool:
  U32.is_eq(owner, 1) || U32.is_eq(owner, 2)
