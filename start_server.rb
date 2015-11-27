load "lib/server.rb"

# Erroinfo = "command line parameter not fit:\n" + 
# 	"\t'--boot [Integer Identifier]' for start\n" +
# 	"\t'--bootstrap [IP Address] --id [Integer Identifier]' for join\n"

# if ARGV.length == 2
# 	if ARGV[0] == "--boot"
# 		Identifier = ARGV[1].to_i
# 		p Identifier
# 		para = [Identifier]
# 		Server.new("start",para)
# 	else
# 		puts Erroinfo
# 	end
# elsif ARGV.length == 3
# 	if ARGV[0] == "--bootstrap"
# 		Ip = ARGV[1]
# 		Identifier = ARGV[2]
# 		Server.new("join",[Ip, Identifier])
# 	else
# 		puts Erroinfo
# 	end
# else
# 	puts Erroinfo
# end

Erroinfo = "command line parameter not fit:\n" + 
	"\t'--boot [Integer Identifier] [port]' for start\n" +
	"\t'--bootstrap [IP Address] --id [Integer Identifier] [port]' for join\n"

if ARGV.length == 3
	if ARGV[0] == "--boot"
		Port = ARGV[2].to_i
		Identifier = ARGV[1].to_i
		para = [Identifier, Port]
		Server.new("start",para)
	else
		puts Erroinfo
	end
elsif ARGV.length == 4
	if ARGV[0] == "--bootstrap"
		Port = ARGV[3].to_i
		Ip = ARGV[1]
		Identifier = ARGV[2][2,-1].to_i
		para = [Ip, Identifier, Port]
		Server.new("join",para)
	else
		puts Erroinfo
	end
else
	puts Erroinfo
end

