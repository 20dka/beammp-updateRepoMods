json = require('json')
lfs = require('lfs')

api = require('api')

ignore_list = {}

-- function to capture output of system calls
function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end


function onInit()
	-- get a beamng api token
	if not api.get_token() then print("shits fucked") return end

	-- check all zips, excluding those in the txt
	if FS.Exists("dontupdate.txt") then
		ignore_list = {}
		for mod in io.lines("dontupdate.txt") do
			ignore_list[mod] = true
		end
	end

	--loop_mods()
end

function loop_mods()
	local path = "./Resources/Client"
	-- loop through files (exclude subfolders)
	for file in lfs.dir(path) do
		if string.match(file, ".+%.zip$") and not ignore_list[file] then
			local f = path..'/'..file
			check_mod(f, file)
		end
	end
end

function check_mod(path, file)
	-- find the mod's "tagid"
	local zip_contents
	if MP.GetOSName() == "Windows" then
		zip_contents = os.capture("7za.exe -l " .. path)
	else
		zip_contents = os.capture("unzip -l " .. path)
	end
	tagid = string.match(zip_contents, ".+mod_info/(%g+)/info.json")
	print(string.format("Checking mod %s (ID:%s)", file, tagid))

	-- pipe json contents into string then parse it
	local local_mod_info_str
	if MP.GetOSName() == "Windows" then
		local_mod_info_str = os.capture(string.format("7za.exe x -so %s mod_info/%s/info.json", path, tagid))
	else
		local_mod_info_str = os.capture(string.format("unzip -p %s mod_info/%s/info.json", path, tagid))
	end
	local local_mod_info = json.parse(local_mod_info_str)
	print("\tlocal resource_version_id", local_mod_info.resource_version_id)

	-- get info about mod from the API
	local remote_mod_info = api.call('/s1/v4/getMod/'..local_mod_info.tagid)
	print("\tremote resource_version_id", remote_mod_info.current_version_id)

	if remote_mod_info.current_version_id > local_mod_info.resource_version_id then
		print('\tmod is out of date, updating')
		update_mod(path, remote_mod_info.filename, tagid..'/'..remote_mod_info.current_version_id)
	end
end

function update_mod(path, filename, version)
	-- move old mod to a folder inside 'Client'
	FS.CreateDirectory("Resources/Client/outdated")
	FS.Remove("Resources/Client/outdated/"..filename)
	FS.Rename(path, "Resources/Client/outdated/"..filename)

	-- get new mod (will possibly override filename)
	api.get_mod(filename, version)
end
