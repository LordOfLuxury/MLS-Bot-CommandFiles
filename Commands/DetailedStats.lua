local function detailedStats(msg, user, _, _, json)
	local mentionedUser
	for _, userMentioned in pairs(msg.mentionedUsers) do
		mentionedUser = userMentioned
		break
	end
	mentionedUser = mentionedUser or user

	if mentionedUser.bot then return end

	local standingsDoc = io.open("Record_Documents/Standings.json", "r")
	local currentStandings = standingsDoc:read("*all")
	standingsDoc:close()

	currentStandings = json.parse(currentStandings)

	if not currentStandings then msg:reply("There are no standings.") return end

	local userStandings = currentStandings[mentionedUser.id]

	if not userStandings then msg:reply("No data has been found for this user in standings.") return end

	msg:reply({
		embed = {
			title = "Detailed Summary";
			author = {
				name = mentionedUser.tag,
				icon_url = mentionedUser.avatarURL
			};
			fields = {
				{
					name = "Total Points",
					value = userStandings.TotalPoints,
				};
				{
					name = "Points per Week (PPW)",
					value = userStandings.PointsPerWeek,
				};
				{
					name = "Correct Scores",
					value = userStandings.CorrectScores,
				};
				{
					name = "Correct Results",
					value = userStandings.CorrectResults,
				};
				{
					name = "Weeks Participated In",
					value = userStandings.WeeksParticipated,
				};
			};
			footer = {
				text = "MLS Discord Prediction League (created by curtis Vol. IV chapter 4#0004)"
			};
			color = 0xD52600
		}
	})
end

return detailedStats