--- Records a user's predictions in the records channel

local IDs = require("MLS_Bot/IDs")

local function CreateRecords(user, server, client)
	local recordsChannel = server:getChannel(IDs.predictionRecords)

	if not recordsChannel then print("Error occurred in recording records for user " .. tostring(user.id)) return end

	local userPredictions = io.open("Record_Documents/User_Predictions/" .. tostring(user.id) .. ".txt", "r")
	local predictions = userPredictions:read("*all")

	local function getRecordMsgText()
		--- Generates the text to be used in the message
		return "**" .. user.mentionString .. "'s Predictions:**\n" .. predictions
	end

	--- Find if their message already exists; if it does, edit it. If not, create it.
	local recordMsg
	for _, msg in pairs(recordsChannel:getMessages()) do
		if string.match(msg.content, user.mentionString) then
			recordMsg = msg
		end
	end

	if not recordMsg then
		recordMsg = recordsChannel:send(getRecordMsgText())
	else
		recordMsg:setContent(getRecordMsgText())
	end

	userPredictions:close()
end

return CreateRecords