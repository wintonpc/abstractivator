require 'rspec'
require 'abstractivator/fiber_defer'
require 'eventmachine'
require 'mongoid'

describe Abstractivator::FiberDefer do
  include Abstractivator::FiberDefer

  describe '#with_fiber_defer' do
    it 'raises an error when an eventmachine reactor is not running' do
      expect{with_fiber_defer}.to raise_error /reactor/
    end
    it 'does nothing when no block is provided' do
      EM.run do
        with_fiber_defer
        EM.stop
      end
    end
    it 'calls the block' do
      EM.run do
        expect{|b| with_fiber_defer(&b)}.to yield_control
        EM.stop
      end
    end
    context 'when a proc guard is provided' do
      it 'invokes the guard upon entering the block' do
        called_it = false
        guard = proc { called_it = true }
        EM.run do
          with_fiber_defer(guard) do
            expect(called_it).to be true
            EM.stop
          end
        end
      end
    end
    context 'when a hash guard is provided' do
      before(:each) { Thread.current[:meaning] = 42 }
      after(:each) { Thread.current[:meaning] = nil }
      it 'propagates the thread/fiber-local variables into the block' do
        EM.run do
          guard = {
            Thread.current[:meaning] => proc { |x| Thread.current[:meaning] = x }
          }
          with_fiber_defer(guard) do
            expect(Thread.current[:meaning]).to eql 42
            EM.stop
          end
        end
      end
    end
    context 'when an invalid guard is provided' do
      it 'raises an error' do
        EM.run do
          expect{with_fiber_defer(3){ }}.to raise_error /guard/
          EM.stop
        end
      end
    end
  end

  describe '#fiber_defer' do
    context 'when called outside a with_fiber_defer block' do
      it 'raises an error' do
        expect{fiber_defer{}}.to raise_error /with_fiber_defer/
      end
    end
    context 'when it is not passed a block' do
      it 'raises an error' do
        EM.run do
          with_fiber_defer do
            expect{fiber_defer}.to raise_error /must be passed an action/
            EM.stop
          end
        end
      end
    end
    it 'executes the block on a background thread' do
      EM.run do
        with_fiber_defer do
          main_thread = Thread.current
          executed = false
          fiber_defer do
            expect(Thread.current).to_not eql main_thread
            executed = true
          end
          expect(executed).to be true
          EM.stop
        end
      end
    end
    it 'returns the value of its block' do
      EM.run do
        with_fiber_defer do
          expect(fiber_defer{42}).to eql 42
          EM.stop
        end
      end
    end
    it 'raises an error raised by its block' do
      EM.run do
        with_fiber_defer do
          expect{fiber_defer{raise 'oops'}}.to raise_error 'oops'
          EM.stop
        end
      end
    end
    it 'works with simultaneous deferred actions' do
      EM.run do
        log = []
        EM.next_tick do
          with_fiber_defer do
            log << 'start1'
            fiber_defer { sleep(0.1) }
            log << 'end1'
          end
        end
        EM.next_tick do
          with_fiber_defer do
            log << 'start2'
            fiber_defer { sleep(0.2) }
            log << 'end2'
            expect(log).to eql %w(start1 start2 end1 end2)
            EM.stop
          end
        end
        EM.next_tick do
          sleep(0.3)
        end
      end
    end
    context 'when a proc guard is provided' do
      it 'invokes the guard upon entering and exiting the block' do
        called_count = 0
        guard = proc { called_count += 1 }
        EM.run do
          with_fiber_defer do
            fiber_defer(guard) do
              expect(called_count).to eql 1
            end
            expect(called_count).to eql 2
            EM.stop
          end
        end
      end
      context 'and an inherited guard is provided' do
        it 'invokes the inherited guard and then the local guard upon entering and exiting the block' do
          the_log = []
          guard1 = proc { the_log << 'guard1' }
          guard2 = proc { the_log << 'guard2' }
          EM.run do
            with_fiber_defer(guard1) do
              expect(the_log).to eql %w(guard1)
              fiber_defer(guard2) do
                expect(the_log).to eql %w(guard1 guard1 guard2)
              end
              expect(the_log).to eql %w(guard1 guard1 guard2 guard1 guard2)
              EM.stop
            end
          end
        end
      end
    end
    context 'when a hash guard is provided' do
      before(:each) do
        Thread.current[:a] = 1
        Thread.current[:b] = 2
      end
      after(:each) do
        Thread.current[:a] = nil
        Thread.current[:b] = nil
      end
      it 'propagates the thread/fiber-local variables into the block' do
        EM.run do
          with_fiber_defer do
            Thread.current[:a] = 42
            guard = { Thread.current[:a] => proc {|x| Thread.current[:a] = x} }
            fiber_defer(guard) do
              expect(Thread.current[:a]).to eql 42
            end
            expect(Thread.current[:a]).to eql 42
            EM.stop
          end
        end
      end
      context 'and an inherited guard is provided' do
        it 'applies the inherited guard and then the local guard upon entering and exiting the block' do
          EM.run do
            guard1 = {
              Thread.current[:a] => proc {|x| Thread.current[:a] = x},
              Thread.current[:b] => proc {|x| Thread.current[:b] = x}
            }
            with_fiber_defer(guard1) do
              Thread.current[:b] = 22
              Thread.current[:c] = 33
              guard2 = {
                Thread.current[:b] => proc {|x| Thread.current[:b] = x},
                Thread.current[:c] => proc {|x| Thread.current[:c] = x}
              }
              fiber_defer(guard2) do
                expect(Thread.current[:a]).to eql 1
                expect(Thread.current[:b]).to eql 22
                expect(Thread.current[:c]).to eql 33
              end
              expect(Thread.current[:a]).to eql 1
              expect(Thread.current[:b]).to eql 22
              expect(Thread.current[:c]).to eql 33
              EM.stop
            end
          end
        end
      end
    end
    context 'when an invalid guard is provided' do
      it 'raises an error' do
        EM.run do
          with_fiber_defer do
            expect{fiber_defer(3){ }}.to raise_error /guard/
          end
          EM.stop
        end
      end
    end
  end

  describe '#mongoid_fiber_defer' do
    it 'restores the mongoid database override within and after the deferred action' do
      the_log = []
      log = proc { the_log << Mongoid::Threaded.database_override }
      EM.run do
        with_fiber_defer do
          Mongoid.override_database('good')
          mongoid_fiber_defer do
            sleep(0.1) # let the main thread proceed to set 'bad'
            log.call # regardless, we should get 'good' here
            EM.next_tick do
              Mongoid.override_database('bad') # something else sets 'bad' again on the main thread
              log.call
            end
            sleep(0.1) # allow main thread to run
          end
          log.call # back on the main thread now, we should see 'good'
          EM.stop
        end
        Mongoid.override_database('bad') # this runs right after the background thread is started
        log.call
      end
      expect(the_log).to eql %w(bad good bad good)
    end
    it 'returns the value of its block' do
      EM.run do
        with_fiber_defer do
          expect(mongoid_fiber_defer{42}).to eql 42
          EM.stop
        end
      end
    end
  end

end
