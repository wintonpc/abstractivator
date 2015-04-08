module Abstractivator
  class ArgsOf
    module CompoundConstraint
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def [](*args)
          new(*args.deep_map(&ArgsOf.method(:mask_for)))
        end
      end
    end
  end
end
