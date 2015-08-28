require 'rspec/core'
require 'abstractivator/schedule/schedule'

describe Schedule do
  let(:sunday) { 0 }
  let(:monday) { 1 }
  let(:tuesday) { 2 }
  let(:wednesday) { 3 }
  let(:thursday) { 4 }
  let(:friday) { 5 }
  let(:saturday) { 6 }
  describe '#new' do
    it 'raises an exception when no periods are specified' do
      expect{Schedule.new('')}.to raise_exception StandardError
      expect{Schedule.new(',,,')}.to raise_exception StandardError
      expect{Schedule.new('asdf')}.to raise_exception StandardError
    end
    it 'accepts schedule strings delimited by commas and/or spaces' do
      expect(Schedule.new('1:00-12:00,15:00-16:00')).to be_a Schedule
      expect(Schedule.new('1:00-12:00 15:00-16:00')).to be_a Schedule
      expect(Schedule.new('1:00-12:00, 15:00-16:00')).to be_a Schedule
      expect(Schedule.new('1:00-12:00 ,15:00-16:00')).to be_a Schedule
    end
  end
  describe '#permits?' do
    it 'indicates if schedule permits the given time' do
      s = Schedule.new('1:00-2:00')
      assert_rejects(s, 0, 59)
      assert_permits(s, 1, 0)
      assert_permits(s, 1, 30)
      assert_permits(s, 1, 59)
      assert_rejects(s, 2, 00)
    end
    it 'allows day-of-week specifiers' do
      s = Schedule.new('1:00-2:00#MWF')
      assert_rejects(s, 1, 30, sunday)
      assert_permits(s, 1, 30, monday)
      assert_rejects(s, 1, 30, tuesday)
      assert_permits(s, 1, 30, wednesday)
      assert_rejects(s, 1, 30, thursday)
      assert_permits(s, 1, 30, friday)
      assert_rejects(s, 1, 30, saturday)
    end
    it 'allows any reasonable day-of-week delimiter' do
      good = %w(# @ / |)
      good.each do |delimiter|
        Schedule.new("1:00-2:00#{delimiter}MWF")
      end
      bad = %w(- : . 4 M) + [' ']
      bad.each do |delimiter|
        expect { Schedule.new("1:00-2:00#{delimiter}MWF") }.to raise_error
      end
    end
    it 'raises an exception when a bad day-of-week specifier is provided' do
      expect{Schedule.new('1:00-2:00#X')}.to raise_exception RuntimeError
    end
    it 'handles periods that cross midnight' do
      s = Schedule.new('23:30-0:30')
      assert_rejects(s, 23, 29)
      assert_permits(s, 23, 30)
      assert_permits(s, 0, 29)
      assert_rejects(s, 0, 30)
    end
    it 'handles periods that cross the end of the week' do
      s = Schedule.new('23:30-0:30#S')
      assert_rejects(s, 23, 29, saturday)
      assert_permits(s, 23, 30, saturday)
      assert_permits(s, 0, 29, sunday)
      assert_rejects(s, 0, 30, sunday)
    end
  end
  describe '#downtime_minutes_from' do
    it 'returns zero if the given time is permitted' do
      s = Schedule.new('1:00-2:00')
      expect(s.downtime_minutes_from(make_time(1, 23))).to eql 0
    end
    it 'returns the number of seconds until the start of the next permitted period' do
      s = Schedule.new('1:00-2:00#M,3:00-4:00#M,3:00-4:00#T')
      expect(s.downtime_minutes_from(make_time(0, 55, monday))).to eql 5
      expect(s.downtime_minutes_from(make_time(2, 55, monday))).to eql 5
      expect(s.downtime_minutes_from(make_time(4, 00, monday))).to eql 23 * 60
      expect(s.downtime_minutes_from(make_time(4, 00, tuesday))).to eql (21 + 5 * 24) * 60
    end
  end

  def assert_permits(s, hour, minute, day_of_week=0)
    expect(s.permits?(make_time(hour, minute, day_of_week))).to be true
  end

  def assert_rejects(s, hour, minute, day_of_week=0)
    expect(s.permits?(make_time(hour, minute, day_of_week))).to be false
  end

  def make_time(hour, minute, day_of_week=0, seconds=0)
    Time.local(2014, 6, day_of_week + 1, hour, minute, seconds)
  end
end
