--- Toggles weekly standings summary DM.

local function toggleSummaries(msg, user)
	local noSummariesListDoc = io.open("Record_Documents/noSummariesList.txt", "r+")
	if not noSummariesListDoc then return "Critical error in finding summaries blacklist. Please try again later." end

	local userId = tostring(user.id)

	local noSummariesList = noSummariesListDoc:read("*all")

	local isOnBlacklist = string.match(noSummariesList, userId)

	noSummariesListDoc:close()
	noSummariesListDoc = io.open("Record_Documents/noSummariesList.txt", "w")

	if isOnBlacklist then
		local newList = string.gsub(noSummariesList, userId .. "\n", "")
		noSummariesListDoc:write(newList)
		msg:reply("Successfully removed you from the blacklist. You will recieve weekly summaries.")
	else
		local newList = noSummariesList .. tostring(userId) .. "\n"
		noSummariesListDoc:write(newList)
		msg:reply("Successfully added you to the blacklist. You will not recieve weekly summaries but will still recieve points. Use the `leavepredictions` command to drop out entirely.")
	end

	noSummariesListDoc:close()
end

return toggleSummaries