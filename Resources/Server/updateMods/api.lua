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

	local str = table.concat(t, '')

	if headers['content-type'] == "application/json" then
		local parsed = json.parse(str)
		str = parsed.data and parsed.data or parsed
	end

	return str, code, headers
end

function get_token()
	-- h2 is the magic identifier, should be kept same on the same host, I think
	local resp, code, headers = http.request(host..'/s2/v4/gameauth', '{"h2":"'..os.time()..'"}')

	if code == 200 and headers.bngstk then
		token = headers.bngstk
		print("received token: "..token)
		return token
	else
		print("got non-200 ("..tostring(code)..") response: "..tostring(resp))
	end
end

function get_mod(filename, version)
	-- get ourselves a freshly baked CDN url
	local resp, code, headers = api_call('/s1/v4/download/mods/'..version..'/'..filename)

	print('\tCDN url: '..headers.location)

	-- download it with ltn12 to the Client folder
        local success, code, headers, status_line = http.request({
                url = headers.location,
                sink = ltn12.sink.file(io.open("Resources/Client/"..filename, 'w+'))
        })
	return success
end


M.get_token = get_token
M.call = api_call
M.get_mod = get_mod

return M
