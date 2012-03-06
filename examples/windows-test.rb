# Add our lib folder
$:.push(File.join(File.dirname(__FILE__), %w{.. lib}))

require "spoon"

pid = Spoon.spawn('C:\\WINDOWS\\explorer')
#pid = Spoon.spawn('/usr/bin/Thunar', '/home')
puts "pid: #{pid}"
