local IDs = require("MLS_Bot/IDs")

local function wipePredictions(msg, user, server)
	local registeredUsersDoc = io.open("Record_Documents/Registered Users.txt", "r")
	if not registeredUsersDoc then return "Critical error in opening registered users document" end

	msg:reply("Wiping predictions...")

	local registeredUsers = registeredUsersDoc:read("*all")
	registeredUsersDoc:close()

	for line in registeredUsers:gmatch("([^\n]*)\n?") do
		if string.match(line, "%S+") then
			local userPredictionsDoc = io.open("Record_Documents/User_Predictions/" .. line .. ".txt", "w")
			if userPredictionsDoc then
				userPredictionsDoc:write("")
			end
			userPredictionsDoc:close()
		end
	end

	for _, record in pairs(server:getChannel(IDs.predictionRecords):getMessages()) do
		record:delete()
	end

	msg:reply("All predictions successfully wiped.")
end

return wipePredictions