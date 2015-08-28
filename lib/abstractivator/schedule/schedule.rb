class Schedule

  WEEKDAYS = 'UMTWRFS' # Sunday through Saturday

  def initialize(str)
    @periods = parse_periods(str)
    unless @periods.any?
      raise 'At least one period must be specified'
    end
  end

  def permits?(localtime)
    @periods.any?{|p| p.includes?(localtime)}
  end

  def downtime_minutes_from(localtime)
    return 0 if permits?(localtime)
    wmin = Wmin.from_localtime(localtime)
    @periods.map{|p| (p.start - wmin + Wmin::WEEK) % Wmin::WEEK}.min
  end

  private

  def parse_periods(str)
    str.split(/[, ]+/).map(&method(:parse_period)).flatten
  end

  def parse_period(str)
    # the regex for matching a period.
    # don't restrict days here; otherwise, garbage will cause the optional days clause to fail,
    # which would be massaged to "UMTWRFS", which is not what we want.
    m = str.match /^(?<sh>\d\d?):(?<sm>\d\d?)-(?<eh>\d\d?):(?<em>\d\d?)([^\d:\-\.UMTWRFS ](?<days>.+))?$/
    m or raise "Could not parse period: #{str}"
    day_chars = m[:days] || WEEKDAYS
    day_chars.chars.map do |day_char|
      start = Wmin.parse(day_char, m[:sh], m[:sm])
      stop = Wmin.parse(day_char, m[:eh], m[:em])
      if stop < start
        stop = Wmin.add_day(stop)
      end
      if stop < Wmin::WEEK
        Period.new(start, stop)
      else
        [Period.new(start, Wmin::WEEK), Period.new(0, stop % Wmin::WEEK)]
      end
    end
  end

  class Period
    attr_accessor :start # inclusive
    attr_accessor :stop  # exclusive

    def initialize(start, stop)
      @start = start
      @stop = stop
    end

    def includes?(localtime)
      wmin = Wmin.from_localtime(localtime)
      result = start <= wmin && wmin < stop
      #puts "#{to_s} includes? #{to_clock(wmin)} (#{localtime}) : #{result}"
      #puts "  #{start} <= #{wmin} && #{wmin} < #{stop}"
      result
    end

    def to_s
      "#{to_clock(start)}-#{to_clock(stop)}"
    end

    def to_clock(wmin)
      day = (wmin / Wmin::DAY) % 7
      minutes = wmin % Wmin::DAY
      "#{minutes / 60}:#{minutes % 60}#{WEEKDAYS[day]}"
    end
  end

  # a 'wmin' is a week-minute: a time in any given week, represented as the number of minutes since
  # midnight on Sunday. Saturday 23:59 is the largest wmin (7 * 24 * 60 - 1)
  module Wmin
    DAY = 24 * 60
    WEEK = 7 * DAY

    def self.parse(day_char, hour, min)
      day = WEEKDAYS.index(day_char)
      unless day
        raise "Invalid day specifier: '#{day_char}'"
      end
      make(day, hour.to_i, min.to_i)
    end

    def self.make(day, hour, minute)
      minute + hour * 60 + day * 24 * 60
    end

    def self.from_localtime(localtime)
      make(localtime.wday, localtime.hour, localtime.min)
    end

    def self.add_day(wmin)
      wmin + DAY
    end

  end
end
