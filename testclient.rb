require 'socket'
s = UDPSocket.new()
s.send("hello", 0, '127.0.0.1', 3456)