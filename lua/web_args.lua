-- web_args module
local web_args = {}
web_args.__index = web_args;

setmetatable(web_args, {
	__call = function (cls, ...)
	local self = setmetatable({}, cls)
	self:_init(...)
        return self
        end,
})

local json = require("cjson");

function web_args._init(init)
end

function web_args.one(key, val)
	return key .. '=' .. val
end

function web_args.add_str(tab, str)
	table.insert(tab, str);
end

function web_args.add(tab, key, val, defval)
	if val == nil and defval ~= nil then
		val = defval
	end
	if val ~= nil then
		web_args.add_str(tab, web_args.one(key, val))
	end
end

function web_args.add_json(tab, key, val)
	web_args.add_str(tab, key .. '=' .. json.encode(val))
end

function web_args.add_array(tab, arr)
	for i = 0, table.getn(arr), 1 do
		web_args.add_str(tab, arr[i])
	end
end

function web_args.build(tab)
	return table.concat(tab, '&')
end

return web_args
