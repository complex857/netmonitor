# encoding: UTF-8

require 'timeout'

class NetMonitor

	class NoDeviceError < StandardError
		def to_s
			"No USB Line switch device found"
		end
	end

	DEVICE_PATTERN = /RE\d{6}/

	attr_accessor :run

	def ping
		begin
			io = open("|ping #{@pinghost}", 'r:iso-8859-2')
			Timeout::timeout(@ping_timeout) {
				return io.readlines
			}
		rescue Timeout::Error
			@logger.error "Ping call timed out" if @logger
			return [
				"no net found\n"
			]
		end
	end

	def initialize(opts = {}, logger = nil)
		opts = { 
			pinghost: 'dev.progressive.hu', 
			interval: 60, 
			reconnect_sleep: 120,
			uls_path: "./ULS.exe",
			ping_timeout: 5,
		}.merge(opts)

		@pinghost = opts[:pinghost] 
		@interval = opts[:interval]
		@reconnect_sleep = opts[:reconnect_sleep] 
		@uls_path = opts[:uls_path] 
		@ping_timeout = opts[:ping_timeout] 
		
		@run = true
		@logger = logger

		@on_has_net_callbacks   = []
		@on_no_net_callback = []
	end

	def has_net?()
		success_pattern = /minimum = \d+ms, maximum = \d+ms, .tlag = (\d+)ms/
		success_line = ping.detect do |l|
			l =~ success_pattern
		end
		return false unless success_line

		m = success_pattern.match(success_line)
		return true if m[1].to_i > 0

		false
	end

	def disconnect 
		detect_first_device if @device_name.nil?
		system("\"#{@uls_path}\" /N=#{@device_name} /S=off")
	end
	
	def connect 
		detect_first_device if @device_name.nil?
		system("\"#{@uls_path}\" /N=#{@device_name} /S=on")
	end

	def device_state
		detect_first_device if @device_name.nil?
		raise NoDeviceError unless @device_name
		m = open("|\"#{@uls_path}\" /N=#{@device_name} /S=query").readlines[0].match /turned (on|off)$/i
		m[1]
	end

	def reconnect
		@logger.warn "reconnect" if @logger
		@logger.debug "disconnect start" if @logger
		re = disconnect
		@logger.debug "disconnect returned #{re}" if @logger
		sleep(1)
		@logger.debug "connect" if @logger
		re = connect
		@logger.debug "connect returned #{re}" if @logger
		@logger.debug "sleeping for #{@reconnect_sleep} seconds"
		sleep(@reconnect_sleep)
	end

	def device_list
		open("|\"#{@uls_path}\" /A").readlines
	end

	def detect_first_device
		@device_name = device_list.detect do |l|
			l =~ DEVICE_PATTERN
		end
		@device_name.chop! unless @device_name.nil?
	end

	def has_device?
		detect_first_device if @device_name.nil?
		return false if @device_name.nil? or @device_name.match(DEVICE_PATTERN).nil?
		return true
	end

	def on_has_net(&block)
		@logger.debug 'adding new has_net callback' if @logger
		@on_has_net_callbacks << block;	
	end
	
	def on_no_net(&block)
		@logger.debug 'adding new no_net callback' if @logger
		@on_no_net_callback << block;	
	end

	def monitor!
		@logger.info "starting interval:#{@interval}, reconnect:#{@reconnect_sleep} ping host:#{@pinghost}" if @logger
		@logger.info "found device: #{detect_first_device}"
		had_net = true
		while(@run) do
			@logger.debug 'checking' if @logger
			sleep_time = @interval
			if has_net?
				@logger.debug 'has net' if @logger
				had_net = true
				run_callbacks :has_net
			else
				if had_net
					@logger.info 'dont has net at the first time' if @logger
					had_net = false
					run_callbacks :no_net
				else
					@logger.info 'dont has net at the second time time' if @logger
					reconnect
					sleep_time = 0
					if has_net?
						had_net = true
						@logger.info 'reconnect success' if @logger
						run_callbacks :has_net
					else 
						@logger.error 'reconnect failed' if @logger
						run_callbacks :no_net
					end
				end
			end
			@logger.debug "sleeping for #{sleep_time} sec" if @logger
			sleep(sleep_time)
		end
	end

	private
	def run_callbacks(type)
		if type == :has_net
			cbs = @on_has_net_callbacks
		elsif type == :no_net
			cbs = @on_no_net_callback;
		end

		if cbs
			@logger.info "running callbacks for :#{type.to_s}" if @logger
			cbs.each do |cb|
				re = cb.call
				@logger.debug "callback returned:#{re}" if @logger
			end
		end
	end
end
