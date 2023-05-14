local S = minetest.get_translator("worldedit_commands")

--`count` is the number of nodes that would possibly be modified
--`callback` is a callback to run when the user confirms
local max_nodes = tonumber(minetest.settings:get("worldedit.max_region_nodes")) or 20000
local max_size = tonumber(minetest.settings:get("worldedit.max_area_size")) or 128
local abs = math.abs
local safe_region_callback = {}

local function safe_region(name, count, callback, strict)
	if count < max_nodes then
		return callback()
	end

	-- Prevent the operation if strict is set (if the safe_area check wasn't used)
	if strict then
		worldedit.player_notify(name, "This operation would affect up to " ..
			count .. " nodes; you can only update " .. max_size .. " nodes at a time")
		return
	end

	--save callback to call later
	safe_region_callback[name] = callback
	worldedit.player_notify(name, "WARNING: this operation could affect up to " .. count .. " nodes; type //y to continue or //n to cancel")
end

local function reset_pending(name)
	safe_region_callback[name] = nil
end

minetest.register_on_leaveplayer(function(player)
	reset_pending(player:get_player_name())
end)

minetest.register_chatcommand("/y", {
	params = "",
	description = "Confirm a pending operation",
	func = function(name)
		local callback = safe_region_callback[name]
		if not callback then
			worldedit.player_notify(name, "no operation pending")
			return
		end

		reset_pending(name)
		callback(name)
	end,
})

minetest.register_chatcommand("/n", {
	params = "",
	description = "Abort a pending operation",
	func = function(name)
		if not safe_region_callback[name] then
			worldedit.player_notify(name, "no operation pending")
			return
		end

		reset_pending(name)
	end,
})

local function safe_area(name, pos1, pos2)
	if abs(pos2.x - pos1.x) + 1 > max_size or abs(pos2.x - pos1.x) + 1 > max_size or
			abs(pos2.z - pos1.z) + 1 > max_size then
		worldedit.player_notify(name, S("Your selected area is too big, you can only select areas up to @1 × @2 × @3",
			max_size, max_size, max_size))
		return false
	end
	return true
end

return safe_region, reset_pending, safe_area
