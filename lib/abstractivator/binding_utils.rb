require 'binding_of_caller'

module Abstractivator
  class BindingUtils
    class << self
      def frame_args(depth=0)
        parent_binding = binding.of_caller(depth + 1)
        parameter_names = parent_binding.eval('method(__method__)').parameters.map(&:last)
        parameter_names.map{|p| [p, parent_binding.eval(p.to_s)]}
      end
    end
  end
end
