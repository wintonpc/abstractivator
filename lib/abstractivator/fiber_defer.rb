require 'fiber'

begin
  require 'eventmachine'
rescue => e
  raise 'Abstractivator::FiberDefer requires eventmachine but it is unavailable.'
end

module Abstractivator

  # Provides a pair of functions for handling long-running requests in a thread pool.
  # Uses fibers to maintain a somewhat normal coding style (hides explicit continuations).
  # with_fiber_defer defines the lexical scope of all work being done.
  # fiber_defer defines the portion of the work to be done in the worker thread.
  # Control passes from the calling thread, to the worker thread, and back to the calling thread.
  # The code is capable of propagating thread variables (e.g., Mongoid::Threaded.database_override)
  # across these thread/fiber transitions.
  # See EventMachine::defer for more information.
  module FiberDefer
    ROOT_FIBER = Fiber.current

    def with_fiber_defer(thread_var_guard=nil, &block)
      raise 'this method requires an eventmachine reactor to be running' unless EM.reactor_running?
      return unless block
      guard_proc = make_guard_proc(thread_var_guard)
      f = Fiber.new do
        guard_proc.call
        begin
          Thread.current[:fiber_defer_guard_proc] = guard_proc # make available to fiber_defer calls
          block.call
        ensure
          Thread.current[:fiber_defer_guard_proc] = nil
        end
      end
      f.resume
    end

    def fiber_defer(thread_var_guard=nil, &action)
      inherited_guard_proc = Thread.current[:fiber_defer_guard_proc]
      raise 'fiber_defer must be called within a with_fiber_defer block' unless inherited_guard_proc
      raise 'fiber_defer must be passed an action to defer (the block)' unless action
      local_guard_proc = make_guard_proc(thread_var_guard)
      guard_proc = proc do
        inherited_guard_proc.call
        local_guard_proc.call
      end
      begin
        basic_fiber_defer do
          # in the background thread
          guard_proc.call
          action.call
        end
      ensure
        guard_proc.call
      end
    end

    def mongoid_fiber_defer(&action)
      thread_vars = {
        Mongoid::Threaded.database_override => proc { |db| Mongoid.override_database(db) }
      }
      fiber_defer(thread_vars, &action)
    end

    private

    def make_guard_proc(x)
      case x
      when Proc
        x
      when Hash
        proc do
          x.each do |value, setter|
            setter.call(value)
          end
        end
      when nil
        proc { }
      else
        raise "Cannot turn #{x.inspect} into a guard proc"
      end
    end

    def basic_fiber_defer(&action)
      f = Fiber.current
      raise 'fiber_defer must be called within a with_fiber_defer block' if f == ROOT_FIBER

      safe_action = proc do
        begin
          [action.call, nil]
        rescue Exception => e
          [nil, e]
        end
      end

      EM.defer(safe_action, proc { |result, error| f.resume([result, error]) })
      result, error = Fiber.yield
      raise error if error
      result
    end
  end
end
