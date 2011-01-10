require File.realpath File.join(File.dirname(__FILE__), "..", "lib", "netmon.rb")

require 'test/unit'

require 'wrong/adapters/test_unit'

require 'wrong'
include Wrong

class NetMonTest < Test::Unit::TestCase
	
	def test_no_net_with_nonexisting_host
		nm = NetMonitor.new({pinghost: 'no_such_host.net'}).extend(Module.new do 
			def ping
				open(File.dirname(__FILE__) + '/nosuchhost_output', 'r:iso-8859-2')
			end
		end);
		assert { nm.has_net? == false }
	end	
	
	def test_no_net_with_noresponding_host
		nm = NetMonitor.new({pinghost: 'progressive.hu'}).extend(Module.new do 
			def ping
				open(File.dirname(__FILE__) + '/norespond_output', 'r:iso-8859-2')
			end
		end);
		assert { nm.has_net? == false }
	end	
	
	def test_no_net_with_no_route_host
		nm = NetMonitor.new({pinghost: '127.0.0.2'}).extend(Module.new do 
			def ping
				open(File.dirname(__FILE__) + '/noroute_output', 'r:iso-8859-2')
			end
		end);
		assert { nm.has_net? == false }
	end	
	
	def test_has_net
		nm = NetMonitor.new({pinghost: 'dev.progressive.hu'}).extend(Module.new do 
			def ping
				open(File.dirname(__FILE__) + '/success_output', 'r:iso-8859-2')
			end
		end);
		assert { nm.has_net? == true }
	end	
	
	# def test_has_net_real_test
	# 	nm = NetMonitor.new({pinghost: 'dev.progressive.hu'})
	# 	assert { nm.has_net? == true }
	# end	

end
