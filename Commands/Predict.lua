-- Prompts the users to guess all the results for the upcoming week.
local channelIds = require("MLS_Bot/IDs")
local botFunctions = require("MLS_Bot/BotFunctions")
local createRecords = require("MLS_Bot/CreateRecords")
local predictionsChannelId = channelIds.predictions
local IDs = require("MLS_Bot/IDs")

local split = botFunctions.split -- Split string function

local usersPredicting = {}

local function Predict(msg, user, server, client)
	if tostring(msg.channel) ~= "GuildTextChannel: " .. predictionsChannelId then return "This can only be used in the predictions channel!" end

	if usersPredicting[user] then return "You are already predicting!" end

	local readMatchups = io.open("Record_Documents/Week Matchups.txt", "r")
	if not readMatchups then return "An error has occured. Please try again later." end

	local function stopPredicting(didNotPredict)
		usersPredicting[user] = nil
		
		if didNotPredict then return end

		--- Create records
		coroutine.wrap(function()
			createRecords(user, server, client)
		end)()
	end

	usersPredicting[user] = true

	local userIsRegistered = false
	local madePrediction = false
	local skippedMatch = false

	local matchList = readMatchups:read("a")

	--- Go through each line and split it by spaces
	local matchups = {}
	local currentIndex = 1

	for line in matchList:gmatch("([^\n]*)\n?") do
		if string.match(line, "%S+") then
			table.insert(matchups, line)
		end
	end

	local notDoneMatchups = {}

	local predictionsAlreadyMade = io.open("Record_Documents/User_Predictions/" .. tostring(user.id) .. ".txt", "r")
	if predictionsAlreadyMade then
		local predictionsMade = predictionsAlreadyMade:read("*all")
		for _, matchup in pairs(matchups) do
			if not string.match(predictionsMade, matchup) then
				table.insert(notDoneMatchups, matchup)
			end
		end
		matchups = notDoneMatchups -- Overwrite
	end

	notDoneMatchups = nil

	local function promptMatchup()
		local line = matchups[currentIndex]

		if not line then
			if madePrediction then
				msg:reply("**All predictions for this week have been recorded!** " .. user.mentionString)
			else
				if skippedMatch then
					msg:reply("Haha we have a funny jokester guy here. So funny. Skipping every prediction. Cunt. " .. user.mentionString)
				else
					msg:reply("You have already recorded your predictions for this week! " .. user.mentionString)
				end
			end
			stopPredicting(not madePrediction) -- They might have just said skip a dozen times
			return
		end

		local matchTeams = split(line, "vs")
		local team1 = matchTeams[1]
		local team2 = matchTeams[2]

		if team1 and team2 then
			-- Prompt prediction
			msg:reply("**" .. msg.member.name .. "**, reply with your predicted score for __**" .. line .. "**__. (format example: `3-2`) (reply `cancel` to stop and `skip` to skip)")

			coroutine.wrap(function()
				local waitForPrediction, predictionMsg = client:waitFor("messageCreate", 90000, function(predictionMsg) -- 90 seconds before timeout
					-- Input validation
					
					if predictionMsg.author ~= user then return end
					if predictionMsg.channel ~= msg.channel then return end
					local prediction = predictionMsg.content

					if predictionMsg.content:lower() == "cancel" or predictionMsg.content:lower() == "skip" then return true end

					if #prediction ~= 3 then return end -- Must be in format a-b
					local scoreSplit = split(prediction, "-") -- Split into a table by the "-" character
					if #scoreSplit ~= 2 then return end

					local homeGoals = tonumber(scoreSplit[1])
					local awayGoals = tonumber(scoreSplit[2])

					if not (homeGoals and awayGoals) then return end

					return true
				end)

				if waitForPrediction then
					-- --[[
					---- CANCEL
					local prediction = predictionMsg.content
					if prediction:lower() == "cancel" then
						msg:reply(user.mentionString .. " cancelled. You can use the wipe command to erase all your predictions for this week.")

						stopPredicting(not madePrediction)
						--client:removeListener("messageCreate", waitForPrediction)
						return
					elseif prediction:lower() == "skip" then
						skippedMatch = true
						currentIndex = currentIndex + 1

						--client:removeListener("messageCreate", waitForPrediction)

						coroutine.wrap(function() -- Return right away and get this function finished
							promptMatchup()
						end)()
						return
					end

					-- Success! Register prediction.
					local success, errorMessage = pcall(function()
						--client:removeListener("messageCreate", waitForPrediction)
					end)

					if not success then
						msg:reply("Error occurred in listener cleanup: " .. errorMessage)
					end

					server:getMember(user.id):addRole(IDs.predictionsRole)

					local userPredictions = io.open("Record_Documents/User_Predictions/" .. tostring(user.id) .. ".txt", "a+")

					userPredictions:write(line .. " // " .. prediction .. "\n")

					userPredictions:close()

					madePrediction = true

					-- Register the user
					if not userIsRegistered then
						local registeredUsersList = io.open("Record_Documents/Registered Users.txt", "a+") -- List of all registered users

						local list = registeredUsersList:read("*all")

						if not string.match(list, tostring(user.id)) then
							registeredUsersList:write(user.id .. "\n")
						end

						userIsRegistered = true

						registeredUsersList:close()
					end

					currentIndex = currentIndex + 1

					promptMatchup()
					--]]
				else
					msg:reply(user.mentionString .. " your prediction input has timed out. Any made have been recorded. Use the `predict` command again to continue.")
					stopPredicting(not madePrediction)
				end
			end)()
		end
	end

	promptMatchup()

	readMatchups:close()
end

return Predict