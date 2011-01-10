require File.realpath File.join(File.dirname(__FILE__), "lib", "netmon.rb")

require 'log4r'
include Log4r


log = Logger.new 'netmon'
log.outputters = FileOutputter.new('netmon', {filename: File.join(File.dirname(File.realpath(__FILE__)), 'netmon.log'), formatter: PatternFormatter.new(:pattern => "%d [%l] => %m")})

nm = NetMonitor.new({
	pinghost: 'dev.progressive.hu', 
	interval: 60, 
	reconnect_sleep: 120,
}, log)

nm.monitor!
