module FMM
  module TestMachine
    extend self

    def create
      { _machine:
        {
          current: :new,
          transitions: TRANSITIONS,
          callbacks: CALLBACKS,
          aliases: ALIASES
        }
      }
    end

    TRANSITIONS = {
      begin: { :new => :step1 },
      advance: { :step1 => :step2, :step2 => :step3 },
      end: { :step3 => :done },
      aliased: { :aliased => :recognized },
      bail: { :* => :bail }
    }.freeze

    CALLBACKS = {
      step1: lambda { |state, event, payload| step1_callback(state, event, payload) },
      aliased: lambda { |s,e,p| aliased_callback(s,e,p) },
      :* => lambda { |s,e,p| all_callback(s,e,p) }
    }.freeze

    ALIASES = {
      step2: [ :aliased ],
      step3: [ :aliased ]
    }.freeze

    # some testing methods
    [ :step1, :aliased, :all ].each do |m|
      define_method(:"#{m}_callback") do |state, event, payload|
        call_history = (state[m] || []).push({ event => payload })
        state.merge({ m => call_history })
      end
    end
  end
end
