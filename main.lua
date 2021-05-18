--- Main Variables
local PREFIX = ";"
local discordia = require("discordia")
local client = discordia.Client()
local json = require("json")
local clock = discordia.Clock()

--- IDs
local idList = require("MLS_Bot/IDs")
local botId = idList.botId
local botManagementId = idList.botManagementId -- Role that's allowed to use mod commands
local serverId = idList.serverId

--- Command modules
local help = require("MLS_Bot/Commands/Help")
local predict = require("MLS_Bot/Commands/Predict")
local ping = require("MLS_Bot/Commands/Ping")
local setStandings = require("MLS_Bot/Commands/SetStandings")
local toggleSummaries = require("MLS_Bot/Commands/ToggleSummaries")
local leavePredictions = require("MLS_Bot/Commands/LeavePredictions")
local detailedStats = require("MLS_Bot/Commands/DetailedStats")
local wipePredictions = require("MLS_Bot/Commands/WipePredictions")

--- List of commands
local listOfCommands = {
    {Name = "help", Function = help, Description = "Shows a list of all available commands."};
    {Name = "ping", Function = ping, Description = "Test uptime and server latency."};
    {Name = "predict", Function = predict, Description = "Start the prediction prompt."};
    {Name = "togglesummaries", Function = toggleSummaries, Description = "Toggle prediction summaries being DMed to you on/off."};
    {Name = "leavepredictions", Function = leavePredictions, Description = "Completely opt out of the predictions league."};
    {Name = "detailedstats", Function = detailedStats, Description = "View detailed prediction league stats. Use " .. PREFIX .. "detailedstats [@user] to see someone else's."};

    {Name = "setstandings", Function = setStandings, Description = "Set the standings of the current week (results must be recorded).", Mod = true};
    {Name = "wipepredictions", Function = wipePredictions, Description = "Deletes all users' predictions for the new week.", Mod = true};
}

--- Set status
client:on("ready", function() -- bot is ready
    client:setGame("Say " .. PREFIX .. "help for a list of commands!")
end)

--- Message event
client:on("messageCreate", function(msg)
	if msg.author.bot then return end -- Ignore messages made by the bot

    local content = msg.content

    local mentionedUsers = msg.mentionedUsers

    local mentionsBot
    if mentionedUsers then
        for _, user in pairs(mentionedUsers) do
            if tostring(user) == "User: " .. botId then
                mentionsBot = true
            end
        end
    end

    if mentionsBot then
        msg:reply("Hello! Say `" .. PREFIX .. "help` for a list of commands. ")
    end

    --- Commands
    if string.sub(content, 1, string.len(PREFIX)) == PREFIX then
        --if not  return end
        local channelIsBotChannel
        for _, channel in pairs(idList.botChannels) do
            if msg.channel.id == channel then
                channelIsBotChannel = true
            end
        end

        if not channelIsBotChannel then msg:reply("Commands can only be used in a bot channel!") return end

        local messageInput = string.match(content, "%a+")

        local matchingCommand
        
        for id, cmd in pairs(listOfCommands) do
            if cmd.Name == messageInput then
                matchingCommand = cmd
            end
        end

        if matchingCommand then
            local function execute()
                local server = client:getGuild(serverId)
                local executeCommand

                if matchingCommand.Name == "help" then
                    local color = discordia.Color.fromRGB(0, 210, 0).value

                    executeCommand = matchingCommand.Function(msg, msg.author, server, PREFIX, listOfCommands, botManagementId, color)
                elseif matchingCommand.Name == "setstandings" or matchingCommand.Name == "detailedstats" then
                    executeCommand = matchingCommand.Function(msg, msg.author, server, client, json)
                else
                    executeCommand = matchingCommand.Function(msg, msg.author, server, client)
                end

                if type(executeCommand) == "string" then -- If the function returns a string then reply with that string
                    msg:reply(executeCommand)
                end
            end
            if not matchingCommand.Mod then
                execute()
            else
                if msg.member:hasRole(botManagementId) then
                    execute()
                else
                    msg:reply("You do not have permission to use this command!")
                end
            end
        else
            msg:reply("This command could not be found! Say `" .. PREFIX .. "help` for a list of commands.")
        end
    end
	--]]
end)


------- RUN BOT
local botToken = io.open("./Bot_Token.txt")
client:run(botToken:read())
botToken:close()