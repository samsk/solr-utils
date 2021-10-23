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

local cjson_flat = require "cjson"
local web_args = require "web_args"

cjson_flat.decode_max_depth(1)

function _deepcopy(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[_deepcopy(k, s)] = _deepcopy(v, s) end
	return res
end

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
function solr_args.query(arg, value, def)
	if value ~= nil and value ~= '' then
		if arg ~= nil then
			solr_args.args[arg] = value
		end
		return solr_args.arg(solr_args.arg_q, value, def)
	elseif def ~= nil then
		return solr_args.arg(solr_args.arg_q, value, def)
	end
	return solr_args
end

----
-- q=
function solr_args.any_query(arg, value, def)
	if arg ~= nil then
		solr_args.args[arg] = value
	end
	return solr_args.arg(solr_args.arg_q, value, def)
end

----
-- q=*
function solr_args.wildcard_query(arg, value, wildprefix)
	if value ~= nil then
		if arg ~= nil then
			solr_args.args[arg] = value
		end
		if wildprefix ~= nil and wildprefix then
			value = '*' .. value
		end
		value = value .. '*'
	end
	return solr_args.arg(solr_args.arg_q, value)
end

----
-- q=*
function solr_args.quoted_query(arg, value)
	if value ~= nil then
		if arg ~= nil then
			solr_args.args[arg] = value
		end
		value = '"' .. value .. '"'
	end
	return solr_args.arg(solr_args.arg_q, value)
end

----
-- q=field:*
function solr_args.field_query(arg, field, value)
	if value ~= nil then
		if arg ~= nil then
			solr_args.args[arg] = value
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
function solr_args.filter_raw(arg, fq, value, cb, op)
	if value ~= nil and value ~= '' then
		if solr_args.args['fq'] == nil then
			solr_args.args['fq'] = {}
		end
		if type(value) ~= "table" then
			value = { value }
		end

		local value_arg = {}
		local value_arg_complex = 0

		if cb ~= nil then
			for k,v in pairs(value) do
				if string.sub(v, 1, 2) == '["'
						and string.sub(v, -2) == '"]' then
					-- THROWS error, if not flat (should we catch it ?)
					v_table = cjson_flat.decode(v)

					if v_table ~= nil and type(v_table) == "table" then
						table.insert(value_arg, _deepcopy(v_table))
						value_arg_complex = 1

						for nk,nv in pairs(v_table) do
							v_table[nk] = cb(nv)
						end

						v = '(' .. table.concat(v_table, ' AND ') .. ')'
					else
						table.insert(value_arg, v)
						v = cb(v)
					end
				else
					table.insert(value_arg, v)
					v = cb(v)
				end

				value[k] = v
			end
		else
			value_arg = value
		end

		glue = ' '
		if op ~= nil then
			glue = ' ' .. op .. ' '
		end

		if value_arg_complex == 1 then
			solr_args.args['json:' .. arg] = cjson_flat.encode(value_arg)
		else
			solr_args.args[arg] = table.concat(value_arg, ',')
		end
		solr_args.args['fq'][arg] = fq .. ':(' .. table.concat(value, glue) .. ')'
	end
	return solr_args
end

----
-- fq=
function solr_args.filter_raw_and(arg, fq, value, cb)
	return solr_args.filter_raw(arg, fq, value, cb, 'AND')
end

----
-- fq=
function solr_args.filter(arg, fq, value)
	return solr_args.filter_raw(arg, fq, value, function(v) return v end)
end

----
-- fq=*
function solr_args.filter_range(arg, fq, valueFrom, valueTo, withNull)
	local filter = nil
	if (valueFrom ~= nil or valueTo ~= nil) then
		if valueFrom == nil or valueFrom == '' then
			valueFrom = '*'
		end
		if valueTo == nil or valueTo == '' then
			valueTo = '*'
		end

		if valueTo ~= '*' or valueFrom ~= '*' then
			solr_args.args['argr_' .. arg] = valueFrom .. ':' .. valueTo
			filter = fq .. ':[' .. valueFrom .. ' TO ' .. valueTo .. ']'
		end
	end

	if withNull ~= nil and withNull == 1 then
		local filterNull = '*:* AND -' .. fq .. ':*'

		solr_args.args['arg_' .. arg .. 'IsNull'] = withNull
		if filter ~= nil then
			filter = '((' .. filterNull .. ') OR (' .. filter .. '))'
		else
			filter = filterNull
		end
	end

	if filter ~= nil then
		if solr_args.args['fq'] == nil then
			solr_args.args['fq'] = {}
		end
		solr_args.args['fq'][arg] = filter
	end

	return solr_args
end

----
-- fq=
function solr_args.filter_bool(arg, fq, value)
	if value ~= nil and (value == 1 or value == '1') then
		return solr_args.filter_raw('arg_' .. arg, fq, 1)
	elseif value == 0 or value == '0' then
		return solr_args.filter_raw('arg_' .. arg, fq, 0)
	end
	return solr_args
end

----
-- fq=
function solr_args.filter_datetime_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		solr_args.args[arg] = value
		if solr_args.args['fq'] == nil then
			solr_args.args['fq'] = {}
		end
		solr_args.args['fq'][arg] = fq .. ':' .. '[' .. value .. ' TO NOW]'
	end
	return solr_args
end

----
-- fq=
function solr_args.filter_date_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		solr_args.args[arg] = value
		if solr_args.args['fq'] == nil then
			solr_args.args['fq'] = {}
		end
		solr_args.args['fq'][arg] = fq .. ':' .. '[' .. value .. 'T00:00:00Z TO NOW]'
	end
	return solr_args
end

----
-- fq=
function solr_args.filter_day_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		solr_args.args[arg] = value
		if solr_args.args['fq'] == nil then
			solr_args.args['fq'] = {}
		end
		solr_args.args['fq'][arg] = fq .. ':' .. '[NOW-' .. value .. 'DAY TO NOW]'
	end
	return solr_args
end

function solr_args.filter_day_range(arg, fq, valueTo, valueFrom)
	if (valueFrom ~= nil or valueTo ~= nil) then
		if valueFrom == nil or valueFrom == '' then
			valueFrom = '*'
		else
			valueFrom = 'NOW-' .. valueFrom .. 'DAY'
		end
		if valueTo == nil or valueTo == '' then
			valueTo = '*'
		else
			valueTo = 'NOW-' .. valueTo .. 'DAY'
		end

		if valueTo ~= '*' or valueFrom ~= '*' then
			solr_args.args[arg] = valueFrom .. ':' .. valueTo
			if solr_args.args['fq'] == nil then
				solr_args.args['fq'] = {}
			end
			solr_args.args['fq'][arg] = fq .. ':[' .. valueFrom .. ' TO ' .. valueTo .. ']'
		end
	end
	return solr_args
end

----
-- fq=
function solr_args.filter_hour_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		solr_args.args[arg] = value
		if solr_args.args['fq'] == nil then
			solr_args.args['fq'] = {}
		end
		solr_args.args['fq'][arg] = fq .. ':' .. '[NOW-' .. value .. 'HOUR TO NOW]'
	end
	return solr_args
end
-- compat, remove after 2020-01-01
function solr_args.filter_hour_range(arg, fq, value)
	return solr_args.filter_hour_from(arg, fq, value)
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
