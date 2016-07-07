local socket = require "simplesocket"
local sproto = require "sproto"

local message = {}
local var = {
	session_id = 0 ,
	session = {},
	object = {},
}

function message.register(name)
	local f = assert(io.open(name .. ".s2c.sproto"))
	local t = f:read "a"
	f:close()
	var.host = sproto.parse(t):host "package"
	local f = assert(io.open(name .. ".c2s.sproto"))
	local t = f:read "a"
	f:close()
	var.request = var.host:attach(sproto.parse(t))
end

function message.peer(addr, port)
	var.addr = addr
	var.port = port
end

function message.connect()
	socket.connect(var.addr, var.port)
	socket.isconnect()
end

function message.bind(obj, handler)
	var.object[obj] = handler
end

function message.request(name, args)
	var.session_id = var.session_id + 1
	var.session[var.session_id] = { name = name, req = args }
	socket.write(var.request(name , args, var.session_id))
	return var.session_id
end

function message.update(ti)
	local msg = socket.read(ti)
	if not msg then
		return false
	end
	local t, session_id, resp, err = var.host:dispatch(msg)
	if t == "REQUEST" then
		for obj, handler in pairs(var.object) do
			local f = handler[session_id]	-- session_id is request type
			if f then
				local ok, err_msg = pcall(f, obj, resp)	-- resp is content of push
				if not ok then
					print(string.format("push %s for [%s] error : %s", session_id, tostring(obj), err_msg))
				end
			end
		end
	else
		local session = var.session[session_id]
		var.session[session_id] = nil

		for obj, handler in pairs(var.object) do
			if err then
				local f = handler.__error
				if f then
					local ok, err_msg = pcall(f, obj, session.name, err, session.req, session_id)
					if not ok then
						print(string.format("session %s[%d] error(%s) for [%s] error : %s", session.name, session_id, err, tostring(obj), err_msg))
					end
				end
			else
				local f = handler[session.name]
				if f then
					local ok, err_msg = pcall(f, obj, session.req, resp, session_id)
					if not ok then
						print(string.format("session %s[%d] for [%s] error : %s", session.name, session_id, tostring(obj), err_msg))
					end
				end
			end
		end
	end

	return true
end

return message
