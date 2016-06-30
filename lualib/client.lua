local skynet = require "skynet"
local proxy = require "socket_proxy"
local sprotoloader = require "sprotoloader"
local log = require "log"

local client = {}
local host
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
		local f = handler[name]
		if f then
			local ok, result = pcall(f, c, args)
			if ok then
				proxy.write(fd, response(result))
			else
				log("raise error = %s", result)
				proxy.write(fd, response(ERROR, result))
			end
			if c.exit then
				return c
			end
		else
			-- unsupported command, disconnected
			error ("Invalid command " .. name)
		end
	end
end

function client.close(fd)
	proxy.close(fd)
end

function client.init(name)
	return function ()
		local protoloader = skynet.uniqueservice "protoloader"
		local slot = skynet.call(protoloader, "lua", "index", name)
		host = sprotoloader.load(slot):host "package"
	end
end

return client