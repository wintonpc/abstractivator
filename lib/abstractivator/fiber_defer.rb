require 'fiber'

begin
  require 'eventmachine'
rescue => e
  raise 'Abstractivator::FiberDefer requires eventmachine but it is unavailable.'
end

module Abstractivator
  module FiberDefer
    ROOT_FIBER = Fiber.current

    def with_fiber_defer(&block)
      raise 'this method requires an eventmachine reactor to be running' unless EM.reactor_running?
      Fiber.new{block.call}.resume if block
    end

    def fiber_defer(&action)
      f = Fiber.current
      raise 'fiber_defer must be passed an action to defer (the block)' unless action
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

    def mongoid_fiber_defer(&action)
      db = Mongoid::Threaded.database_override
      fiber_defer do
        # in the background thread
        Mongoid.override_database(db) # set the db to what it was in the main thread
        action.call
      end
      Mongoid.override_database(db) # main thread has moved on before we resume here. restore the db override.
    end
  end
end
