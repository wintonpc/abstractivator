begin
  require 'eventmachine'
rescue
  raise "ScheduleRunner requires EventMachine but `require 'eventmachine'` failed."
end

# Performs an action periodically, but only at times allowed by a Schedule.
class ScheduleRunner
  def self.run_on_schedule(task, &action)
    ScheduleRunner.new(task, action).start
  end

  def initialize(task, action)
    @task = task
    @action = action
  end

  def start
    run_after(@task.interval_seconds)
  end

  def run_after(seconds_to_wait)
    @task.before_waiting(seconds_to_wait)
    @task.pump.add_timer(seconds_to_wait) do
      schedule = @task.schedule
      if schedule.permits?(Time.now)
        @action.call
        run_after(@task.interval_seconds)
      else
        run_after(schedule.downtime_minutes_from(Time.now) * 60)
      end
    end
  end
end
