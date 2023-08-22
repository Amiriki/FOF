-- Script Variables

local Players = game:GetService('Players')
local Teams = game:GetService('Teams')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local StarterGui = game:GetService('StarterGui')
local LocalPlayer = Players.LocalPlayer
local Stats = LocalPlayer.leaderstats
local Gold = Stats.Gold.Value
local XP = Stats.XP.Value
local HGold = Gold
local HXP = XP
local HourlyGold = 0
local HourlyExp = 0
local TimeElapsed = 0
local Time = os.time()

local NPCs = workspace['Unbreakable']['Characters']
local EnemyTeam
local Thumbnail = game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar?userIds="..LocalPlayer.UserId.."&size=420x420&format=Png&isCircular=false")

-- Script functions

function NotifyChat(message, colour)
	StarterGui:SetCore("ChatMakeSystemMessage", {Text = "[Field of Heaven] "..message, Color = colour, Font = Enum.Font.SourceSansBold, TextSize = 16})
end

function Format_Number(num) -- I skidded this whole function; I don't know how it works and I don't want to know
	local formatted = num
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end

function SendWebhook()
	local Split_Label = string.gsub(LocalPlayer.PlayerGui.Gui.XPBar.TextLabel.Text, 'Level Up: ', '')
	local data = {
		["username"] = LocalPlayer.DisplayName,
		["embeds"] = {{
			["title"] = "Field of Heaven Autofarm",
			["description"] = "Round over!",
			["thumbnail"] = {
				["url"] = HttpService:JSONDecode(Thumbnail).data[1].imageUrl
			},
			["type"] = "rich",
			["color"] = tonumber(0x00ffff),
			["fields"] = {
				{
					["name"] = ":moneybag: Gold",
					["value"] = tostring(Format_Number(Stats.Gold.Value))..' (+'..(Format_Number(Stats.Gold.Value - Gold))..')',
					["inline"] = false
				},
				{
					["name"] = ":moneybag: Hourly Gold :hourglass:",
					["value"] = tostring(Format_Number(math.floor(HourlyGold + 0.5))),
					["inline"] = false
				},
				{
					["name"] = ":man_in_tuxedo: Exp",
					["value"] = tostring(Format_Number(Stats.XP.Value))..' (+'..(Format_Number(Stats.XP.Value - XP))..')',
					["inline"] = false
				},
				{
				["name"] = ":man_in_tuxedo: Hourly Exp :hourglass:",
					["value"] = tostring(Format_Number(math.floor(HourlyExp + 0.5))),
					["inline"] = false
				},
				{
					["name"] = ":test_tube: Level",
					["value"] = tostring(Stats.Level.Value)..' ('..Format_Number(string.split(Split_Label, ' / ')[1])..' / '..Format_Number(string.split(Split_Label, ' / ')[2])..')',
					["inline"] = false
				},
				{
					["name"] = ":stopwatch: Time Elapsed",
					["value"] = tostring(Format_Number(TimeElapsed))..' seconds',
					["inline"] = false
				},
				{
					["name"] = ":scroll: Changelog 21/08/23",
					["value"] = [[```- Added 'IgnorePlayers' feature to the config. Set is as you would any other part of the config.
					This is a useful feature for autofarming on two accounts in the same server. 
					- Improved map vote handling so that it always votes.
					- Reworked some functions to work better
					Join the discord at dsc.gg/amiriki (cool dsc.gg url i know!!!1!!)```]],
					["inline"] = false
				},
			},

			["footer"] = {
				["icon_url"] = "https://i.vgy.me/7hO15E.png",
				["text"] = 'Round lasted '..(os.time() - Time)..' seconds | developed by amiriki | dsc.gg/amiriki for feedback'
			}
		}}
	}
request({Url = FOFConfig.WebhookURL, Method = 'POST', Headers = {['Content-Type'] = 'application/json'}, Body = HttpService:JSONEncode(data)})

	XP = Stats.XP.Value
	Gold = Stats.Gold.Value
	Time = os.time()
end

function ObtainTargets()
	local TargetsList
    local EnemyTeam
    local Index
	local General

	if LocalPlayer.Team == Teams:FindFirstChild('Neutral') then return {} end
	if LocalPlayer.Team == Teams:FindFirstChild('Orc') then EnemyTeam = 'Human' end
	if LocalPlayer.Team == Teams:FindFirstChild('Human') then EnemyTeam = 'Orc' end

	TargetsList = NPCs[EnemyTeam]:GetChildren()

	for i, npc in pairs(TargetsList) do
		if npc.Name:find('General')  then
			Index = i
			General = npc
		end
	end

    if FOFConfig.IgnorePlayers then
        for i, player in pairs(Players:GetPlayers()) do
            if table.find(TargetsList, player.Name) then
                TargetsList[i] = nil
            end
        end
    end

	TargetsList[Index] = nil
	table.insert(TargetsList, #TargetsList, General)
	return TargetsList
end

function Attack(target, weapon)
    if not target or not weapon then return end
	NotifyChat('Attacking enemy '..target.Name, Color3.fromRGB(69, 69, 215))
	if LocalPlayer.Backpack:FindFirstChild(weapon) then LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild(weapon)) end

	repeat
		pcall(function()
			if not target:FindFirstChild('Torso') then return end
			LocalPlayer.Character:FindFirstChild(weapon):Activate()
			LocalPlayer.Character.HumanoidRootPart.CFrame = target.Torso.CFrame * CFrame.new(0,0,3)
		end)
		task.wait(0.125)
	until not target or not target:FindFirstChild('Humanoid') or target:FindFirstChild('Humanoid').Health == 0 or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('Humanoid') or LocalPlayer.Character:FindFirstChild('Humanoid').Health == 0
end

-- Script events
LocalPlayer.CharacterAdded:Connect(function()
    if FOFConfig.AutofarmEnabled then
		local CurrentWeapon
        local Enemies = ObtainTargets()
        for index, npc in pairs(Enemies) do
            if not FOFConfig.AutofarmEnabled then return NotifyChat('Autofarm is disabled', Color3.fromRGB(215, 69, 69)) end
            if Teams:FindFirstChild('Neutral') and LocalPlayer.Team == Teams:FindFirstChild('Neutral') then return end

            if npc.Name:find('General') then CurrentWeapon = FOFConfig.BossWeapon else CurrentWeapon = FOFConfig.NPCWeapon end 
	        repeat task.wait() until LocalPlayer.Backpack:FindFirstChild(CurrentWeapon) or LocalPlayer.Character:FindFirstChild(CurrentWeapon)
			Attack(npc, CurrentWeapon)
            Enemies[index] = nil
        end
    end
end)

Players.PlayerAdded:Connect(function()
	if FOFConfig.DisableOnJoin then
		FOFConfig.AutofarmEnabled = false
		LocalPlayer.Character:BreakJoints()
	end
end)

Players.PlayerRemoving:Connect(function()
	if FOFConfig.EnableOnLeave then
		if #Players:GetPlayers() == 1 then
			FOFConfig.AutofarmEnabled = true
			LocalPlayer.Character:BreakJoints()
		end
	end
end)

NPCs.DescendantAdded:Connect(function(obj)
	if obj.Name:find('General') then 
		local Humanoid = obj:WaitForChild('Humanoid', 3)
		if Humanoid then
			obj:WaitForChild('Humanoid').Died:Connect(function()
				if FOFConfig.AutofarmEnabled then
					Players:Chat(':mapvote '..(FOFConfig.Map or 'Savannah'))
					SendWebhook() 
				end
			end)
		end
	end
end)

for i, v in pairs(NPCs:GetDescendants()) do
	if v.Name:find('General') and v:FindFirstChild('Humanoid') then 
		v:FindFirstChild('Humanoid').Died:Connect(function()
			if FOFConfig.AutofarmEnabled then
				Players:Chat(':mapvote '..(FOFConfig.Map or 'Savannah'))
				SendWebhook() 
			end
		end)
	end
end

spawn(function()
	while task.wait(1) do
		if not FOFConfig.AutofarmEnabled then return end
	
		GoldGained = Stats.Gold.Value - HGold
		ExpGained = Stats.XP.Value - HXP
		TimeElapsed = TimeElapsed + 1
	
		HourlyGold = (GoldGained / TimeElapsed) * 3600
		HourlyExp = (ExpGained / TimeElapsed) * 3600
	end
end)

if FOFConfig.AutoShutdownTimer and FOFConfig.AutoShutdownTimer > 0 then
	spawn(function()
		task.wait(FOFConfig.AutoShutdownTimer * 3600)
		game:Shutdown()
	end)
end

RunService:Set3dRenderingEnabled(not FOFConfig.DisableRendering)

Players.LocalPlayer.Idled:connect(function()
	game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

LocalPlayer.Character:BreakJoints()

NotifyChat("Development Autofarm has successfully been executed.", Color3.fromRGB(69, 215, 69))
NotifyChat("Report any bugs to Amiriki on Discord", Color3.fromRGB(69, 69, 215))
NotifyChat("Join the Discord at dsc.gg/amiriki", Color3.fromRGB(69, 69, 215))
