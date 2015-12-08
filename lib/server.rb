require './lib/ThreadPool.rb'
require './lib/RoutingTable.rb'
require "socket"
require "net/http"
require 'json'

class Server
	def initialize(info, para)
		if info == "start"
			@identifier = para[0]
			@selfport = para[1]
			p @identifier
		elsif info == "join"
			@identifier = para[2]
			@ip = para[0]
			@destport = para[1]
			@selfport = para[3]
		else
			raise SystemExit
		end

		@server = UDPSocket.new()
		@server.bind(nil, @selfport)
		@routing_table = RoutingTable.new()
		uri = URI("http://ipecho.net/plain")
		body = Net::HTTP.get(uri)
		if body.length != 0
			@self_ip = body
		else
			@self_ip = '127.0.0.1'
		end
		if info == "join"
			join(@identifier, @ip, @destport)
		else
			start_boost(@identifier, @selfport)
		end
	end

	def join(identifier, ip, destport)
		message = Hash.new()
		message['type'] = "JOINING_NETWORK"
		message['node_id'] = identifier.to_s
		message['ip_address'] = @self_ip
		message['port'] = @selfport
		msg = JSON.generate(message)
		s = UDPSocket.new()
		s.send(msg, 0, ip, @destport)
		run
	end

	def start_boost(identifier, port)
		run
	end

	def run
		thread_pool = ThreadPool.new(5)
		loop{
			text, sender = @server.recvfrom(100)
			thread_pool.schedule(sender) do
				p "into thread pool"
				p Thread.current[:id]
				p text
				handle_client(text)
			end
		}
	end

	def handle_client(text)
		message = JSON.parse(text)
		p message
	end

	def routing
	end

	def leave
	end

	def send_message
	end

	def receive_message
	end

	def hashcode(s)
		hash = 0
		for i in 0..(s.length-1)
			hash = hash * 31 + s[i].ord
			p s[i]
			p s[i].ord
		end
		return hash
	end

end
