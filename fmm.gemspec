Gem::Specification.new do |s|
  s.name = "fmm"
  s.version = "0.1.0"
  s.summary = %{FMM: a minimal FSM with functional leanings}
  s.description = %Q{FMM is a small finite state machine implementation based on Michael Martens' micromachine, but recast in the idioms of functional programming: instead of mutable state we use arguments and return values, and instead of methods bound to an instance of a class like MicroMachine, we provide utility functions that operate on any suitable data structure.}
  s.author = ["Erik Cameron"]
  s.email = ["root@erikcameron.org"]
  s.homepage = "http://github.com/erikcameron/fmm"
  s.license = "MIT"

  s.files = `git ls-files`.split("\n")

  s.add_development_dependency "rspec"
end
