self_roles = %W(#{ENV["SERF_SELF_ROLE"]} self)
puts self_roles
server 'localhost:22', roles: self_roles, serf: { :'rpc-addr' => ENV["SERF_RPC_ADDR"] }
