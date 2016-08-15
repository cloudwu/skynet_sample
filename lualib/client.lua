local skynet = require "skynet"
local proxy = require "socket_proxy"
local sprotoloader = require "sprotoloader"
local log = require "log"

local client = {}
local host
local sender
local handler = {}

function client.handler()
	return handler
end

function client.dispatch( c )
	local fd = c.fd
	proxy.subscribe(fd)
	local ERROR = {}
	while true do
		local msg, sz = proxy.read(fd)
		local type, name, args, response = host:dispatch(msg, sz)
		assert(type == "REQUEST")
		if c.exit then
			return c
		end
		local f = handler[name]
		if f then
			-- f may block , so fork and run
			skynet.fork(function()
				local ok, result = pcall(f, c, args)
				if ok then
					proxy.write(fd, response(result))
				else
					log("raise error = %s", result)
					proxy.write(fd, response(ERROR, result))
				end
			end)
		else
			-- unsupported command, disconnected
			error ("Invalid command " .. name)
		end
	end
end

function client.close(fd)
	proxy.close(fd)
end

function client.push(c, t, data)
	proxy.write(c.fd, sender(t, data))
end

function client.init(name)
	return function ()
		local protoloader = skynet.uniqueservice "protoloader"
		local slot = skynet.call(protoloader, "lua", "index", name .. ".c2s")
		host = sprotoloader.load(slot):host "package"
		local slot2 = skynet.call(protoloader, "lua", "index", name .. ".s2c")
		sender = host:attach(sprotoloader.load(slot2))
	end
end

return client