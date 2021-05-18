local botFunctions = require("MLS_Bot/BotFunctions")
local IDs = require("MLS_Bot/IDs")
local split = botFunctions.split -- Split string function

local function setStandings(msg, _, server, client, json)
	local resultsDoc = io.open("Record_Documents/Week Results.txt", "r")
	if not resultsDoc then return "Critical error in opening results document" end
	local registeredUsersDoc = io.open("Record_Documents/Registered Users.txt", "r")
	if not registeredUsersDoc then return "Critical error in opening registered users document" end

	msg:reply("Setting standings. Please wait...")

	local results = resultsDoc:read("*all")
	local registeredUsers = registeredUsersDoc:read("*all")

	local standings = {} -- Keep all standings info here

	local standingsDoc = io.open("Record_Documents/Standings.json", "r")
	local currentStandings = standingsDoc:read("*all")
	standingsDoc:close()

	--- Record prediction accuracy for each user
	for line in registeredUsers:gmatch("([^\n]*)\n?") do
		if string.match(line, "%S+") then
			local totalPoints = 0
			local summary = {}
			local skippedPredictions = {}

			local user = client:getUser(line)

			local userPredictionsDoc = io.open("Record_Documents/User_Predictions/" .. user.id .. ".txt", "r")
			if userPredictionsDoc then
				standings[user.id] = {CorrectResults = 0, CorrectScores = 0} -- Allocate section in standings table
				local userStandingsInfo = standings[user.id]

				local predictions = userPredictionsDoc:read("*all")

				-- Matches skipped
				for result in results:gmatch("([^\n]*)\n?") do
					local teams = split(result, " // ")[1]
					if teams then
						if not string.match(predictions, teams) then
							table.insert(skippedPredictions, result)
						end
					end
				end

				--- Go through each prediction
				for prediction in predictions:gmatch("([^\n]*)\n?") do
					if string.match(prediction, "%S+") then
						local predictionDivider = split(prediction, " // ")
						local teamsPredicted = predictionDivider[1]
						local resultPredicted = predictionDivider[2]
						
						--- Find the line in the results doc with the same teams as the prediction
						local predictionLine
						for result in results:gmatch("([^\n]*)\n?") do
							if string.match(result, teamsPredicted) then
								predictionLine = result
							end
						end

						--- Verify accuracy of result
						local resultSplit = split(predictionLine, " // ")
						local finalResult = resultSplit[2]
						local result_splitHomeAndAway = split(finalResult, "-")
						local result_homeGoals = result_splitHomeAndAway[1]
						local result_awayGoals = result_splitHomeAndAway[2]

						local prediction_splitHomeAndAway = split(resultPredicted, "-")
						local prediction_homeGoals = prediction_splitHomeAndAway[1]
						local prediction_awayGoals = prediction_splitHomeAndAway[2]

						local function setSummary(pointsEarned)
							table.insert(summary, teamsPredicted .. " // __" .. finalResult .. "__" .. "\n----> Your prediction: __" .. resultPredicted .. "__ **(" .. pointsEarned .. ")**") -- Set summary
						end

						--- Determine correct result
						local splitTeams = split(teamsPredicted, " vs ")
						local homeTeam = splitTeams[1]
						local awayTeam = splitTeams[2]

						local winnerPredicted
						if prediction_homeGoals == prediction_awayGoals then
							winnerPredicted = "Draw"
						elseif prediction_homeGoals > prediction_awayGoals then
							winnerPredicted = homeTeam
						elseif prediction_homeGoals < prediction_awayGoals then
							winnerPredicted = awayTeam
						end

						local actualWinner
						if result_homeGoals == result_awayGoals then
							actualWinner = "Draw"
						elseif result_homeGoals > result_awayGoals then
							actualWinner = homeTeam
						elseif result_homeGoals < result_awayGoals then
							actualWinner = awayTeam
						end

						if winnerPredicted ~= actualWinner then
							-- Incorrect result. Zero points
							setSummary("0 pts")
						else
							userStandingsInfo.CorrectResults = userStandingsInfo.CorrectResults + 1
							--- Correct result, calculate points
							if result_homeGoals == prediction_homeGoals and result_awayGoals == prediction_awayGoals then
								--- Correct score
								totalPoints = totalPoints + 3
								setSummary("3 pts :thumbsup:")
								userStandingsInfo.CorrectScores = userStandingsInfo.CorrectScores + 1
							elseif result_homeGoals == prediction_homeGoals or result_awayGoals == prediction_awayGoals then
								--- One goal correct
								totalPoints = totalPoints + 2
								setSummary("2 pts :thumbsup:")
							else
								--- Both goals incorrect.
								totalPoints = totalPoints + 1
								setSummary("1 pt :thumbsup:")
							end
						end
					end
				end

				--- Add to standings
				local currentStandingsParsed = json.parse(currentStandings)
				local oldStandingsInfo
				if currentStandingsParsed then
					oldStandingsInfo = currentStandingsParsed[user.id]
				end

				local member = server:getMember(user.id)
				userStandingsInfo.Name = member.name
				userStandingsInfo.UserID = user.id

				if oldStandingsInfo then
					--- Update existing
					userStandingsInfo.TotalPoints = oldStandingsInfo.TotalPoints + totalPoints
					userStandingsInfo.WeeksParticipated = oldStandingsInfo.WeeksParticipated + 1
					userStandingsInfo.CorrectResults = oldStandingsInfo.CorrectResults + userStandingsInfo.CorrectResults
					userStandingsInfo.CorrectScores = oldStandingsInfo.CorrectScores + userStandingsInfo.CorrectScores
				else
					--- Create new
					userStandingsInfo.TotalPoints = totalPoints
					userStandingsInfo.WeeksParticipated = 1
				end

				userStandingsInfo.PointsPerWeek = userStandingsInfo.TotalPoints / userStandingsInfo.WeeksParticipated

				standings[user.id] = userStandingsInfo

				--- Convert to json
				local userStandingsInJson = json.encode(standings)
				standingsDoc = io.open("Record_Documents/Standings.json", "w")
				standingsDoc:write(userStandingsInJson)
				standingsDoc:close()

				------ SUMMARY
				-- Number off each match
				for index, matchSummary in pairs(summary) do
					summary[index] = tostring(index .. ") " .. matchSummary)
				end

				-- Skipped predictions
				local skippedString = ""
				if #skippedPredictions > 0 then
					skippedString = "\n\n**Matches skipped:**\n" .. table.concat(skippedPredictions, "\n")
				end

				local summaryMsg = "__**MLS PREDICTIONS SUMMARY:**__\n\n" .. table.concat(summary, "\n") .. skippedString .. "\n----------------------\n__**TOTAL: " .. tostring(totalPoints) .. " PTS**__"
				summaryMsg = summaryMsg .. "\n\n**You can opt out of weekly summaries by using the `togglesummaries` command from the MLS Discord.**"

				local summaryBlacklistDoc = io.open("Record_Documents/noSummariesList.txt", "r")

				if not string.match(summaryBlacklistDoc:read("*all"), tostring(user.id)) then
					user:send(summaryMsg) -- DM the user their summary
				end
				summaryBlacklistDoc:close()
			else
				msg:reply("Could not open predictions document for " .. user.mentionString)
			end
			userPredictionsDoc:close()
		end
	end

	resultsDoc:close()
	registeredUsersDoc:close()

	--- Create string to post in standings channel
	local userByPoints = {}
	for _, userStats in pairs(standings) do
		table.insert(userByPoints, userStats)
	end

	--- Calculate standings w/ tiebreakers
	math.randomseed(os.time())

	table.sort(userByPoints, function(a,b)
		-- Points
		if a.TotalPoints > b.TotalPoints then
			return true
		elseif a.TotalPoints < b.TotalPoints then
			return false
		end
		-- Only goes through if tied
		-- PPW
		if a.PointsPerWeek > b.PointsPerWeek then
			return true
		elseif a.PointsPerWeek < b.PointsPerWeek then
			return false
		end
		-- Correct scores
		if a.CorrectScores > b.CorrectScores then
			return true
		elseif a.CorrectScores < b.CorrectResults then
			return false
		end
		-- Correct results
		if a.CorrectResults > b.CorrectResults then
			return true
		elseif a.CorrectResults < b.CorrectResults then
			return false
		end
		-- Weeks participated
		if a.WeeksParticipated > b.WeeksParticipated then
			return true
		elseif a.WeeksParticipated < b.WeeksParticipated then
			return false
		end
		-- Coin flip
		return (math.random(1, 2) == 1)
	end)

	-- Create a string for each user's line in the standings
	local eachStandingsLine = {}
	for position, data in ipairs(userByPoints) do
		table.insert(eachStandingsLine, tostring(position) .. ". " .. data.Name .. " (" .. tostring(data.TotalPoints) .. " pts)")
	end

	local standingsString = "__**CURRENT STANDINGS**__\n```\n" .. table.concat(eachStandingsLine, "\n") .. "```\nUse the `detailedstats` command to see detailed stats. Use the `leavepredictions` command to drop out."

	local standingsChannel = server:getChannel(IDs.standings)
	if not standingsChannel then msg:reply("Could not find standings channel\n" .. standingsString) return end

	for _, message in pairs(standingsChannel:getMessages()) do
		message:delete()
	end

	standingsChannel:send(standingsString)

	msg:reply("**Standings set successfully!**")
end

return setStandings