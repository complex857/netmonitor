# encoding: UTF-8

class NetMonitor

	attr_accessor :run

	def ping
		open("|ping #{@pinghost}", 'r:iso-8859-2')
	end

	def initialize(opts = {})
		opts = { pinghost: 'dev.progressive.hu', interval: 60, reconnect_sleep: 120 }.merge(opts)

		@pinghost = opts[:pinghost] 
		@interval = opts[:interval]
		@reconnect_sleep = opts[:reconnect_sleep] 
		
		@had_net  = false
		@run = true
	end

	def has_net?()
		success_pattern = /minimum = \d+ms, maximum = \d+ms, .tlag = (\d+)ms/
		success_line = ping.readlines.detect do |l|
			l =~ success_pattern
		end
		return false unless success_line

		m = success_pattern.match(success_line)
		return true if m[1].to_i > 0;

		return false;
	end

	def monitor!
		while(@run) do
			puts 'checking'
			sleep_time = @interval
			if has_net?
				puts 'had net'
				@had_net = true
			else
				if not @had_net
					puts 'dont have net twice'
					reconnect
					sleep_time = @reconnect_sleep
				else
					puts 'dont have net at the first time'
					@had_net = false
				end
			end
			puts "sleeping for #{sleep_time} sec"
			sleep(sleep_time)
		end
	end

	private
		def reconnect
			puts 'reconnecting'
			sleep(2)
		end
end
