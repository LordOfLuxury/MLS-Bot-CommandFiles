local ids = require("MLS_Bot.IDs")

local usersLeaving = {}
local function leavePredictions(msg, user, server, client)
	local registeredUsersDoc = io.open("Record_Documents/Registered Users.txt", "r+")
	if not registeredUsersDoc then return "Could not find registered users document. Please try again later" end

	if usersLeaving[user] then return end

	usersLeaving[user] = true

	local registeredUsers = registeredUsersDoc:read("*all")
	registeredUsersDoc:close()

	if not string.match(registeredUsers, tostring(user.id)) then return "You are not signed up for the predictions league!" end

	msg:reply("Are you sure you would like to drop out of the prediction league? This action is irreversible and all your points will be wiped. Reply `yes` to confirm, reply `no` to cancel.")

	local waitForConfirmation
	waitForConfirmation = client:on("messageCreate", function(confirmationMsg)
		if confirmationMsg.author ~= user then return end
		local confirmation = confirmationMsg.content

		if confirmation:lower() == "yes" then
			client:removeListener("messageCreate", waitForConfirmation)

			--- Overwrite
			registeredUsersDoc = io.open("Record_Documents/Registered Users.txt", "w")

			local newList = string.gsub(registeredUsers, tostring(user.id) .. "\n", "") -- Erase
			registeredUsersDoc:write(newList)

			registeredUsersDoc:close()

			--- Delete predictions document
			local successfulRemoval, errorMessage = os.remove("Record_Documents/User_Predictions/" .. tostring(user.id) .. ".txt")
			if not successfulRemoval then
				msg:reply("Prediction record document failed to delete. Notify the owner. This error is not critical. " .. errorMessage)
			end

			--- Delete record in the records channel
			local recordsChannel = server:getChannel(ids.predictionRecords)
			if not recordsChannel then
				msg:reply("Could not access the records channel. Notify the owner. This error is not critical.")
			end

			--local userRecord
			for _, record in pairs(recordsChannel:getMessages()) do
				if string.match(record.content, user.mentionString) then
					record:delete()
				end
			end

			--- Remove predictions role
			server:getMember(user.id):removeRole(ids.predictionsRole)

			msg:reply("Successfully left the predictions league and wiped all data.")
			usersLeaving[user] = nil
		elseif confirmation:lower() == "no" then
			client:removeListener("messageCreate", waitForConfirmation)

			msg:reply("Cancelled.")
			usersLeaving[user] = nil
		end
	end)
end

return leavePredictions