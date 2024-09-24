local Players = game:GetService("Players")
local shelfBlock = script.Parent:FindFirstChild("MiddleShelf")
local shelf = script.Parent
local ServerStorage = game:GetService("ServerStorage")

-- Create the ProximityPrompt if it doesn't already exist
local prompt = shelfBlock:FindFirstChild("ProximityPrompt")
if not prompt then
	prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Restock"
	prompt.ObjectText = "Shelf"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.Parent = shelfBlock
	print("Prompt created")
end

-- Function to handle restocker prompt triggered
local function onRestockPromptTriggered(player)
	local character = player.Character
	if character then
		local equippedTool = character and character:FindFirstChildOfClass("Tool")
		if equippedTool and equippedTool.Name == "Box" then
			local boxModel = equippedTool:FindFirstChild("BoxModel")
			if boxModel then
				local boxStock = boxModel:FindFirstChild("Stock")
				if boxStock then
					local itemsInBox = {}
					for _, child in ipairs(boxStock:GetChildren()) do
						if child:IsA("BasePart") then
							table.insert(itemsInBox, child)
						end
					end
					local playerItemAmount = #itemsInBox
					if playerItemAmount > 0 then
						local shelfStock = shelf:FindFirstChild("Stock")
						if shelfStock then
							local itemAmount = shelfStock:FindFirstChild("ItemCount")
							if itemAmount and itemAmount.Value < 16 then
								-- Insert items into the shelf at available positions
								for _, item in ipairs(itemsInBox) do
									local placed = false
									for _, pos in ipairs(shelfStock:GetChildren()) do
										if pos:IsA("BasePart") and not pos:FindFirstChild("Item") then
											local newItem = item:Clone()
											newItem.Anchored = true
											newItem.CFrame = pos.CFrame
											newItem.Name = "Item"
											newItem.Parent = pos
											itemAmount.Value = itemAmount.Value + 1
											item:Destroy() -- Remove item from box stock
											playerItemAmount = playerItemAmount - 1
											placed = true
											print("Item added to shelf")
											break
										end
									end
									if not placed then
										print("No free positions available on the shelf")
										break
									end
									if playerItemAmount == 0 or itemAmount.Value >= 16 then
										break
									end
								end
							else
								print("Shelf is already full")
							end
						else
							print("No stock folder found in shelf")
						end
					else
						print("Player has no items in the box")
						equippedTool:Destroy() -- Remove the empty box tool
					end
				else
					print("No stock folder found in box")
				end
			else
				print("No BoxModel found in box tool")
			end
		else
			print("Player does not have the correct tool equipped")
		end
	else
		print("Player character not found")
	end
end

-- Connect the restocker prompt triggered event to the handler
prompt.Triggered:Connect(onRestockPromptTriggered)
