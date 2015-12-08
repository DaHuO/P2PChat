class RoutingTable
	def initialize
		@routing_table = Hash.new
	end

	attr_reader :routing_table

	# def insert(node_id, ip_address)
	# 	@routing_table[node_id] = ip_address
	# end

	def insert(node_id, port_number)
		@routing_table[node_id] = port_number
	end

	def del(node_id)
		@routing_table.delete(node_id)
	end
end