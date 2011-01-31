require 'rubygems'
require File.realpath File.join(File.dirname(__FILE__), "..", "lib", "netmon.rb")

require 'minitest/autorun'
require 'wrong'
require 'wrong/adapters/minitest'
include Wrong::Assert


class NetMonTest < MiniTest::Unit::TestCase
	
	def test_no_net_with_nonexisting_host
		nm = NetMonitor.new({pinghost: 'no_such_host.net'}).extend(Module.new do 
			def ping
				open(File.dirname(__FILE__) + '/nosuchhost_output', 'r:iso-8859-2')
			end
		end)
		deny { nm.has_net? }
	end	
	
	def test_no_net_with_noresponding_host
		nm = NetMonitor.new({pinghost: 'progressive.hu'}).extend(Module.new do 
			def ping
				open(File.dirname(__FILE__) + '/norespond_output', 'r:iso-8859-2')
			end
		end)
		deny { nm.has_net? }
	end	
	
	def test_no_net_with_no_route_host
		nm = NetMonitor.new({pinghost: '127.0.0.2'}).extend(Module.new do 
			def ping
				open(File.dirname(__FILE__) + '/noroute_output', 'r:iso-8859-2')
			end
		end)
		deny { nm.has_net? }
	end	
	
	def test_has_net
		nm = NetMonitor.new({pinghost: 'dev.progressive.hu'}).extend(Module.new do 
			def ping
				open(File.dirname(__FILE__) + '/success_output', 'r:iso-8859-2')
			end
		end)
		assert { nm.has_net? }
	end	

	def test_ping_timeout
		nm = NetMonitor.new({ping_timeout:0.001}) # lets assume that no ping call will succeed that fast (-:
		deny nm.has_net?
	end

	def test_detect_first_device_when_theres_a_device
		nm = NetMonitor.new({pinghost: 'dev.progressive.hu'}).extend(Module.new do 
			def device_list
				open(File.dirname(__FILE__) + '/device_detect_output').readlines
			end
		end)
		assert { nm.detect_first_device == "RE000050" }
		assert { nm.has_device? }
	end
	
	def test_detect_first_device_when_there_isnt_a_device
		nm = NetMonitor.new({pinghost: 'dev.progressive.hu'}).extend(Module.new do 
			def device_list
				open(File.dirname(__FILE__) + '/device_detect_output_no_device').readlines
			end
		end)
		assert { nm.detect_first_device.nil? }
		deny { nm.has_device? }
	end

	# def test_detect_first_device_real
	# 	nm = NetMonitor.new({pinghost: 'dev.progressive.hu'})
	# 	assert { nm.detect_first_device.match(NetMonitor::DEVICE_PATTERN) }
	# 	assert { nm.has_device? }
	# end

	# def test_has_net_real_test
	# 	nm = NetMonitor.new({pinghost: 'dev.progressive.hu'})
	# 	assert { nm.has_net? }
	# end	
	
	# def test_device_state_real
	# 	nm = NetMonitor.new({pinghost: 'dev.progressive.hu'})
	# 	assert { ['on', 'off'].include? nm.device_state }
	# end
end
