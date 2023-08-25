-- Script Variables

local Players = game:GetService('Players')
local Teams = game:GetService('Teams')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local StarterGui = game:GetService('StarterGui')
local VirtualUser = game:GetService("VirtualUser")
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

function NotifyChat(message, colour, required)
	if required then
		return StarterGui:SetCore("ChatMakeSystemMessage", {Text = "[Field of Heaven] "..message, Color = colour, Font = Enum.Font.SourceSansBold, TextSize = 16})
	end

	if FOFConfig.DebugMode then
		return StarterGui:SetCore("ChatMakeSystemMessage", {Text = "[Field of Heaven] "..message, Color = colour, Font = Enum.Font.SourceSansBold, TextSize = 16})
	end
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
					["value"] = [[```- Added ['AttackNeutralNPCs'] toggle to the config, and also added a table called ['UseGeneralWeaponNPCs'] = {['mage'] = true}. For more information, join the discord at dsc.gg/amiriki```]],
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
	local NeutralTable = NPCs['Neutral']:GetChildren()
	local TablePos
	local TargetsList
    local EnemyTeam
    local Index
	local General

	if LocalPlayer.Team == Teams:FindFirstChild('Neutral') then return {} end
	if LocalPlayer.Team == Teams:FindFirstChild('Orc') then EnemyTeam = 'Human' end
	if LocalPlayer.Team == Teams:FindFirstChild('Human') then EnemyTeam = 'Orc' end

	TargetsList = NPCs[EnemyTeam]:GetChildren()

	if FOFConfig.AttackNeutralNPCs then
		TablePos = #TargetsList + 1
		for i, v in ipairs(NeutralTable) do
			TargetsList[TablePos] = v
			TablePos += 1
		end
	end

	for i, npc in ipairs(TargetsList) do
		if npc.Name:find('General')  then
			Index = i
			General = npc
		end

		if FOFConfig.IgnorePlayers then
			if Players:FindFirstChild(npc.Name) then
				TargetsList[i] = nil
			end
		end
	end

	if Index ~= nil then
		TargetsList[Index] = nil
	end

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
			NotifyChat('Looping attack, target name is '..target.Name, Color3.fromRGB(69, 69, 215))
			LocalPlayer.Character:FindFirstChild(weapon):Activate()
			LocalPlayer.Character.HumanoidRootPart.CFrame = target.Torso.CFrame * CFrame.new(0,0,3)
		end)
		task.wait()
	until not target or not target:FindFirstChild('Humanoid') or target:FindFirstChild('Humanoid').Health == 0 or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('Humanoid') or LocalPlayer.Character:FindFirstChild('Humanoid').Health == 0
	NotifyChat('Player or target died', Color3.fromRGB(69, 69, 215))
end

-- Script events
LocalPlayer.CharacterAdded:Connect(function()
	if FOFConfig.LagMode then task.wait(1.5) end
    if FOFConfig.AutofarmEnabled then
		local CurrentWeapon
        local Enemies = ObtainTargets()
        for index, npc in pairs(Enemies) do
			NotifyChat('Looping through enemies, enemy name is '..npc.Name, Color3.fromRGB(69, 69, 215))
            if not FOFConfig.AutofarmEnabled then return NotifyChat('Autofarm is disabled!', Color3.fromRGB(255, 0, 0)) end
			if not LocalPlayer.Character or not LocalPlayer.Character:WaitForChild('Humanoid', 3) or LocalPlayer.Character:FindFirstChild('Humanoid').Health == 0 then return NotifyChat('Character died, waiting for respawn...', Color3.fromRGB(69, 69, 215)) end
            if Teams:FindFirstChild('Neutral') and LocalPlayer.Team == Teams:FindFirstChild('Neutral') then return end

            if npc.Name:find('General') or (FOFConfig.UseGeneralWeaponNPCs and FOFConfig.UseGeneralWeaponNPCs[npc.Name:lower():split(" ")[2]]) then CurrentWeapon = FOFConfig.BossWeapon else CurrentWeapon = FOFConfig.NPCWeapon end 
	        repeat task.wait() until LocalPlayer.Backpack:FindFirstChild(CurrentWeapon) or LocalPlayer.Character:FindFirstChild(CurrentWeapon)
			Attack(npc, CurrentWeapon)
            Enemies[index] = nil
        end
		NotifyChat('End of table has been reached!', Color3.fromRGB(175, 0, 0))
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

LocalPlayer.Idled:connect(function()
	VirtualUser:ClickButton2(Vector2.new())
end)

LocalPlayer.Character:BreakJoints()

NotifyChat("Autofarm has successfully been executed.", Color3.fromRGB(69, 215, 69), true)
NotifyChat("Report any bugs to Amiriki on Discord", Color3.fromRGB(69, 69, 215), true)
NotifyChat("Join the Discord at dsc.gg/amiriki", Color3.fromRGB(69, 69, 215), true)
