-- Script variables

local Players = game:GetService('Players')
local Teams = game:GetService('Teams')
local HttpService = game:GetService('HttpService')

local LocalPlayer = Players.LocalPlayer
local Stats = LocalPlayer.leaderstats
local Gold = Stats.Gold.Value
local XP = Stats.XP.Value
local Time = os.time()

local NPCs = workspace['Unbreakable']['Characters']
local EnemyTeam

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
	local Thumbnail = game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-bust?userIds="..LocalPlayer.UserId.."&size=420x420&format=Png&isCircular=true")
	local data = {
		["username"] = LocalPlayer.DisplayName,
		["avatar_url"] = HttpService:JSONDecode(Thumbnail).data[1].imageUrl,

		["embeds"] = {{
			["title"] = "Field of Farming",
			["description"] = "Round over!",
			["type"] = "rich",
			["color"] = tonumber(0x0096FF),
			["fields"] = {
				{
					["name"] = ":moneybag: Gold",
					["value"] = tostring(Format_Number(Stats.Gold.Value))..' (+'..(Format_Number(Stats.Gold.Value - Gold))..')',
					["inline"] = false
				},
				{
					["name"] = ":man_in_tuxedo: Experience",
					["value"] = tostring(Format_Number(Stats.XP.Value))..' (+'..(Format_Number(Stats.XP.Value - XP))..')',
					["inline"] = false
				},
				{
					["name"] = ":test_tube: Level",
					["value"] = tostring(Stats.Level.Value)..' ('..Format_Number(string.split(Split_Label, ' / ')[1])..' / '..Format_Number(string.split(Split_Label, ' / ')[2])..')',
					["inline"] = false
				},
			},

			["footer"] = {
				["icon_url"] = "https://i.vgy.me/loT5uM.png",
				["text"] = 'Time Taken: '..(os.time() - Time)..' seconds | discord.gg/hMG9ESHT'
			}
		}}
	}
request({Url = WebhookURL, Method = 'POST', Headers = {['Content-Type'] = 'application/json'}, Body = HttpService:JSONEncode(data)})

	XP = Stats.XP.Value
	Gold = Stats.Gold.Value
	Time = os.time()
	--print('[Field of Farming Debugger]: Notification has been sent to webhook!')
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

	if target.Name:find('General') then CurrentWeapon = BossWeapon else CurrentWeapon = NPCWeapon end 
	if Teams:FindFirstChild('Neutral') and LocalPlayer.Team == Teams:FindFirstChild('Neutral') then return end
	repeat wait() until LocalPlayer.Backpack:FindFirstChild(CurrentWeapon) or LocalPlayer.Character:FindFirstChild(CurrentWeapon)
	if LocalPlayer.Backpack:FindFirstChild(CurrentWeapon) then LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild(CurrentWeapon)) end

	repeat
		if not target:FindFirstChild('Torso') then return end
		LocalPlayer.Character:FindFirstChild(CurrentWeapon):Activate()
		LocalPlayer.Character.HumanoidRootPart.CFrame = target.Torso.CFrame * CFrame.new(0,0,3)
		wait(0.125)
	until not target or not target:FindFirstChild('Humanoid') or target:FindFirstChild('Humanoid').Health == 0

	if string.find(target.Name, 'General') then
		Players:Chat(':mapvote savannah')
		SendWebhook()
	end
    
end

-- Script events

LocalPlayer.CharacterAdded:Connect(function()
    if AutofarmEnabled then
    local Enemies = ObtainTargets()
        for index, npc in pairs(Enemies) do
            if not AutofarmEnabled then return end
					Attack(npc)
                	Enemies[index] = nil
        end
    --print('[Field of Farming Debugger]: No enemies found, reseting!')
    --LocalPlayer.Character:BreakJoints()
    end
end)

if AutofarmEnabled then LocalPlayer.Character:BreakJoints() end

