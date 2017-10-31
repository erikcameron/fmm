require 'spec_helper'
require './lib/fmm.rb'
require './spec/test_machine.rb'

describe FMM do
  let(:state) { FMM::TestMachine.create }

  it "validates the test machine" do
    expect(FMM.validate!(state)).to eq(true)
  end

  context "when advancing" do 
    let(:new_state) { FMM.trigger!(state, :begin) }
      
    it "accepts begin" do
      expect(FMM.current(new_state)).to eq(:step1)
    end

    it "doesn't mutate the original state object" do
      expect(FMM.current(state)).to eq(:new)
    end
    
    it "runs step1 callback" do
      expect(new_state[:step1]).to eq([{ begin: nil }])
    end
    
    it "runs the * callback" do
      expect(new_state[:all]).to eq([{ begin: nil }])
    end 
    
    it "doesn't run uncalled for callbacks" do
      expect(new_state[:aliased]).to be(nil)
    end

    it "refuses invalid transitions" do
      bad_transition_return = FMM.trigger(state, :end)
      expect(bad_transition_return).to be(false)
    end

    it "raises on invalid transition with trigger!" do
      expect { FMM.trigger!(state, :end) }.to raise_error(FMM::InvalidState)
    end

    it "raises on invalid event no matter what" do
      expect { FMM.trigger(state, :no_such_event) }.to raise_error(FMM::InvalidEvent) 
    end

    it "passes payload to callback" do
      payloaded_state = FMM.trigger!(state, :begin, :a_very_simple_payload)
      expect(payloaded_state[:all]).to eq([{ begin: :a_very_simple_payload }])
    end 

    it "accepts the * state in transitions" do 
      bailed_state = FMM.trigger!(state, :bail)
      expect(FMM.current(bailed_state)).to eq(:bail)
    end

    context "further" do
      let(:step2_state) { FMM.trigger!(new_state, :advance) } 
      
      it "sets step2 state" do  
        expect(FMM.current(step2_state)).to eq(:step2)
      end

      it "runs callbacks for aliased states" do 
        expect(step2_state[:aliased]).to eq([{ advance: nil }])
      end
     
      it "recognizes aliased states in the transition table" do 
        aliased_state = FMM.trigger!(step2_state, :aliased)
        expect(FMM.current(aliased_state)).to eq(:recognized)
      end
      
      it "recognizes when aliases don't apply in the transition table" do
        expect { FMM.trigger!(FMM.trigger!(step2_state, :bail), :aliased) }.to raise_error(FMM::InvalidState)
      end
    end
  end
end
