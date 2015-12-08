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
			@identifier = para[1]
			@destport = para[0]
			@selfport = para[2]
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
			join(@identifier, @destport, @selfport)
		else
			start_boost(@identifier, @selfport)
		end
	end

	def join(identifier, destport, selfport)
		puts 'JOIN'
		message = Hash.new()
		message['type'] = "JOINING_NETWORK"
		message['node_id'] = identifier.to_s
		message['port'] = selfport
		msg = JSON.generate(message)
		s = UDPSocket.new()
		s.send(msg, 0, '127.0.0.1', destport)
		run
	end

	def start_boost(identifier, port)
		run
	end

	def run
		thread_pool = ThreadPool.new(5)
		loop{
			text, sender = @server.recvfrom(1000)
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
		message_type = message['type']
		case message_type
		when 'JOINING_NETWORK'
			puts 'JOINING_NETWORK'
			joining_network(message['node_id'], message['port'])
		end
	end

	def joining_network(node_id, port)
		routing_message = generate_routing_info(@identifier, node_id, port)
		s = UDPSocket.new()
		s.send(routing_message, 0, '127.0.0.1', port)
		@routing_table.insert(node_id, port)
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

	def generate_routing_info(gateway_id, node_id, port_number)
		routing_info = Hash.new()
		routing_info['type'] = 'ROUTING_INFO'
		routing_info['gateway_id'] = gateway_id
		routing_info['node_id'] = node_id
		routing_info['port_number'] = port_number
		routing_info['route_table'] = Array.new()
		for node_id in @routing_table.routing_table.keys
			temp = Hash.new
			temp['node_id'] = node_id
			temp['port'] = @routing_table.getport(node_id)
			routing_info['route_table'] << temp
		end
		msg = JSON.generate(routing_info)
		p msg
		return msg
	end

end
