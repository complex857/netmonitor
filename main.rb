require File.realpath File.join(File.dirname(__FILE__), "lib", "netmon.rb")

require 'log4r'
include Log4r


log = Logger.new 'netmon'
f   = PatternFormatter.new(:pattern => "%d [%l] => %m")
log.outputters << FileOutputter.new('netmon', {filename: File.join(File.dirname(File.realpath(__FILE__)), 'netmon.log'), formatter: f})
log.outputters << StdoutOutputter.new('netmon_stdout', formatter: f)

nm = NetMonitor.new({
	pinghost: ARGV[2] || 'dev.progressive.hu', 
	interval: ARGV[0] || 60, 
	reconnect_sleep: ARGV[1] || 120,
}, log)

nm.monitor!
