require './lib/ThreadPool.rb'
require './lib/RoutingTable.rb'
require "socket"
require "net/http"
require 'json'
require "thread"

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
		puts 'ARE you ready to start the chat? Y/N'
		temp = false
		thread_pool = ThreadPool.new(2)
		while line = $stdin.gets.chomp
			if temp == false
				if (line == 'N') || (line == 'n')
					p 'exiting the program'
					raise SystemExit
				end
				temp = true
			end
			handle_stdin(line)
			Thread.new{
				loop{
					text, sender = @server.recvfrom(5000)
					thread_pool.schedule(sender) do
						p "into thread pool"
						p Thread.current[:id]
						p text
						handle_client(text)
					end
				}
			}
		end
	end

	def handle_stdin(text)
		if text.include?('#')
			tag = getTag(text)
			puts "tag is #{tag}"
			if text == '#' + tag
				send_chat_retrieve(tag, text)
			else
				send_chat(tag, text)
			end
		else
			return
		end
	end

	def send_chat_retrieve(tag, text)

	end

	def send_chat(tag, text)
		p 'send_chat'
		target_id = hashcode(tag)
		puts "target_id is #{target_id}"
		target_node_id = @routing_table.get_next_from_ls(target_id)
		puts "target_node_id is #{target_node_id}"
		if target_node_id == @identifier
			p 'this is the chat destination'
		else
			p target_node_id
			p @routing_table.routing_table
			target_port = @routing_table.getport(target_node_id)
			message = Hash.new()
			message["type"] = "CHAT"
			message["target_id"] = target_id
			message["sender_id"] = @identifier
			message["tag"] = tag
			message["text"] = text
			msg = JSON.generate(message)
			s = UDPSocket.new()
			p target_port
			s.send(msg, 0, '127.0.0.1', target_port)
		end
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
			joining_network_relay(message['node_id'], message['gateway_id'], \
				message['port'], text)
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
			chat(message['target_id'], text)
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
		send_joining_relay(node_id, port)
		p 'sent_joining_relay'
		@routing_table.insertNode(node_id, port)
		p 'insert succesfully'
		p @routing_table.routing_table
	end

	def send_joining_relay(node_id, port)
		message = Hash.new()
		message['type'] = 'JOINING_NETWORK_RELAY'
		message['node_id'] = node_id
		message['gateway_id'] = @identifier
		message['port'] = port
		msg = JSON.generate(message)
		p msg
		target = @routing_table.get_next_from_ls(node_id)
		puts "target is #{target}"
		if target == @identifier
			p 'it is the destination'
			# @routing_table.insertNode(node_id, port)
		else
			target_port = @routing_table.getport(target)
			s = UDPSocket.new()
			s.send(msg, 0, '127.0.0.1', target_port)
		end
	end

	def joining_network_relay(node_id, gateway_id, port, msg)
		routing_message = generate_routing_info(gateway_id, node_id, @selfport)
		puts "routing_message in joining network relay is:\n#{routing_message}"
		target = @routing_table.get_next_from_ls(node_id)
		puts "target is #{target}"
		if target == @identifier
			p 'the relay destination is here'
			@routing_table.insertNode(node_id, port)
			p @routing_table.routing_table
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
		############## here may be a bug!!!!!!!
			target = @routing_table.get_next_from_ls(gateway_id)
			p target
			target_port = @routing_table.getport(target)
			s = UDPSocket.new()
			s.send(msg, 0, '127.0.0.1', target_port)
		############## here may be a bug!!!!!!!
		end
	end

	def leaving_network

	end

	def chat(target_id, text)
		next_hop = @routing_table.get_next_from_ls(target_id)
		if next_hop == @identifier
			p 'chat ends here'
		else
			next_hop_port = @routing_table.getport(next_hop)
			s = UDPSocket.new()
			s.send(text, 0, '127.0.0.1', next_hop_port)
		end
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

	def getTag(text)
		flag = text.index('#')
		flag_end = text.index(' ', flag)
		if flag_end == nil
			flag_end = text.index('.', flag)
			if flag_end == nil
				flag_end = text.index(',', flag)
			end
		end
		if flag_end == nil
			flag_end = 0
		end
		tag = text[(flag + 1)..(flag_end - 1)]
		return tag
	end

end
