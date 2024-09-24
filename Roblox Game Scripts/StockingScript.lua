local Players = game:GetService("Players")
local restocker = script.Parent
local ServerStorage = game:GetService("ServerStorage")

-- Create the ProximityPrompt if it doesn't already exist
local prompt = restocker:FindFirstChild("ProximityPrompt")
if not prompt then
	prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy"
	prompt.ObjectText = "Stock"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.Parent = restocker
	print("Prompt created")
end

-- Function to weld parts together
local function weldParts(part1, part2)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part1
	weld.Part1 = part2
	weld.Parent = part1
end

-- Function to handle restocker prompt triggered
local function onRestockPromptTriggered(player)
	-- Check the player's balance
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui = playerGui:FindFirstChild("Cash")
	if screenGui then
		local playerAmount = screenGui:FindFirstChild("CashAmount")
		local textLabel = screenGui:FindFirstChild("TextLabel")
		if playerAmount and playerAmount.Value >= 3 then
			-- Temporarily disable the ProximityPrompt
			prompt.Enabled = false
			playerAmount.Value = playerAmount.Value - 3
			textLabel.Text = "" .. playerAmount.Value

			-- Give the player the box as a tool
			local boxTemplate = ServerStorage:FindFirstChild("Box")
			if boxTemplate then
				local clonedTool = boxTemplate:Clone()
				local playerCharacter = player.Character or player.CharacterAdded:Wait()

				-- Ensure the cloned tool has a valid handle inside the model
				local boxModel = clonedTool:FindFirstChild("BoxModel")
				if boxModel then
					local handle = boxModel:FindFirstChild("Handle")
					if handle then
						handle.Name = "Handle" -- Ensure the part is named "Handle"
						handle.Parent = clonedTool -- Move handle to the tool

						-- Find the Stock container within the box model
						local stockContainer = boxModel:FindFirstChild("Stock")
						local stockUpdate = boxModel:FindFirstChild("Stock"):FindFirstChild("ItemAmount")
						if stockContainer then
							-- Position the items inside the stock container
							local bottom = boxModel:FindFirstChild("Bottom")
							if bottom then
								for i = 1, 5 do  -- Adjust the number of items as needed
									local itemClone = ServerStorage:FindFirstChild("Stock"):FindFirstChild("Item"):Clone()
									itemClone.Parent = stockContainer
									itemClone.Anchored = false
									itemClone.CFrame = bottom.CFrame * CFrame.new(0, 0.5 * i, 0) -- Adjust position as needed

									-- Weld the item to the handle to keep it in place
									weldParts(handle, itemClone)
									stockUpdate.Value = stockUpdate.Value + 1
								end
							else
								warn("Bottom part not found in BoxModel")
							end
						else
							warn("Stock container not found in BoxModel")
						end

						clonedTool.Parent = player.Backpack
						print("Box given to player:", player.Name)
					else
						warn("Handle not found in BoxModel")
					end
				else
					warn("BoxModel not found in cloned tool")
				end
			else
				warn("Box not found in ServerStorage")
			end

			-- Re-enable the ProximityPrompt after a short delay
			wait(1)
			prompt.Enabled = true
		else
			warn("Player does not have enough money to restock")
		end
	else
		warn("Cash GUI not found")
	end
end

-- Connect the restocker prompt triggered event to the handler
prompt.Triggered:Connect(onRestockPromptTriggered)
