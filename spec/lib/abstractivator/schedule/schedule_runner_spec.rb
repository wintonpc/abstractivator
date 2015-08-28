require 'rspec/core'
require 'abstractivator/schedule/schedule'
require 'abstractivator/schedule/schedule_runner'
require_relative './em_util'

describe ScheduleRunner do
  let(:task) {double}
  let(:interval) {0.1}

  before(:each) do
    allow(task).to receive(:interval_seconds) {interval}
    allow(task).to receive(:before_waiting)
    allow(task).to receive(:pump) {EventMachine}
    allow(task).to receive(:schedule) {Schedule.new('00:00-24:00')}
  end

  describe '::run_on_schedule' do
    it 'waits for an interval before starting' do
      em do
        start = Time.now
        ScheduleRunner.run_on_schedule(task) do
          expect(Time.now - start).to be_within(ten_percent_of(interval)).of(interval)
          done
        end
      end
    end
    it 'runs periodically' do
      em do
        last = Time.now
        n = 0
        ScheduleRunner.run_on_schedule(task) do
          n += 1
          expect(Time.now - last).to be_within(ten_percent_of(interval)).of(interval)
          last = Time.now
          done if n == 3
        end
      end
    end
    it 'only runs during scheduled times' do
      em do
        start = Time.now + 3 * 60
        stop = Time.now + 4 * 60
        allow(task).to receive(:schedule) {Schedule.new("#{start.hour}:#{start.min}-#{stop.hour}:#{stop.min}")}
        orig_add_timer = EventMachine.method(:add_timer)
        expect(EventMachine).to receive(:add_timer).with(interval) {|s, &block| orig_add_timer.(s, &block)}.ordered
        expect(EventMachine).to receive(:add_timer).with(3 * 60) {done}.ordered
        ScheduleRunner.run_on_schedule(task) {}
      end
    end
    it 'calls before_waiting before waiting' do
      em do
        expect(task).to receive(:before_waiting).with(interval).ordered
        expect(EventMachine).to receive(:add_timer) {done}.ordered
        ScheduleRunner.run_on_schedule(task) {}
      end
    end
  end

  def ten_percent_of(x)
    x / 10.0
  end
end
