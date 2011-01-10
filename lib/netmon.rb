# encoding: UTF-8

class NetMonitor

	attr_accessor :run

	def ping
		open("|ping #{@pinghost}", 'r:iso-8859-2')
	end

	def initialize(opts = {}, logger = nil)
		opts = { pinghost: 'dev.progressive.hu', interval: 60, reconnect_sleep: 120 }.merge(opts)

		@pinghost = opts[:pinghost] 
		@interval = opts[:interval]
		@reconnect_sleep = opts[:reconnect_sleep] 
		
		@had_net = false
		@run = true
		@logger = logger
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
	
	def reconnect
		@logger.warn "reconnect" if @logger
		sleep(@reconnect_sleep)
	end

	def monitor!
		@logger.info "starting up with #{@interval} sleep interval" if @logger
		while(@run) do
			@logger.debug 'checking' if @logger
			sleep_time = @interval
			if has_net?
				@logger.debug 'has net' if @logger
				@had_net = true
			else
				if @had_net
					@logger.info 'dont has net at the first time' if @logger
					@had_net = false
				else
					@logger.info 'dont has net at the second time time' if @logger
					reconnect
					sleep_time = 0
					if has_net?
						@had_net = true
						@logger.info 'reconnect success' if @logger
					else 
						@logger.error 'reconnect failed' if @logger
					end
				end
			end
			@logger.debug "sleeping for #{sleep_time} sec" if @logger
			sleep(sleep_time)
		end
	end
end
