local socket = require('socket')
local http = require('socket.http')
local ltn12 = require('ltn12')
local json = require('json')

local M = {}

local host = "https://api.beamng.com"
local token = nil

function api_call(endpoint, data)
	local t = {}
	local headers = {bngstk=token}
	local success, code, headers, status_line = http.request({
		url = host..endpoint,
		headers = headers, 
		source = data and ltn12.source.string(data) or nil,
		sink = ltn12.sink.table(t)
	})

	--print(t)

	local str = table.concat(t, '')

	--print(headers)

	if headers['content-type'] == "application/json" then
		local parsed = json.parse(str)
		str = parsed.data
	end

	return str, code, headers
end

function get_token()
	resp, code, headers = http.request(host..'/s2/v4/gameauth', '{"h2":"meow"}')
	
	if code == 200 and headers.bngstk then
		token = headers.bngstk
		print("received token: "..token)
		return token
	else
		print("got non-200 ("..tostring(code)..") response: "..tostring(resp))
	end
end

function get_mod(filename, version)
	local resp, code, headers = api_call('/s1/v4/download/mods/'..version..'/'..filename)

	print('CDN url: '..headers.location)


        local success, code, headers, status_line = http.request({
                url = headers.location,
                sink = ltn12.sink.file(io.open("Resources/Client/"..filename, 'w+'))
        })

	print(success, code, status_line)


end


M.get_token = get_token
M.call = api_call
M.get_mod = get_mod

return M

