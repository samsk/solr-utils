-- ngx_solr module
local ngx_solr = {
}
ngx_solr.__index = ngx_solr

setmetatable(ngx_solr, {
	__call = function (cls, ...)
	local self = setmetatable({}, cls)
	self:_init(...)
        return self
        end,
})

local solr_args = require "solr_args"

function ngx_solr._init(init)
end

function ngx_solr.get_one(ngx, location, init_args, field, chomp)
	ngx.req.read_body();
	local resp = ngx.location.capture(location,
			{ args = init_args
					.result_field(field)
					.output('csv')
					.rows(1)
					.build() })
	local body = resp.body or ''

	local data = nil
	local field_len = string.len(field)
	if body ~= nil and string.sub(body, 1, field_len) == field then
		data = string.sub(body, field_len + 2)

		if chomp ~= nil then
			data = string.gsub(data, "\n$", "") -- chomp
		end
	end

	return data
end

return ngx_solr
