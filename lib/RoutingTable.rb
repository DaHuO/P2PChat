# so far, the node number is small, so I put all the known nodes to the 
# leaf set, and a altered way of routing table, so that all the known 
# nodes will be in the routing table.

class RoutingTable
	def initialize(identifier)
		@routing_table = Hash.new
		@rt = Hash.new # the routing table used for prefix routing
		@ls_l = Array.new # the half leaf set whose nodeid is smaller
		@ls_r = Array.new # the half leaf set whose nodeid is larger
		@selfId = identifier
		@selfIdHex = @selfId.to_s(16)
		if @selfIdHex.length != 32
			@selfIdHex = '0' * (32 - @selfIdHex.length) + @selfIdHex
		end
	end

	attr_reader :routing_table

	# def insert(node_id, ip_address)
	# 	@routing_table[node_id] = ip_address
	# end

	def insert(node_id, port_number)
		@routing_table[node_id] = port_number
		node_id_hex = node_id.to_s(16)
		if node_id_hex.length != 32
			node_id_hex = '0' * (32 - node_id_hex.length) + node_id_hex
		end
		prefix = string_compare(@selfIdHex, node_id_hex)
		if @rt[prefix] == nil
			@rt[prefix] = Array.new
		end
		@rt[prefix] << node_id
		push_to_ls(node_id)
	end

	def del(node_id)
		@routing_table.delete(node_id)
	end

	def getport(node_id)
		return @routing_table[node_id]
	end

	def merge(rt)	# for merge routing information
		for node_id in rt.keys
			unless @routing_table.has_key?(node_id)
				@routing_table[node_id] = rt[node_id]
			end
		end
	end

	def push_to_ls(node_id)
		if(node_id < @selfId)
			insert_to_ls(@ls_l, node_id)
		else
			insert_to_ls(@ls_r, node_id)
		end
	end

	def string_compare(s1, s2)
		for i in 0..(s1.length - 1)
			if s1[i]!= s2[i]
				return i
			end
		end
		return s1.length
	end

	def insert_to_ls(ls, node_id)
		if ls.length == 0
			ls << node_id
		else
			for i in 0..(ls.length - 1)
				if ls[i] > node_id
					ls.insert(i, node_id)
					return
				end
			end
			ls << node_id
		end
	end

end