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
		@routing_table = RoutingTable.new(@identifier)
		@routing_table.insertNode(@identifier, @selfport)
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
			text, sender = @server.recvfrom(5000)
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
			puts 'end of JOINING_NETWORK'
		when 'JOINING_NETWORK_RELAY'
			puts 'JOINING_NETWORK_RELAY'
			joining_network_relay(message['node_id'], message['gateway_id'], text)
			puts 'end of JOINING_NETWORK_RELAY'
		when 'ROUTING_INFO'
			puts 'ROUTING_INFO'
			routing_info(message['gateway_id'], message['node_id'], \
				message['route_table'], text)

			puts 'end of ROUTING_INFO'
		when 'LEAVING_NETWORK'
			puts 'LEAVING_NETWORK'
			leaving_network()
			puts 'end of LEAVING_NETWORK'
		when 'CHAT'
			puts 'CHAT'
			chat()
			puts 'end of CHAT'
		when 'ACK_CHAT'
			puts 'ACK_CHAT'
			ack_chat()
			puts 'end of ACK_CHAT'
		when 'CHAT_RETRIEVE'
			puts 'CHAT_RETRIEVE'
			chat_retrieve()
			puts 'end of CHAT_RETRIEVE'
		when 'CHAT_RESPONSE'
			puts 'CHAT_RESPONSE'
			chat_response()
			puts 'end of CHAT_RESPONSE'
		when 'PING'
			puts 'PING'
			ping()
			puts 'end of PING'
		when 'ACK'
			puts 'ACK'
			ack()
			puts 'end of ACK'
		end
	end

	def joining_network(node_id, port)
		routing_message = generate_routing_info(@identifier, node_id, port)
		s = UDPSocket.new()
		s.send(routing_message, 0, '127.0.0.1', port)
		p 'sent succesfully'
		send_joining_relay(node_id)
		p 'sent_joining_relay'
		@routing_table.insertNode(node_id, port)
		p 'insert succesfully'
		p @routing_table.routing_table
	end

	def send_joining_relay(node_id)
		message = Hash.new()
		message['type'] = 'JOINING_NETWORK_RELAY'
		message['node_id'] = node_id
		message['gateway_id'] = @identifier
		msg = JSON.generate(message)
		target = @routing_table.get_next_from_ls(node_id)
		if target == @identifier
			p 'it is the destination'
		else
			target_port = @routing_table.getport(target.to_s)
			s = UDPSocket.new()
			s.send(msg, 0, '127.0.0.1', target_port)
		end
	end

	def joining_network_relay(node_id, gateway_id, msg)
		routing_message = generate_routing_info(gateway_id, node_id, @selfport)
		puts "routing_message in joining network relay is:\n#{routing_message}"
		target = @routing_table.get_next_from_ls(node_id)
		puts "target is #{target}"
		if target == @identifier
			p 'the relay destination is here'
		else
			target_port = @routing_table.getport(target)
			s = UDPSocket.new()
			s.send(msg, 0, '127.0.0.1', target_port)
		end
		target_gateway = @routing_table.get_next_from_ls(gateway_id)
		puts target_gateway
		puts gateway_id
		puts @routing_table.routing_table
		target_gateway_port = @routing_table.getport(target_gateway)
		s = UDPSocket.new()
		s.send(routing_message, 0, '127.0.0.1', target_gateway_port)
		p 'finish send relay return'
	end

	def routing_info(gateway_id, node_id, routing_table, msg)
		p 'we are in the routing_info'
		if node_id.to_i == @identifier
			p 'node_id = identifier'
			@routing_table.merge(routing_table)
			@routing_table.insertNode(gateway_id, @destport)
			p @routing_table.routing_table
			return
		end		
		if gateway_id == @identifier
			p 'gateway = identifier'
			target = @routing_table.get_next_from_ls(node_id)
			p target
			target_port = @routing_table.getport(target)
			p target_port
			s = UDPSocket.new()
			s.send(msg, 0, '127.0.0.1', target_port)
		else
			p 'gateway != identifier'
			p @routing_table.routing_table
			p gateway_id
			target = @routing_table.get_next_from_ls(gateway_id)
			p target
			target_port = @routing_table.getport(target)
			s = UDPSocket.new()
			s.send(msg, 0, '127.0.0.1', target_port)
		end
	end

	def leaving_network

	end

	def chat

	end

	def ack_chat

	end

	def chat_retrieve

	end

	def chat_response

	end

	def ping

	end

	def ack

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
