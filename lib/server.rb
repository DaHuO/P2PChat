load "lib/ThreadPool.rb"
require "socket"
require "net/http"

class Server
	def initialize(info, para)
		if info == "start"
			@identifier = para[0]
			@port = para[1]
			p @identifier
		elsif info == "join"
			@identifier = para[1]
			@ip = para[0]
			@port = para[2]
			p @ip
			p @identifier
		else
			raise SystemExit
		end

		@server = UDPSocket.new()
		@server.bind(nil, @port)
		@routing_table = Hash.new
		uri = URI("http://ipecho.net/plain")
		body = Net::HTTP.get(uri)
		if body.length != 0
			@ip = body
		else
			@ip = '127.0.0.1'
		end
		if info == "join"
			join(@identifier, @ip, @port)
		else
			start(@identifier, @port)
		end
		run
	end

	def join(identifier, ip, port)
	end

	def start(identifier, port)
	end

	def run
		thread_pool = ThreadPool.new(10)
		loop{
			text, sender = @server.recvfrom(100)
			puts text
		}
	end

	def start(identifier, port)
	end

	def handle_client(c)
	end

	def routing
	end

	def join(identifier, ip, port)
	end

	def leave
	end

	def send_message
	end

	def receive_message
	end

end
