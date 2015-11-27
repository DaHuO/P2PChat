load "lib/ThreadPool.rb"
require "socket"

class Server
	def initialize(port)
		@port = port
		@server = TCPServer.open(@port)
		@routing_table = Hash.new
		uri = URI("http://ipecho.net/plain")
		body = Net::HTTP.get(uri)
		if body.length != 0
			@ip = body
		else
			@ip = '127.0.0.1'
		end
		run
	end

	def run
	end

	def message_handle
	end

	def routing
	end

	def join
	end

	def leave
	end

	def send_message
	end

	def receive_message
	end

end
