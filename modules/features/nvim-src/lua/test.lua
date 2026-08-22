-- Print a simple greeting
print("Hello! What is your name?")

-- Read user input from the console
local name = io.read()

-- Concatenate strings using ..
print("Nice to meet you, " .. name .. "!")

-- Define a simple function to add two numbers
local function addNumbers(a, b)
	return a + b
end

local sum = addNumbers(10, 15)
print("10 + 15 = " .. sum)

-- Run a short numeric loop
print("Counting to 3:")
for i = 1, 3 do
	print("Count: " .. i)
end
