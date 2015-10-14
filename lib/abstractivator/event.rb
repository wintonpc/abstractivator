module Abstractivator
  module Event
    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      def event(*names)
        names.each do |name|
          define_method("on_#{name}") do |&block|
            __event_hooks[name] << block
            proc { __event_hooks[name].delete(block) }
          end

          define_method("do_#{name}") do |*args, **kws, &block|
            __event_hooks[name].each do |hook|
              if hook.parameters.map(&:first).include?(:key)
                hook.call(*args, **kws, &block)
              else
                hook.call(*args, &block)
              end
            end
          end
        end
      end
    end

    def __event_hooks
      @__event_hooks ||= Hash.new { |h, k| h[k] = [] }
    end
  end
end
