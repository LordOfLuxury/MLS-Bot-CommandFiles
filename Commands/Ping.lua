local function Ping(msg, author, server, client)
	local pong = msg:reply("Pong!")
	msg:reply("Server latency: " .. tostring(math.ceil((pong.createdAt - msg.createdAt) * 1000)) .. " ms")
end

return Ping