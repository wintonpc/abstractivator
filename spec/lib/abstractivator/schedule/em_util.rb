require 'eventmachine'

def em
  EM.run do
    EM.add_timer(in_debug_mode? ? 999999 : 3) { raise 'EM spec timed out' }
    yield
  end
end

def in_debug_mode?
  ENV['RUBYLIB'] =~ /ruby-debug-ide/ # http://stackoverflow.com/questions/22039807/determine-if-a-program-is-running-in-debug-mode
end

def done
  EM.stop
end
