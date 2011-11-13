module Admin
  class PlayerSession

    SESSION_TIME = 30 * 60

    class PageView < OpenStruct;
    end;

    attr_accessor :start_time, :infos

    def initialize(info)
      @start_time = Time.parse(info['key'][1])
      @player_id = info['key'][0]
      @infos = [PageView.new(:start_time => @start_time, :path => info['value'], :key => info['id'])]
    end

    def add_request(info)
      start_time = Time.parse(info['key'][1])
      @infos.last.duration = start_time - @infos.last.start_time
      @infos << PageView.new(:start_time => start_time, :path => info['value'], :key => info['id'])
    end

    def duration
      @infos.last.start_time - @infos.first.start_time  
    end

    def self.parse(log_requests)
      sessions = []
      last_log_time = 100.years.ago
      log_requests.each do |info|
        info_time = Time.parse(info['key'][1])
        if info_time - last_log_time < SESSION_TIME
          sessions.last.add_request(info)
        else
          sessions << PlayerSession.new(info)
        end
        last_log_time = info_time
      end
      sessions
    end
  end
end
