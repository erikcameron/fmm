module FMM
  class InvalidEvent < NoMethodError; end
  class InvalidState < ArgumentError; end
  class InvalidMachine < TypeError; end   # this is ultimately a data error

  extend self

  # validate a state machine; defacto specification; no
  # state for which this method returns true should ever
  # crash with an InvalidMachine error
  def validate!(state)
    # The state is a Hash-like object (HLO) with a value
    # at key :_machine
    unless state[:_machine]
      raise InvalidMachine, "no state machine found: #{state}"
    end

    # The machine has a current state 
    unless state[:_machine][:current]
      raise InvalidMachine, "no current state: #{state}"
    end

    # The machine specifies a set of transitions (and hence states)
    unless state[:_machine][:transitions]
      raise InvalidMachine, "you must specify some transitions: #{state}"
    end

    # The transitions table must be a HLO...
    unless state[:_machine][:transitions].is_a?(Hash)
      raise InvalidMachine, "transitions must be a hash: #{state}"
    end

    # ...all of whose values are also HLOs
    unless state[:_machine][:transitions].values.map { |v| v.is_a?(Hash) }.inject(:&)
      raise InvalidMachine, "transitions must be a hash of hashes: #{state}"
    end
      
    # Callbacks (which are all post-transition; see below) are optional,
    # but if they exist...
    if state[:_machine][:callbacks]
      # ...they must be in a HLO...
      unless state[:_machine][:callbacks].is_a?(Hash)
        raise InvalidMachine, "callbacks must be a hash: #{state}"
      end
      
      # ...whose values are either callables or collections thereof
      valid_callbacks = state[:_machine][:callbacks].values.flatten.map do |v| 
        v.respond_to?(:call)
      end.inject(:&)
      
      unless valid_callbacks
        raise InvalidMachine, "callbacks must be callables or arrays thereof: #{state}"
      end
    end
   
    # Aliases are optional, but if they exist...
    if state[:_machine][:aliases]
      # ...they must be in a HLO. This is all we can actually
      # say about aliases, other than this: The keys of this
      # HLO correspond to states, but can be of any type; 
      # nonexistent states simply won't be consulted. Similarly,
      # the values are all either names of states or collections 
      # thereof, but that doesn't actually place any type limitation
      # on what the values _are_, other than not letting them be
      # arrays, because they will be flattened.
      unless state[:_machine][:aliases].is_a?(Hash)
        raise InvalidMachine, "aliases must be a hash: #{state}"
      end
    end
    true
  end
        
  # trigger state changes
 
  def trigger(state, event, payload = nil)
    payload.freeze if payload.respond_to?(:freeze)
    trigger?(state, event) and change(state, event, payload)
  end

  def trigger!(state, event, payload = nil)
    trigger(state, event, payload) or
      raise InvalidState, "Event '#{event}' not valid from state :'#{current(state)}'"
  end

  # talk to the machine object
  
  def current(state)
    state[:_machine][:current]
  rescue => err
    # reraise as an explicit InvalidMachine;
    # get the orig out of #cause
    raise InvalidMachine, '#current'
  end  

  def transitions(state)
    state[:_machine][:transitions]
  rescue => err
    raise InvalidMachine, '#transitions'
  end

  def callbacks(state)
    state[:_machine][:callbacks]  || {}
  rescue => err
    raise InvalidMachine, '#callbacks'
  end

  def aliases_for(state)
    state[:_machine][:aliases] ? state[:_machine][:aliases][current(state)] : nil
  end

  # from most to least specific, as this is the order
  # in which we will resolve available transitions
  # and run callbacks
  def all_names_for(state)
    [ current(state), aliases_for(state), :* ].flatten
  end

  def trigger?(state, event)
    unless transitions(state).has_key?(event)
      raise InvalidEvent, "no such event #{event}"
    end
    resolve_next_state_name(state, event) ? true : false
  end

  def events(state)
    transitions(state).keys
  end

  def triggerable_events(state)
    events(state).select { |event| trigger?(state, event) }
  end

  def machine_states(state)
    transitions(state).values.map(&:to_a).flatten.uniq
  end

private

  # 
  # the elbow grease
  #
  # there was a whole one-person debate here about the
  # point/utility of pre-transition callbacks; if they
  # actually prove to be something useful, we can add them
  # without breaking existing machines. ([:_machine][:before],
  # at which point, we can just construe [:_machine][:callbacks]
  # as synonymous with [:post]) for now, i don't really see what 
  # purpose they serve in this sort of application other than 
  # being able to veto state changes, maybe; for now i say poo 
  # on them

  def change(state, event, payload)
    state   = update_machine_state(state, resolve_next_state_name(state, event))
    # post callbacks; these we very much want
    resolve_callbacks(state).each do |callback|
      state = callback.call(state, event, payload)
    end
    state
  rescue => err
    raise InvalidMachine.new('#change')
  end

  def resolve_callbacks(state)
    all_names_for(state).map { |n| callbacks(state)[n] }.flatten.compact 
  end

  def resolve_next_state_name(state, event)
    all_names_for(state).map { |n| transitions(state)[event][n] }.compact.first
  end

  def update_machine_state(state, target)
    raise InvalidState, "nil target" unless target
    new_machine = state[:_machine].merge({ current: target })
    state.merge({ _machine: new_machine })
  end
end
