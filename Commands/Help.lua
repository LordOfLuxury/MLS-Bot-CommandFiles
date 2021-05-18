--local discordia = require("discordia")

local function Help(message, author, server, prefix, commandList, botManagementId, textColor)
	local member = message.member
    local showModCommands = false

    if member:hasRole(botManagementId) then
        showModCommands = true
    end

    local validCommands = {}
    local modCommands = {}

    for id, cmd in pairs(commandList) do
        if not cmd.Mod then
            table.insert(validCommands, prefix .. cmd.Name .. " | " .. cmd.Description)
        else
            table.insert(modCommands, prefix .. cmd.Name .. " | " .. cmd.Description)
        end
    end

    local fields
    if not showModCommands then
        message:reply{
            embed = {
               fields = {
                   {name = "Here is a list of all available commands:"; value = table.concat(validCommands, "\n")};
               };
               footer = {
                   text = "Created by curtis Vol. IV chapter 4#0004"
               };
			   color = textColor
               --color = discordia.Color.fromRGB(0, 210, 0).value
            }
        }
    else
        message:reply{
            embed = {
               fields = {
                   {name = "Here is a list of all available commands:"; value = table.concat(validCommands, "\n")};
                   {name = "Moderator commands:"; value = table.concat(modCommands, "\n")};
               };
               footer = {
                   text = "Created by curtis Vol. IV chapter 3#0004"
               };
			   color = textColor
              -- color = discordia.Color.fromRGB(0, 210, 0).value
            }
        }
    end
end

return Help