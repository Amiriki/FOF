-- Script variables

local Players = game:GetService('Players')
local Teams = game:GetService('Teams')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')

local LocalPlayer = Players.LocalPlayer
local Stats = LocalPlayer.leaderstats
local Gold = Stats.Gold.Value
local XP = Stats.XP.Value
local HGold = Gold
local HXP = XP
local HourlyGold = 0
local HourlyExp = 0
local GoldGained = 0
local ExpGained = 0
local TimeElapsed = 0
local Time = os.time()

local NPCs = workspace['Unbreakable']['Characters']
local EnemyTeam
local Thumbnail = game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar?userIds="..LocalPlayer.UserId.."&size=420x420&format=Png&isCircular=false")

-- Script functions

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
			["title"] = "Field of Farming Autofarm",
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
					["name"] = ":scroll: Changelog",
					["value"] = '- Updated the embed and added hourly rates, as well as time elapsed. Contact me to report any bugs or suggest new features.',
					["inline"] = false
				},
			},

			["footer"] = {
				["icon_url"] = "https://i.vgy.me/7hO15E.png",
				["text"] = 'Round lasted '..(os.time() - Time)..' seconds | developed by amiriki | contact me for feedback'
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
    local Index
	local General

    -- Figuring out what team to attack

	if LocalPlayer.Team == Teams:FindFirstChild('Neutral') then return {} end
	if LocalPlayer.Team == Teams:FindFirstChild('Orc') then EnemyTeam = 'Human' end
	if LocalPlayer.Team == Teams:FindFirstChild('Human') then EnemyTeam = 'Orc' end

	TargetsList = NPCs[EnemyTeam]:GetChildren()

    -- Adding the general to the end of the table so that it doesn't target the general early

	for i,v in pairs(TargetsList) do
		if v.Name:find('General')  then
			Index = i
			General = v
		end
	end

	TargetsList[Index] = nil
	table.insert(TargetsList, #TargetsList, General)

	return TargetsList
end

function Attack(target)
    if not target then return end
	local CurrentWeapon

	if target.Name:find('General') then CurrentWeapon = FOFConfig.BossWeapon else CurrentWeapon = FOFConfig.NPCWeapon end 
	if Teams:FindFirstChild('Neutral') and LocalPlayer.Team == Teams:FindFirstChild('Neutral') then return end
	repeat task.wait() until LocalPlayer.Backpack:FindFirstChild(CurrentWeapon) or LocalPlayer.Character:FindFirstChild(CurrentWeapon)
	if LocalPlayer.Backpack:FindFirstChild(CurrentWeapon) then LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild(CurrentWeapon)) end

	repeat
		if not target:FindFirstChild('Torso') or not FOFConfig.AutofarmEnabled then return end
		LocalPlayer.Character:FindFirstChild(CurrentWeapon):Activate()
		LocalPlayer.Character.HumanoidRootPart.CFrame = target.Torso.CFrame * CFrame.new(0,0,3)
		task.wait(0.125)
	until not target or not target:FindFirstChild('Humanoid') or target:FindFirstChild('Humanoid').Health == 0

	if string.find(target.Name, 'General') then
		Players:Chat(':mapvote savannah')
		SendWebhook()
	end
    
end

-- Script events

LocalPlayer.CharacterAdded:Connect(function()
    if FOFConfig.AutofarmEnabled then
    local Enemies = ObtainTargets()
        for index, npc in pairs(Enemies) do
            if not FOFConfig.AutofarmEnabled then return end
					Attack(npc)
                	Enemies[index] = nil
        end
    end
end)

Players.PlayerAdded:Connect(function()
	FOFConfig.AutofarmEnabled = false
	LocalPlayer.Character:BreakJoints()
end)

Players.PlayerRemoving:Connect(function()
	if #Players:GetPlayers() == 1 then
		FOFConfig.AutofarmEnabled = true
		LocalPlayer.Character:BreakJoints()
	end
end)
spawn(function()
	while task.wait(3) do
		if not FOFConfig.AutofarmEnabled then return end
	
		GoldGained = Stats.Gold.Value - HGold
		ExpGained = Stats.XP.Value - HXP
		TimeElapsed = TimeElapsed + 3
	
		HourlyGold = (GoldGained / TimeElapsed) * 3600
		HourlyExp = (ExpGained / TimeElapsed) * 3600
	end
end)

RunService:Set3dRenderingEnabled(not FOFConfig.DisableRendering)
LocalPlayer.Character:BreakJoints()
