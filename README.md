
# FMM

FMM is short for "functional micromachines;" it is based on 
the [micromachine](https://github.com/soveran/micromachine/)
gem, a nicely compact little finite state machine implementation.

Micromachine is an imperative design, based on the methods and 
mutable state of an instance of class `MicroMachine`. FMM takes 
a functional approach, where (a) the state machine operations
are pure functions that take the current state as an argument
and return an updated state, and (b) instead of building
the machine imperatively by calls to `machine.on(...)`, we
assume the machine is given as a data structure of a certain
format. (A validation method is included.) 

Updates soon. In the meantime, have a look at the test suite.
