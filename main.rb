require File.realpath File.join(File.dirname(__FILE__), "lib", "netmon.rb")

require 'log4r'
include Log4r

SQUID_SERVICE_NAME = 'squid';
BROWSER_START_URL_FILE = "start_url.txt"
HAS_NET_URL = "http://muzeumokejszakaja.hu/"
NO_NET_URL = "file://c:\\\\muzeumokejszakaja.hu\\\\index.php.html"

log = Logger.new 'netmon'
f   = PatternFormatter.new(:pattern => "%d [%l] => %m")
log.outputters << FileOutputter.new('netmon', {filename: File.join(File.dirname(File.realpath(__FILE__)), 'netmon.log'), formatter: f})
log.outputters << StdoutOutputter.new('netmon_stdout', formatter: f)

params = {}
params[:interval] = ARGV[0].to_i if ARGV[0]
params[:reconnect_sleep] = ARGV[1].to_i if ARGV[1]
params[:pinghost] = ARGV[2] if ARGV[2]
params[:uls_path] = ARGV[3] if ARGV[3]

nm = NetMonitor.new(params, log)

nm.on_has_net do
	io = open("|net start squid 2>/dev/null");
	re = io.readlines
	File.open(BROWSER_START_URL_FILE, 'w') do |f|
		f << "#{HAS_NET_URL}\n"
	end
	re
end
nm.on_no_net do
	re = io = open("|net stop squid 2>/dev/null");
	re = io.readlines
	File.open(BROWSER_START_URL_FILE, 'w') do |f|
		f << "#{NO_NET_URL}\n"
	end
	re
end

nm.monitor!
