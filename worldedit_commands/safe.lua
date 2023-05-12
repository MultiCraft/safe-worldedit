local S = minetest.get_translator("worldedit_commands")

--`count` is the number of nodes that would possibly be modified
--`callback` is a callback to run when the user confirms
local function safe_region(name, count, callback)
	if count < 20000 then
		return callback()
	end

	worldedit.player_notify(name, "This operation would affect up to " .. count .. " nodes; you can only update 20,000 nodes at a time")
end

return safe_region
