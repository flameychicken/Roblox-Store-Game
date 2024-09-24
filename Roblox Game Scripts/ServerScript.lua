local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local CustomerFolder = ServerStorage:FindFirstChild("Customers")
local ShelfFolder = Workspace:FindFirstChild("shelves")
local Register = Workspace:FindFirstChild("Register")
local restocker = Workspace:FindFirstChild("RestockBlock")
local StockFolder = ServerStorage:FindFirstChild("Stock")

if not CustomerFolder then
	CustomerFolder = Instance.new("Folder")
	CustomerFolder.Name = "Customers"
	CustomerFolder.Parent = ServerStorage
end

local customerModels = {
	CustomerFolder:WaitForChild("Customer1"),
	CustomerFolder:WaitForChild("Customer2")
}

local spawnPoints = {
	Vector3.new(-7, 0.5, -96)
}

local shelves = {
	ShelfFolder:WaitForChild("Shelf1"),
	ShelfFolder:WaitForChild("Shelf2"),
	ShelfFolder:WaitForChild("Shelf3")
}

local totalMoneyEarned = 0
local activeCustomer = nil

local function evaluateExpression(expression)
	local t = {}
	local sep = "%*"

	-- Split the expression based on the "*" separator
	for str in string.gmatch(expression, "([^"..sep.."]+)") do
		table.insert(t, str)
	end

	if #t == 2 then
		-- Convert the split strings to integers and multiply them
		local num1 = tonumber(t[1])
		local num2 = tonumber(t[2])

		if num1 and num2 then
			return num1 * num2
		end
	end

	return nil, "Invalid expression"
end


local function spawnCustomer()
	if activeCustomer then
		return -- Prevent spawning a new customer if one is already active
	end

	local customerModel = customerModels[math.random(1, #customerModels)]:Clone()
	local spawnPoint = spawnPoints[math.random(1, #spawnPoints)]
	local shelf = shelves[math.random(1, #shelves)]
	local stock = shelf:FindFirstChild("Stock")
	local itemCount = stock:FindFirstChild("ItemCount")
	local balance = customerModel:FindFirstChild("Balance")

	local itemPositions = {
		stock:WaitForChild("ItemPosition1"),
		stock:WaitForChild("ItemPosition2"),
		stock:WaitForChild("ItemPosition3"),
		stock:WaitForChild("ItemPosition4"),
		stock:WaitForChild("ItemPosition5"),
		stock:WaitForChild("ItemPosition6"),
		stock:WaitForChild("ItemPosition7"),
		stock:WaitForChild("ItemPosition8"),
		stock:WaitForChild("ItemPosition9"),
		stock:WaitForChild("ItemPosition10"),
		stock:WaitForChild("ItemPosition11"),
		stock:WaitForChild("ItemPosition12")
	}

	local registerBlock = Register:FindFirstChild("RegisterBlock")
	customerModel.Parent = Workspace
	customerModel:SetPrimaryPartCFrame(CFrame.new(spawnPoint))

	print("Customer spawned at: ", spawnPoint)

	local humanoid = customerModel:FindFirstChildOfClass("Humanoid")
	local pathFolder = shelf:FindFirstChild("path")

	if pathFolder and humanoid then
		for _, waypoint in ipairs(pathFolder:GetChildren()) do
			humanoid:MoveTo(waypoint.Position)
			humanoid.MoveToFinished:Wait()
		end
	else
		warn("Path folder or humanoid not found!")
	end
	wait(3)
	activeCustomer = customerModel

	local itemsBought = math.random(1, 4)
	local itemsPurchased = 0
	local totalCost = 0

	-- Check if the shelf has enough items
	if itemCount.Value < itemsBought then
		print("Not enough items on the shelf. Customer is leaving.")
		activeCustomer:Destroy()
		activeCustomer = nil
		return
	end

	for i = 1, itemsBought do
		local itemPosition = itemPositions[math.random(1, #itemPositions)]
		local item = itemPosition:FindFirstChild("Item")
		while not item do
			itemPosition = itemPositions[math.random(1, #itemPositions)]
			item = itemPosition:FindFirstChild("Item")
		end
		local cost = item and item:FindFirstChild("Price")

		if itemCount and itemCount.Value > 0 and balance and cost then
			itemCount.Value = itemCount.Value - 1
			totalCost = totalCost + cost.Value
			item:Destroy()
			itemsPurchased = itemsPurchased + 1
		end

		if itemsPurchased >= itemsBought then
			break
		end
	end

	balance.Value = balance.Value + totalCost
	print("Customer bought " .. itemsPurchased .. " items for $" .. totalCost)
	if itemsPurchased > 0 then
		humanoid:MoveTo(registerBlock.Position)
		humanoid.MoveToFinished:Wait()

		-- Add a ProximityPrompt to the registerBlock if it doesn't exist
		local prompt = registerBlock:FindFirstChild("ProximityPrompt")
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Checkout"
			prompt.ObjectText = "Register"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.RequiresLineOfSight = false -- Setting the RequiresLineOfSight property
			prompt.Parent = registerBlock
			print("Prompt created")
		end

		-- Function to handle when the prompt is triggered
		local function onPromptTriggered(player)
			-- Remove the ProximityPrompt
			prompt:Destroy()

			-- Display the temporary UI
			local playerGui = player:WaitForChild("PlayerGui")
			if playerGui then
				local checkoutGui = playerGui:FindFirstChild("CheckoutGui")
				if checkoutGui then
					checkoutGui.Enabled = true
					local frame = checkoutGui:FindFirstChild("Frame")
					if frame then
						frame.PriceLabel.Text = "Price per Item: $" .. math.floor(totalCost / itemsPurchased)
						frame.QuantityLabel.Text = "Items Bought: " .. itemsPurchased
						frame.TotalLabel.Text = "Total: 0"

						local currentInput = ""

						-- Function to handle calculator button clicks
						local function onButtonClicked(button)
							local buttonValue = button.Name
							if buttonValue == "times" then
								buttonValue = "*"
							elseif buttonValue == "equals" then
								if currentInput == "" then
									currentInput = "0"
								end
								local result = evaluateExpression(currentInput)
								if result then
									currentInput = tostring(result)
									frame.TotalLabel.Text = "Total: " .. currentInput
								else
									currentInput = ""
									frame.TotalLabel.Text = "Error"
								end
								return
							end
							currentInput = currentInput .. buttonValue
							frame.TotalLabel.Text = "Total: " .. currentInput
						end

						-- Connect calculator buttons
						local calculatorFolder = frame:FindFirstChild("Calculator")
						if calculatorFolder then
							for _, button in ipairs(calculatorFolder:GetChildren()) do
								if button:IsA("TextButton") then
									button.MouseButton1Click:Connect(function()
										onButtonClicked(button)
									end)
								end
							end
						end

						local function closeCheckoutGui()
							if playerGui then
								local checkoutGui = playerGui:FindFirstChild("CheckoutGui")
								if checkoutGui then
									frame.TotalLabel.Text = "0"
									checkoutGui.Enabled = false
								end
							end
						end

						local function checkAnswer()
							local inputAmount = tonumber(currentInput)
							if inputAmount == totalCost then
								-- Correct answer, finalize checkout
								closeCheckoutGui()
								-- Kill the customer
								activeCustomer:Destroy()
								activeCustomer = nil
								print("Customer killed.")

								-- Update money earned
								totalMoneyEarned = totalMoneyEarned + balance.Value

								-- Update the UI for the player
								local screenGui = playerGui:FindFirstChild("Cash")
								if screenGui then
									local textLabel = screenGui:FindFirstChild("TextLabel")
									if textLabel then
										local updatedAmount = screenGui:FindFirstChild("CashAmount")
										updatedAmount.Value = totalMoneyEarned + updatedAmount.Value
										totalMoneyEarned = 0
										print("The current amount of the player is", updatedAmount)
										textLabel.Text = "" .. updatedAmount.Value
									end
								end
							else
								-- Incorrect answer, prompt the player to try again
								currentInput = ""
								frame.TotalLabel.Text = "Total: 0"
								frame.TotalLabel.PlaceholderText = "Incorrect, try again"
							end
						end

						-- Reset UI fields for each new customer
						currentInput = ""
						frame.TotalLabel.Text = "Total: 0"

						-- Connect the submit button to the checkAnswer function
						local submitButton = frame:FindFirstChild("SubmitButton")
						if submitButton then
							submitButton.MouseButton1Click:Connect(checkAnswer)
						end

						-- Connect the close button to the closeCheckoutGui function
						local closeButton = frame:FindFirstChild("CloseButton")
						if closeButton then
							closeButton.MouseButton1Click:Connect(closeCheckoutGui)
						end
					end
				end
			end
		end

		-- Connect the prompt triggered event to the handler
		prompt.Triggered:Connect(onPromptTriggered)
	elseif itemCount and itemCount.Value == 0 then
		activeCustomer:Destroy()
		activeCustomer = nil
		print("Customer killed because there is no stock.")
	end
end

-- Coroutine to handle customer spawning
coroutine.wrap(function()
	while true do
		spawnCustomer()
		wait(10)
	end
end)()
