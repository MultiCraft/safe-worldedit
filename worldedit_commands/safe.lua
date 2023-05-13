local S = minetest.get_translator("worldedit_commands")

--`count` is the number of nodes that would possibly be modified
--`callback` is a callback to run when the user confirms
local max_size = tonumber(minetest.settings:get("worldedit.max_region_size")) or 20000

local function safe_region(name, count, callback)
	if count < max_size then
		return callback()
	end

	worldedit.player_notify(name, "This operation would affect up to " .. count .. " nodes; you can only update " ..
		max_size .. " nodes at a time")
end

return safe_region
