-- solr_args module
local solr_args = {
	args = {},
	arg_q = 'q',
}
solr_args.__index = solr_args

setmetatable(solr_args, {
	__call = function (cls, ...)
	local self = setmetatable({}, cls)
	self:_init(...)
        return self
        end,
})

local web_args = require "web_args"

function solr_args._init(init)
end

function solr_args.init(obj)
--	solr_args.args = solr_args:obj
	--solr_args.arg_q = obj.arg_q
	return solr_args
end

function solr_args.reset()
	solr_args.args = { wt='xml' }
	return solr_args
end

----
-- generic argument
function solr_args.arg(arg, value, def)
	if value ~= nil then
		solr_args.args[arg] = value
	elseif def ~= nil then
		solr_args.args[arg] = def
	end
	return solr_args
end

----
-- generic numeric argument
function solr_args.arg_number(arg, value, def)
	if tonumber(value) ~= nil then
		solr_args.args[arg] = value
	elseif def ~= nil then
		solr_args.args[arg] = def
	end
	return solr_args
end

----
-- query_param
function solr_args.query_param(param)
	solr_args.arg_q = param
	return solr_args
end


----
-- df=
function solr_args.query_field(field)
	return solr_args.arg('df', field)
end

----
-- fl=
function solr_args.result_field(field)
	return solr_args.arg('fl', field)
end

----
-- q=
function solr_args.query(value, def, prefix)
	if value ~= nil and prefix ~= nil then
		value = prefix .. value
	end
	return solr_args.arg(solr_args.arg_q, value, def)
end

----
-- q=*
function solr_args.wildcard_query(value)
	if value ~= nil then
		value = value .. '*'
	end
	return solr_args.arg(solr_args.arg_q, value)
end

----
-- q=*
function solr_args.quote_query(value, prefix)
	if value ~= nil then
		if prefix ~= nil then
			value = prefix .. value
		end
		value = '"' .. value .. '"'
	end
	return solr_args.arg(solr_args.arg_q, value)
end

----
-- q=field:*
function solr_args.field_query(field, value, prefix)
	if value ~= nil then
		if prefix ~= nil then
			value = prefix .. value
		end
		value = field .. ':"' .. value .. '"'
	end
	return solr_args.arg(solr_args.arg_q, value)
end

----
-- start=
function solr_args.start(value)
	return solr_args.arg_number('start', value, 0)
end

----
-- rows=
function solr_args.rows(value)
	return solr_args.arg_number('rows', value)
end

----
-- pager=
function solr_args.pager(value)
	return solr_args.arg('pager', value)
end

----
-- sort=
function solr_args.sort(arg, mode, value)
	solr_args.arg(arg, mode)
	return solr_args.arg('sort', value)
end

----
-- fq=
function solr_args.filter(arg, fq, value)
	if value ~= nil and value ~= '' then
		solr_args.args[arg] = value
		if solr_args.args['fq'] == nil then
			solr_args.args['fq'] = {}
		end
		solr_args.args['fq'][arg] = fq .. ':' .. value
	end
	return solr_args
end

----
-- fq=
function solr_args.filter_day_range(arg, fq, value)
	if value ~= nil and value ~= '' then
		solr_args.args[arg] = value
		if solr_args.args['fq'] == nil then
			solr_args.args['fq'] = {}
		end
		solr_args.args['fq'][arg] = fq .. ':' .. '[NOW-' .. value .. 'DAY%20TO%20NOW]'
	end
	return solr_args
end

----
-- fq=
function solr_args.filter_hour_range(arg, fq, value)
	if value ~= nil and value ~= '' then
		solr_args.args[arg] = value
		if solr_args.args['fq'] == nil then
			solr_args.args['fq'] = {}
		end
		solr_args.args['fq'][arg] = fq .. ':' .. '[NOW-' .. value .. 'HOUR%20TO%20NOW]'
	end
	return solr_args
end

----
-- wt=
function solr_args.output(out)
	solr_args.args['wt'] = out
	return solr_args
end

----
-- wt=xml
function solr_args.output_json(enabled)
	if enabled then
		solr_args.args['wt'] = 'xml'
	end
	return solr_args
end


----
-- wt=json
function solr_args.output_json(enabled)
	if enabled then
		solr_args.args['wt'] = 'json'
		solr_args.args['omitHeader'] = 'on'	-- true?
	end
	return solr_args
end

----
-- build final arg string
function solr_args.build()
	local args = {}
	for key, val in pairs(solr_args.args) do
		if type(val) == 'table' then
			for key1, val1 in pairs(val) do
				web_args.add(args, key, val1)
			end
		else
			web_args.add(args, key, val)
		end
	end
	return web_args.build(args)
end

return solr_args
