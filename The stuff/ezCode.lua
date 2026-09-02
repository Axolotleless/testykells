local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FONT = Enum.Font.Code
local FONT_SIZE = 16
local LINE_HEIGHT = 18
local TAB_WIDTH = 4
local GUTTER_WIDTH = 40

local COLOR_BG = Color3.fromRGB(90, 90, 90)
local COLOR_GUTTER = Color3.fromRGB(75, 75, 75)
local COLOR_GUTTER_TEXT = Color3.fromRGB(160, 160, 160)
local COLOR_TEXT = Color3.fromRGB(230, 230, 230)
local COLOR_KEYWORD = Color3.fromRGB(220, 170, 255)
local COLOR_BUILTIN = Color3.fromRGB(150, 210, 255)
local COLOR_STRING = Color3.fromRGB(180, 230, 150)
local COLOR_COMMENT = Color3.fromRGB(150, 150, 150)
local COLOR_NUMBER = Color3.fromRGB(240, 190, 130)
local COLOR_OPERATOR = Color3.fromRGB(240, 140, 140)
local COLOR_FUNCNAME = Color3.fromRGB(150, 210, 255)
local COLOR_ERROR = Color3.fromRGB(255, 90, 90)
local COLOR_STATUS = Color3.fromRGB(70, 70, 70)
local COLOR_AUTO = Color3.fromRGB(80, 80, 80)
local COLOR_AUTO_SEL = Color3.fromRGB(110, 110, 150)
local COLOR_TITLE = Color3.fromRGB(65, 65, 65)
local COLOR_CURLINE = Color3.fromRGB(100, 100, 100)

local DQ = string.char(34)
local BS = string.char(92)

local KEYWORDS = {}
do
	local list = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "export", "type"}
	for index = 1, #list do
		KEYWORDS[list[index]] = true
	end
end

local BUILTINS = {}
do
	local list = {"game", "workspace", "script", "print", "warn", "error", "pairs", "ipairs", "next", "type", "typeof", "tostring", "tonumber", "pcall", "xpcall", "select", "rawget", "rawset", "rawequal", "setmetatable", "getmetatable", "unpack", "table", "string", "math", "os", "coroutine", "task", "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim2", "UDim", "Enum", "wait", "spawn", "delay", "tick", "Ray", "Region3", "BrickColor", "Random"}
	for index = 1, #list do
		BUILTINS[list[index]] = true
	end
end

local BLOCKED_TERMS = {}
do
	local function decode(codes)
		local chars = {}
		for index = 1, #codes do
			chars[index] = string.char(codes[index])
		end
		return table.concat(chars)
	end

	local codeList = {
		{114, 101, 113, 117, 105, 114, 101},
		{104, 116, 116, 112, 115, 101, 114, 118, 105, 99, 101},
		{103, 101, 116, 102, 101, 110, 118},
		{115, 101, 116, 102, 101, 110, 118},
		{108, 111, 97, 100, 115, 116, 114, 105, 110, 103},
		{100, 101, 98, 117, 103},
		{97, 115, 115, 101, 116, 115, 101, 114, 118, 105, 99, 101},
		{100, 97, 116, 97, 115, 116, 111, 114, 101, 115, 101, 114, 118, 105, 99, 101},
		{109, 101, 115, 115, 97, 103, 105, 110, 103, 115, 101, 114, 118, 105, 99, 101},
		{116, 101, 108, 101, 112, 111, 114, 116, 115, 101, 114, 118, 105, 99, 101},
		{109, 97, 114, 107, 101, 116, 112, 108, 97, 99, 101, 115, 101, 114, 118, 105, 99, 101},
		{105, 110, 115, 101, 114, 116, 115, 101, 114, 118, 105, 99, 101},
		{99, 111, 110, 116, 101, 110, 116, 112, 114, 111, 118, 105, 100, 101, 114},
		{115, 99, 114, 105, 112, 116, 99, 111, 110, 116, 101, 120, 116},
		{108, 111, 103, 105, 110, 115, 101, 114, 118, 105, 99, 101},
		{103, 97, 109, 101, 112, 97, 115, 115, 115, 101, 114, 118, 105, 99, 101},
		{98, 97, 100, 103, 101, 115, 101, 114, 118, 105, 99, 101},
		{115, 111, 99, 105, 97, 108, 115, 101, 114, 118, 105, 99, 101},
		{116, 101, 120, 116, 115, 101, 114, 118, 105, 99, 101},
		{112, 101, 114, 109, 105, 115, 115, 105, 111, 110, 115, 115, 101, 114, 118, 105, 99, 101},
		{112, 111, 108, 105, 99, 121, 115, 101, 114, 118, 105, 99, 101},
		{97, 110, 97, 108, 121, 116, 105, 99, 115, 115, 101, 114, 118, 105, 99, 101},
		{104, 101, 97, 114, 116, 98, 101, 97, 116, 115, 101, 114, 118, 105, 99, 101},
		{99, 111, 108, 108, 101, 99, 116, 105, 111, 110, 115, 101, 114, 118, 105, 99, 101},
		{104, 116, 116, 112, 114, 101, 113, 117, 101, 115, 116},
		{103, 101, 116, 114, 97, 119, 109, 101, 116, 97, 116, 97, 98, 108, 101},
		{115, 101, 116, 114, 97, 119, 109, 101, 116, 97, 116, 97, 98, 108, 101},
		{110, 101, 119, 99, 115, 116, 97, 116, 101},
		{103, 101, 116, 103, 99},
		{103, 101, 116, 103, 101, 110, 118},
		{103, 101, 116, 114, 101, 110, 118},
		{103, 101, 116, 105, 110, 115, 116, 97, 110, 99, 101, 115},
		{115, 101, 116, 114, 101, 97, 100, 111, 110, 108, 121},
		{103, 101, 116, 104, 105, 100, 100, 101, 110, 112, 114, 111, 112, 101, 114, 116, 121},
		{115, 101, 116, 104, 105, 100, 100, 101, 110, 112, 114, 111, 112, 101, 114, 116, 121},
		{102, 105, 114, 101, 99, 108, 105, 99, 107, 100, 101, 116, 101, 99, 116, 111, 114},
		{102, 105, 114, 101, 116, 111, 117, 99, 104, 105, 110, 116, 101, 114, 101, 115, 116},
		{103, 101, 116, 99, 111, 110, 110, 101, 99, 116, 105, 111, 110, 115},
		{103, 101, 116, 99, 97, 108, 108, 105, 110, 103, 115, 99, 114, 105, 112, 116},
		{99, 104, 101, 99, 107, 99, 97, 108, 108, 101, 114},
		{105, 115, 108, 99, 108, 111, 115, 117, 114, 101},
		{105, 115, 99, 99, 108, 111, 115, 117, 114, 101},
		{104, 111, 111, 107, 102, 117, 110, 99, 116, 105, 111, 110},
		{104, 111, 111, 107, 109, 101, 116, 97, 109, 101, 116, 104, 111, 100},
		{108, 111, 97, 100, 102, 105, 108, 101},
		{100, 111, 102, 105, 108, 101},
		{99, 111, 108, 108, 101, 99, 116, 103, 97, 114, 98, 97, 103, 101},
		{103, 99, 105, 110, 102, 111},
	}

	for index = 1, #codeList do
		BLOCKED_TERMS[index] = decode(codeList[index])
	end
end

local INTELLISENSE = {}

INTELLISENSE.game = {
	{label = "GetService(name)", detail = "Returns the given service, creating it if needed."},
	{label = "Workspace", detail = "The game's Workspace, a child of the DataModel."},
	{label = "Players", detail = "Service managing connected Players."},
}

INTELLISENSE.table = {
	{label = "insert(t, v)", detail = "Inserts v at the end of t."},
	{label = "remove(t, i)", detail = "Removes and returns the element at index i."},
	{label = "concat(t, sep)", detail = "Concatenates array elements into a string."},
	{label = "sort(t, fn)", detail = "Sorts t in place, optional comparator fn."},
	{label = "find(t, v)", detail = "Returns the index of v in t, or nil."},
	{label = "clone(t)", detail = "Returns a shallow copy of t."},
	{label = "clear(t)", detail = "Removes all entries from t."},
	{label = "getn(t)", detail = "Returns the number of elements in the array part."},
	{label = "unpack(t)", detail = "Returns elements of t as multiple values."},
}

INTELLISENSE.string = {
	{label = "format(fmt, ...)", detail = "Formats a string using printf-style patterns."},
	{label = "sub(s, i, j)", detail = "Returns substring from index i to j."},
	{label = "find(s, pattern)", detail = "Finds a pattern match, returns start and end."},
	{label = "gsub(s, pattern, rep)", detail = "Replaces pattern matches in s."},
	{label = "match(s, pattern)", detail = "Returns the first match of pattern."},
	{label = "gmatch(s, pattern)", detail = "Returns an iterator over pattern matches."},
	{label = "len(s)", detail = "Returns the length of s."},
	{label = "upper(s)", detail = "Returns s in upper case."},
	{label = "lower(s)", detail = "Returns s in lower case."},
	{label = "rep(s, n)", detail = "Repeats s n times."},
	{label = "split(s, sep)", detail = "Splits s into a table by separator."},
	{label = "byte(s, i)", detail = "Returns the numeric byte at index i."},
	{label = "char(...)", detail = "Returns a string from byte values."},
}

INTELLISENSE.math = {
	{label = "floor(x)", detail = "Rounds x down to the nearest integer."},
	{label = "ceil(x)", detail = "Rounds x up to the nearest integer."},
	{label = "abs(x)", detail = "Returns the absolute value of x."},
	{label = "random(m, n)", detail = "Returns a pseudo-random integer or float."},
	{label = "randomseed(x)", detail = "Seeds the pseudo-random generator."},
	{label = "max(...)", detail = "Returns the maximum of its arguments."},
	{label = "min(...)", detail = "Returns the minimum of its arguments."},
	{label = "huge", detail = "A value larger than any representable number."},
	{label = "pi", detail = "The constant pi."},
	{label = "clamp(x, min, max)", detail = "Clamps x between min and max."},
	{label = "sqrt(x)", detail = "Returns the square root of x."},
	{label = "sign(x)", detail = "Returns -1, 0 or 1 depending on the sign of x."},
	{label = "noise(x, y, z)", detail = "Returns Perlin noise for the given coordinates."},
}

INTELLISENSE.task = {
	{label = "wait(seconds)", detail = "Yields the thread for the given duration."},
	{label = "spawn(fn)", detail = "Runs fn on a new thread, resuming immediately."},
	{label = "defer(fn)", detail = "Schedules fn to run after the current resumption cycle."},
	{label = "delay(seconds, fn)", detail = "Runs fn after the given delay."},
	{label = "cancel(thread)", detail = "Cancels a running thread."},
}

INTELLISENSE.os = {
	{label = "time()", detail = "Returns the current Unix timestamp."},
	{label = "clock()", detail = "Returns a high resolution running time value."},
	{label = "date(fmt)", detail = "Returns a formatted date string."},
}

INTELLISENSE.coroutine = {
	{label = "create(fn)", detail = "Creates a new coroutine from fn."},
	{label = "resume(co, ...)", detail = "Resumes a suspended coroutine."},
	{label = "yield(...)", detail = "Suspends the running coroutine."},
	{label = "status(co)", detail = "Returns the status of a coroutine."},
	{label = "wrap(fn)", detail = "Wraps fn as a callable coroutine."},
}

INTELLISENSE.Instance = {
	{label = "new(className, parent)", detail = "Creates a new Instance of the given class."},
}

INTELLISENSE.Vector3 = {
	{label = "new(x, y, z)", detail = "Creates a new Vector3."},
	{label = "zero", detail = "A Vector3 with all components zero."},
	{label = "one", detail = "A Vector3 with all components one."},
	{label = "Magnitude", detail = "The length of the vector."},
	{label = "Unit", detail = "The vector normalized to length 1."},
	{label = "Dot(other)", detail = "Returns the dot product with another Vector3."},
	{label = "Cross(other)", detail = "Returns the cross product with another Vector3."},
}

INTELLISENSE.Vector2 = {
	{label = "new(x, y)", detail = "Creates a new Vector2."},
	{label = "zero", detail = "A Vector2 with all components zero."},
	{label = "one", detail = "A Vector2 with all components one."},
	{label = "Magnitude", detail = "The length of the vector."},
	{label = "Unit", detail = "The vector normalized to length 1."},
}

INTELLISENSE.CFrame = {
	{label = "new(x, y, z)", detail = "Creates a new CFrame at the given position."},
	{label = "Angles(rx, ry, rz)", detail = "Creates a rotation CFrame from angles in radians."},
	{label = "lookAt(from, to)", detail = "Creates a CFrame positioned at from, facing to."},
	{label = "identity", detail = "A CFrame with no offset or rotation."},
	{label = "Position", detail = "The position component of the CFrame."},
	{label = "LookVector", detail = "The forward direction of the CFrame."},
}

INTELLISENSE.Color3 = {
	{label = "fromRGB(r, g, b)", detail = "Creates a Color3 from 0-255 RGB values."},
	{label = "fromHSV(h, s, v)", detail = "Creates a Color3 from hue, saturation, value."},
	{label = "new(r, g, b)", detail = "Creates a Color3 from 0-1 RGB values."},
	{label = "fromHex(hex)", detail = "Creates a Color3 from a hex string."},
}

INTELLISENSE.UDim2 = {
	{label = "new(xScale, xOffset, yScale, yOffset)", detail = "Creates a new UDim2."},
	{label = "fromScale(x, y)", detail = "Creates a UDim2 using only scale values."},
	{label = "fromOffset(x, y)", detail = "Creates a UDim2 using only pixel offsets."},
}

INTELLISENSE.Enum = {
	{label = "KeyCode", detail = "Enum of keyboard key codes."},
	{label = "UserInputType", detail = "Enum of input device types."},
	{label = "Font", detail = "Enum of available fonts."},
	{label = "EasingStyle", detail = "Enum of tween easing styles."},
	{label = "EasingDirection", detail = "Enum of tween easing directions."},
}

INTELLISENSE.instance = {
	{label = "WaitForChild(name)", detail = "Yields until a child with the given name exists."},
	{label = "FindFirstChild(name)", detail = "Returns the first child with the given name, or nil."},
	{label = "FindFirstChildOfClass(className)", detail = "Returns the first child of the given class."},
	{label = "GetChildren()", detail = "Returns an array of the Instance's children."},
	{label = "GetDescendants()", detail = "Returns an array of all descendants."},
	{label = "Destroy()", detail = "Destroys the Instance and its descendants."},
	{label = "Clone()", detail = "Returns a copy of the Instance."},
	{label = "IsA(className)", detail = "Returns whether the Instance is of the given class."},
	{label = "IsDescendantOf(ancestor)", detail = "Returns whether this is nested under ancestor."},
	{label = "GetAttribute(name)", detail = "Returns the value of the given attribute."},
	{label = "SetAttribute(name, value)", detail = "Sets an attribute on the Instance."},
	{label = "Connect(fn)", detail = "Connects fn to a signal event."},
	{label = "Once(fn)", detail = "Connects fn to run only once."},
	{label = "Wait()", detail = "Yields until the signal fires, returns its arguments."},
	{label = "Name", detail = "The Instance's name."},
	{label = "Parent", detail = "The Instance's parent."},
}

local GLOBAL_SNIPPETS = {
	{label = "function() end", detail = "Anonymous function block."},
	{label = "local function", detail = "Declares a local function."},
	{label = "for i = 1, n do", detail = "Numeric for loop."},
	{label = "for _, v in ipairs() do", detail = "Iterates an array in order."},
	{label = "for k, v in pairs() do", detail = "Iterates all keys in a table."},
	{label = "if then end", detail = "Conditional block."},
	{label = "while do end", detail = "While loop block."},
	{label = "repeat until", detail = "Repeat-until loop block."},
	{label = "pcall(function()", detail = "Calls a function, catching errors safely."},
}

local function tokenColor(tokType)
	if tokType == "keyword" then
		return COLOR_KEYWORD
	elseif tokType == "builtin" then
		return COLOR_BUILTIN
	elseif tokType == "string" then
		return COLOR_STRING
	elseif tokType == "string_err" then
		return COLOR_ERROR
	elseif tokType == "comment" then
		return COLOR_COMMENT
	elseif tokType == "number" then
		return COLOR_NUMBER
	elseif tokType == "op" then
		return COLOR_OPERATOR
	elseif tokType == "funcname" then
		return COLOR_FUNCNAME
	end
	return COLOR_TEXT
end

local function tokenizeLine(line, inLongComment)
	local tokens = {}
	local i = 1
	local n = #line

	if inLongComment then
		local closeStart, closeEnd = string.find(line, "%]%]", i)
		if closeStart then
			tokens[#tokens + 1] = {t = "comment", s = line:sub(1, closeEnd)}
			i = closeEnd + 1
		else
			tokens[#tokens + 1] = {t = "comment", s = line}
			return tokens, true
		end
	end

	while i <= n do
		local c = line:sub(i, i)

		if c == " " or c == "\t" then
			local startI = i
			while i <= n and (line:sub(i, i) == " " or line:sub(i, i) == "\t") do
				i = i + 1
			end
			tokens[#tokens + 1] = {t = "ws", s = line:sub(startI, i - 1)}
		elseif line:sub(i, i + 1) == "--" then
			if line:sub(i + 2, i + 2) == "[" then
				local eqs = 0
				local j = i + 3
				while line:sub(j, j) == "=" do
					eqs = eqs + 1
					j = j + 1
				end
				if line:sub(j, j) == "[" then
					local closePattern = "%]" .. string.rep("=", eqs) .. "%]"
					local closeStart, closeEnd = string.find(line, closePattern, j + 1)
					if closeStart then
						tokens[#tokens + 1] = {t = "comment", s = line:sub(i, closeEnd)}
						i = closeEnd + 1
					else
						tokens[#tokens + 1] = {t = "comment", s = line:sub(i)}
						return tokens, true
					end
				else
					tokens[#tokens + 1] = {t = "comment", s = line:sub(i)}
					i = n + 1
				end
			else
				tokens[#tokens + 1] = {t = "comment", s = line:sub(i)}
				i = n + 1
			end
		elseif c == DQ or c == "'" then
			local quote = c
			local startI = i
			i = i + 1
			local closed = false
			while i <= n do
				local cc = line:sub(i, i)
				if cc == BS then
					i = i + 2
				elseif cc == quote then
					i = i + 1
					closed = true
					break
				else
					i = i + 1
				end
			end
			local tokType = "string"
			if not closed then
				tokType = "string_err"
			end
			tokens[#tokens + 1] = {t = tokType, s = line:sub(startI, i - 1)}
		elseif c == "[" and (line:sub(i + 1, i + 1) == "[" or line:sub(i + 1, i + 1) == "=") then
			local eqs = 0
			local j = i + 1
			while line:sub(j, j) == "=" do
				eqs = eqs + 1
				j = j + 1
			end
			if line:sub(j, j) == "[" then
				local closePattern = "%]" .. string.rep("=", eqs) .. "%]"
				local closeStart, closeEnd = string.find(line, closePattern, j + 1)
				if closeStart then
					tokens[#tokens + 1] = {t = "string", s = line:sub(i, closeEnd)}
					i = closeEnd + 1
				else
					tokens[#tokens + 1] = {t = "string", s = line:sub(i)}
					i = n + 1
				end
			else
				tokens[#tokens + 1] = {t = "op", s = c}
				i = i + 1
			end
		elseif c:match("%d") then
			local startI = i
			while i <= n and line:sub(i, i):match("[%d%.xXa-fA-F]") do
				i = i + 1
			end
			tokens[#tokens + 1] = {t = "number", s = line:sub(startI, i - 1)}
		elseif c:match("[%a_]") then
			local startI = i
			while i <= n and line:sub(i, i):match("[%w_]") do
				i = i + 1
			end
			local word = line:sub(startI, i - 1)
			local rest = line:sub(i)
			local isCall = rest:match("^%s*%(") ~= nil
			if KEYWORDS[word] then
				tokens[#tokens + 1] = {t = "keyword", s = word}
			elseif BUILTINS[word] then
				tokens[#tokens + 1] = {t = "builtin", s = word}
			elseif isCall then
				tokens[#tokens + 1] = {t = "funcname", s = word}
			else
				tokens[#tokens + 1] = {t = "ident", s = word}
			end
		elseif c:match("[%+%-%*/%%%^#<>=~%.,:;%(%)%[%]%{%}]") then
			local two = line:sub(i, i + 1)
			if two == "==" or two == "~=" or two == "<=" or two == ">=" or two == ".." or two == "::" then
				tokens[#tokens + 1] = {t = "op", s = two}
				i = i + 2
			else
				tokens[#tokens + 1] = {t = "op", s = c}
				i = i + 1
			end
		else
			tokens[#tokens + 1] = {t = "text", s = c}
			i = i + 1
		end
	end

	return tokens, false
end

local function highlightLine(line, inLongComment)
	local tokens, stillIn = tokenizeLine(line, inLongComment)
	return tokens, stillIn
end

local OPEN_TO_CLOSE = {}
OPEN_TO_CLOSE["("] = ")"
OPEN_TO_CLOSE["["] = "]"
OPEN_TO_CLOSE["{"] = "}"

local CLOSE_TO_OPEN = {}
CLOSE_TO_OPEN[")"] = "("
CLOSE_TO_OPEN["]"] = "["
CLOSE_TO_OPEN["}"] = "{"

local function getLines(text)
	local lines = {}
	for s in (text .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = s
	end
	if #lines == 0 then
		lines = {""}
	end
	return lines
end

local function isCursorInStringOrComment(text, cursorPos)
	if cursorPos < 0 then
		cursorPos = #text + 1
	end
	local before = text:sub(1, cursorPos - 1)
	local lineNumber = 1
	local lastNewline = 0
	for i = 1, #before do
		if before:sub(i, i) == "\n" then
			lineNumber = lineNumber + 1
			lastNewline = i
		end
	end
	local colOnLine = cursorPos - lastNewline

	local lines = getLines(text)
	local inLongComment = false
	for i = 1, lineNumber - 1 do
		local tokens, stillIn = tokenizeLine(lines[i] or "", inLongComment)
		inLongComment = stillIn
	end

	local currentLineText = lines[lineNumber] or ""
	local tokens = tokenizeLine(currentLineText, inLongComment)
	local scanCol = 1
	for tIndex = 1, #tokens do
		local tok = tokens[tIndex]
		local tokLen = #tok.s
		local tokStart = scanCol
		local tokEnd = scanCol + tokLen
		if colOnLine > tokStart and colOnLine <= tokEnd then
			if tok.t == "string" or tok.t == "string_err" or tok.t == "comment" then
				return true
			end
			return false
		end
		scanCol = tokEnd
	end
	return false
end

local function checkErrors(fullText)
	local errors = {}
	local stack = {}
	local lines = getLines(fullText)
	local inLongComment = false

	for lineNum = 1, #lines do
		local line = lines[lineNum]
		local tokens, stillIn = tokenizeLine(line, inLongComment)
		inLongComment = stillIn

		for tIndex = 1, #tokens do
			local tok = tokens[tIndex]
			if tok.t == "string_err" then
				errors[#errors + 1] = {line = lineNum, msg = "Unterminated string literal"}
			elseif tok.t == "op" then
				local c = tok.s
				if OPEN_TO_CLOSE[c] then
					stack[#stack + 1] = {c = c, line = lineNum}
				elseif CLOSE_TO_OPEN[c] then
					if #stack == 0 then
						errors[#errors + 1] = {line = lineNum, msg = "Unexpected closing bracket, no matching opener"}
					else
						local top = stack[#stack]
						if top.c ~= CLOSE_TO_OPEN[c] then
							errors[#errors + 1] = {line = lineNum, msg = "Mismatched closing bracket"}
							stack[#stack] = nil
						else
							stack[#stack] = nil
						end
					end
				end
			elseif tok.t == "ident" or tok.t == "builtin" then
				local lowered = tok.s:lower()
				for bIndex = 1, #BLOCKED_TERMS do
					if lowered == BLOCKED_TERMS[bIndex] then
						errors[#errors + 1] = {line = lineNum, msg = tok.s .. " is blocked in this sandbox"}
					end
				end
			elseif tok.t == "string" then
				local loweredStr = tok.s:lower()
				for bIndex = 1, #BLOCKED_TERMS do
					local blocked = BLOCKED_TERMS[bIndex]
					if string.find(loweredStr, blocked, 1, true) then
						errors[#errors + 1] = {line = lineNum, msg = blocked .. " is blocked in this sandbox"}
					end
				end
			end
		end
	end

	if inLongComment then
		errors[#errors + 1] = {line = #lines, msg = "Unterminated long comment or string"}
	end

	for i = #stack, 1, -1 do
		local unclosed = stack[i]
		errors[#errors + 1] = {line = unclosed.line, msg = "Unclosed " .. unclosed.c .. " never closed"}
	end

	table.sort(errors, function(a, b)
		return a.line < b.line
	end)
	return errors
end

local function scanDeclaredNames(fullText)
	local names = {}
	local seen = {}
	local lines = getLines(fullText)
	local inLongComment = false

	local function addName(name, lineNum)
		if name == nil or name == "" then
			return
		end
		if KEYWORDS[name] then
			return
		end
		if not seen[name] then
			seen[name] = true
			names[#names + 1] = {label = name, detail = "variable (line " .. lineNum .. ")"}
		end
	end

	for lineNum = 1, #lines do
		local line = lines[lineNum]
		local tokens, stillIn = tokenizeLine(line, inLongComment)
		inLongComment = stillIn

		local tIndex = 1
		while tIndex <= #tokens do
			local tok = tokens[tIndex]
			if tok.t == "keyword" and tok.s == "local" then
				local nextIndex = tIndex + 1
				while tokens[nextIndex] ~= nil and tokens[nextIndex].t == "ws" do
					nextIndex = nextIndex + 1
				end
				if tokens[nextIndex] ~= nil and tokens[nextIndex].t == "keyword" and tokens[nextIndex].s == "function" then
					local fnNameIndex = nextIndex + 1
					while tokens[fnNameIndex] ~= nil and tokens[fnNameIndex].t == "ws" do
						fnNameIndex = fnNameIndex + 1
					end
					if tokens[fnNameIndex] ~= nil and tokens[fnNameIndex].t == "ident" then
						addName(tokens[fnNameIndex].s, lineNum)
					end
				else
					local scanIndex = nextIndex
					while tokens[scanIndex] ~= nil do
						local scanTok = tokens[scanIndex]
						if scanTok.t == "ident" then
							addName(scanTok.s, lineNum)
						elseif scanTok.t == "op" and scanTok.s == "=" then
							break
						elseif scanTok.t == "op" and scanTok.s ~= "," then
							break
						end
						scanIndex = scanIndex + 1
					end
				end
			elseif tok.t == "keyword" and tok.s == "function" then
				local parenDepth = 0
				local scanIndex = tIndex + 1
				local foundOpenParen = false
				while tokens[scanIndex] ~= nil do
					local scanTok = tokens[scanIndex]
					if scanTok.t == "op" and scanTok.s == "(" then
						foundOpenParen = true
						parenDepth = parenDepth + 1
					elseif scanTok.t == "op" and scanTok.s == ")" then
						parenDepth = parenDepth - 1
						if parenDepth <= 0 then
							break
						end
					elseif foundOpenParen and scanTok.t == "ident" then
						addName(scanTok.s, lineNum)
					end
					scanIndex = scanIndex + 1
				end
			elseif tok.t == "keyword" and tok.s == "for" then
				local scanIndex = tIndex + 1
				while tokens[scanIndex] ~= nil do
					local scanTok = tokens[scanIndex]
					if scanTok.t == "ident" then
						addName(scanTok.s, lineNum)
					elseif scanTok.t == "keyword" and scanTok.s == "in" then
						break
					elseif scanTok.t == "op" and scanTok.s == "=" then
						break
					elseif scanTok.t ~= "ws" and scanTok.t ~= "op" then
						break
					end
					scanIndex = scanIndex + 1
				end
			end
			tIndex = tIndex + 1
		end
	end

	return names
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ezCode"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 1000
screenGui.Parent = playerGui

local TITLE_BAR_HEIGHT = 34
local EXPANDED_HEIGHT_SCALE = 0.5

local mainFrame = Instance.new("Frame")
mainFrame.Name = "ezCodeWindow"
local initialViewportSize = workspace.CurrentCamera.ViewportSize
local initialHeight = math.floor(initialViewportSize.Y * EXPANDED_HEIGHT_SCALE)
mainFrame.Size = UDim2.new(1, 0, 0, initialHeight)
mainFrame.Position = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundColor3 = COLOR_BG
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, TITLE_BAR_HEIGHT)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = COLOR_TITLE
titleBar.BorderSizePixel = 1
titleBar.BorderColor3 = Color3.fromRGB(40, 40, 40)
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.Size = UDim2.new(1, -192, 1, 0)
titleLabel.Font = FONT
titleLabel.TextSize = 14
titleLabel.TextColor3 = COLOR_TEXT
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "ezCode by Axo"
titleLabel.Parent = titleBar

local fontDownBtn = Instance.new("TextButton")
fontDownBtn.Size = UDim2.new(0, 24, 0, 26)
fontDownBtn.Position = UDim2.new(1, -184, 0, 4)
fontDownBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
fontDownBtn.BorderSizePixel = 1
fontDownBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
fontDownBtn.Text = "A-"
fontDownBtn.Font = FONT
fontDownBtn.TextSize = 12
fontDownBtn.TextColor3 = Color3.new(1, 1, 1)
fontDownBtn.Parent = titleBar

local fontUpBtn = Instance.new("TextButton")
fontUpBtn.Size = UDim2.new(0, 24, 0, 26)
fontUpBtn.Position = UDim2.new(1, -156, 0, 4)
fontUpBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
fontUpBtn.BorderSizePixel = 1
fontUpBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
fontUpBtn.Text = "A+"
fontUpBtn.Font = FONT
fontUpBtn.TextSize = 12
fontUpBtn.TextColor3 = Color3.new(1, 1, 1)
fontUpBtn.Parent = titleBar

local varsBtn = Instance.new("TextButton")
varsBtn.Size = UDim2.new(0, 44, 0, 26)
varsBtn.Position = UDim2.new(1, -128, 0, 4)
varsBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 100)
varsBtn.BorderSizePixel = 1
varsBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
varsBtn.Text = "Vars"
varsBtn.Font = FONT
varsBtn.TextSize = 12
varsBtn.TextColor3 = Color3.new(1, 1, 1)
varsBtn.Parent = titleBar

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 44, 0, 26)
clearBtn.Position = UDim2.new(1, -80, 0, 4)
clearBtn.BackgroundColor3 = Color3.fromRGB(90, 70, 50)
clearBtn.BorderSizePixel = 1
clearBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
clearBtn.Text = "Clear"
clearBtn.Font = FONT
clearBtn.TextSize = 12
clearBtn.TextColor3 = Color3.new(1, 1, 1)
clearBtn.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -32, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
closeBtn.BorderSizePixel = 1
closeBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
closeBtn.Text = "X"
closeBtn.Font = FONT
closeBtn.TextSize = 13
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = titleBar

local bodyFrame = Instance.new("Frame")
bodyFrame.Name = "Body"
bodyFrame.Position = UDim2.new(0, 0, 0, TITLE_BAR_HEIGHT)
bodyFrame.Size = UDim2.new(1, 0, 1, -TITLE_BAR_HEIGHT - 22)
bodyFrame.BackgroundColor3 = COLOR_BG
bodyFrame.BorderSizePixel = 0
bodyFrame.Parent = mainFrame

local gutterFrame = Instance.new("ScrollingFrame")
gutterFrame.Name = "Gutter"
gutterFrame.Position = UDim2.new(0, 0, 0, 0)
gutterFrame.Size = UDim2.new(0, GUTTER_WIDTH, 1, 0)
gutterFrame.BackgroundColor3 = COLOR_GUTTER
gutterFrame.BorderSizePixel = 1
gutterFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
gutterFrame.ScrollBarThickness = 0
gutterFrame.ScrollingEnabled = false
gutterFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
gutterFrame.Parent = bodyFrame

local gutterText = Instance.new("TextLabel")
gutterText.Name = "GutterText"
gutterText.BackgroundTransparency = 1
gutterText.Position = UDim2.new(0, 0, 0, 4)
gutterText.Size = UDim2.new(1, -6, 0, 10000)
gutterText.Font = FONT
gutterText.TextSize = FONT_SIZE
gutterText.TextColor3 = COLOR_GUTTER_TEXT
gutterText.TextXAlignment = Enum.TextXAlignment.Right
gutterText.TextYAlignment = Enum.TextYAlignment.Top
gutterText.RichText = false
gutterText.Text = "1"
gutterText.Parent = gutterFrame

local editorScroll = Instance.new("ScrollingFrame")
editorScroll.Name = "EditorScroll"
editorScroll.Position = UDim2.new(0, GUTTER_WIDTH, 0, 0)
editorScroll.Size = UDim2.new(1, -GUTTER_WIDTH, 1, 0)
editorScroll.BackgroundColor3 = COLOR_BG
editorScroll.BorderSizePixel = 0
editorScroll.ScrollBarThickness = 8
editorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
editorScroll.Parent = bodyFrame

local currentLineHighlight = Instance.new("Frame")
currentLineHighlight.Name = "CurrentLine"
currentLineHighlight.BackgroundColor3 = COLOR_CURLINE
currentLineHighlight.BorderSizePixel = 0
currentLineHighlight.Size = UDim2.new(1, 0, 0, LINE_HEIGHT)
currentLineHighlight.Position = UDim2.new(0, 0, 0, 4)
currentLineHighlight.ZIndex = 0
currentLineHighlight.Parent = editorScroll

local highlightContainer = Instance.new("Frame")
highlightContainer.Name = "Highlight"
highlightContainer.BackgroundTransparency = 1
highlightContainer.Position = UDim2.new(0, 6, 0, 4)
highlightContainer.Size = UDim2.new(1, -12, 0, 10000)
highlightContainer.ZIndex = 1
highlightContainer.Parent = editorScroll

local tokenLabelPool = {}

local codeBox = Instance.new("TextBox")
codeBox.Name = "CodeBox"
codeBox.BackgroundTransparency = 1
codeBox.Position = UDim2.new(0, 6, 0, 4)
codeBox.Size = UDim2.new(1, -12, 0, 10000)
codeBox.Font = FONT
codeBox.TextSize = FONT_SIZE
codeBox.TextColor3 = COLOR_TEXT
codeBox.TextTransparency = 1
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.TextWrapped = false
codeBox.ClearTextOnFocus = false
codeBox.MultiLine = true
codeBox.ZIndex = 2
codeBox.Parent = editorScroll

do
	local sampleLines = {}
	sampleLines[1] = "local function greet(name)"
	sampleLines[2] = "\tprint(" .. DQ .. "Hello, " .. DQ .. " .. name)"
	sampleLines[3] = "end"
	sampleLines[4] = ""
	sampleLines[5] = "greet(" .. DQ .. "World" .. DQ .. ")"
	sampleLines[6] = ""
	codeBox.Text = table.concat(sampleLines, "\n")
end

local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Position = UDim2.new(0, 0, 1, -22)
statusBar.Size = UDim2.new(1, 0, 0, 22)
statusBar.BackgroundColor3 = COLOR_STATUS
statusBar.BorderSizePixel = 1
statusBar.BorderColor3 = Color3.fromRGB(40, 40, 40)
statusBar.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 10, 0, 0)
statusLabel.Size = UDim2.new(1, -20, 1, 0)
statusLabel.Font = FONT
statusLabel.TextSize = 12
statusLabel.TextColor3 = COLOR_GUTTER_TEXT
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "Ln 1, Col 1"
statusLabel.Parent = statusBar

local statusButtonOverlay = Instance.new("TextButton")
statusButtonOverlay.BackgroundTransparency = 1
statusButtonOverlay.Text = ""
statusButtonOverlay.Size = UDim2.new(1, 0, 1, 0)
statusButtonOverlay.Parent = statusBar

local errorPanel = Instance.new("ScrollingFrame")
errorPanel.Name = "ErrorPanel"
errorPanel.Visible = false
errorPanel.Position = UDim2.new(0.05, 0, 1, -160)
errorPanel.Size = UDim2.new(0.9, 0, 0, 140)
errorPanel.BackgroundColor3 = COLOR_AUTO
errorPanel.BorderSizePixel = 1
errorPanel.BorderColor3 = Color3.fromRGB(40, 40, 40)
errorPanel.ScrollBarThickness = 6
errorPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
errorPanel.ZIndex = 5
errorPanel.Parent = mainFrame

local errorPanelLayout = Instance.new("UIListLayout")
errorPanelLayout.Parent = errorPanel

local varsPanel = Instance.new("ScrollingFrame")
varsPanel.Name = "VarsPanel"
varsPanel.Visible = false
varsPanel.Position = UDim2.new(0.05, 0, 1, -160)
varsPanel.Size = UDim2.new(0.9, 0, 0, 140)
varsPanel.BackgroundColor3 = COLOR_AUTO
varsPanel.BorderSizePixel = 1
varsPanel.BorderColor3 = Color3.fromRGB(40, 40, 40)
varsPanel.ScrollBarThickness = 6
varsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
varsPanel.ZIndex = 6
varsPanel.Parent = mainFrame

local varsPanelLayout = Instance.new("UIListLayout")
varsPanelLayout.Parent = varsPanel

local autoFrame = Instance.new("Frame")
autoFrame.Name = "Autocomplete"
autoFrame.Visible = false
autoFrame.Size = UDim2.new(0, 320, 0, 150)
autoFrame.BackgroundColor3 = COLOR_AUTO
autoFrame.BorderSizePixel = 1
autoFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
autoFrame.ZIndex = 10
autoFrame.Parent = mainFrame

local autoScroll = Instance.new("ScrollingFrame")
autoScroll.Size = UDim2.new(1, 0, 1, 0)
autoScroll.BackgroundTransparency = 1
autoScroll.BorderSizePixel = 0
autoScroll.ScrollBarThickness = 6
autoScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
autoScroll.ZIndex = 10
autoScroll.Parent = autoFrame

local autoLayout = Instance.new("UIListLayout")
autoLayout.Parent = autoScroll

local currentSuggestions = {}
local selectedSuggestionIndex = 1
local autoOpen = false
local ignoreNextTextChanged = false
local lastKnownText = codeBox.Text

local function computeLineCol(text, cursorPos)
	local upToCursor = text:sub(1, cursorPos - 1)
	local line = 1
	local lastNewline = 0
	for i = 1, #upToCursor do
		if upToCursor:sub(i, i) == "\n" then
			line = line + 1
			lastNewline = i
		end
	end
	local col = (cursorPos - 1) - lastNewline + 1
	return line, col
end

local function getPooledLabel(poolIndex)
	local lbl = tokenLabelPool[poolIndex]
	if lbl == nil then
		lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.BorderSizePixel = 0
		lbl.Font = FONT
		lbl.TextSize = FONT_SIZE
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextYAlignment = Enum.TextYAlignment.Top
		lbl.RichText = false
		lbl.TextWrapped = false
		lbl.AutomaticSize = Enum.AutomaticSize.None
		lbl.ZIndex = 1
		lbl.Parent = highlightContainer
		tokenLabelPool[poolIndex] = lbl
	end
	return lbl
end

local function updateHighlight()
	local text = codeBox.Text
	local lines = getLines(text)
	local inLongComment = false
	local usedLabels = 0
	local measureBounds = Vector2.new(4000, 100)

	for lineIndex = 1, #lines do
		local tokens, stillIn = highlightLine(lines[lineIndex], inLongComment)
		inLongComment = stillIn

		local xOffset = 0
		local yOffset = (lineIndex - 1) * LINE_HEIGHT

		for tIndex = 1, #tokens do
			local tok = tokens[tIndex]
			if tok.s ~= "" then
				usedLabels = usedLabels + 1
				local lbl = getPooledLabel(usedLabels)
				lbl.Text = tok.s
				lbl.TextColor3 = tokenColor(tok.t)
				local measured = TextService:GetTextSize(tok.s, FONT_SIZE, FONT, measureBounds)
				lbl.Size = UDim2.new(0, measured.X + 2, 0, LINE_HEIGHT)
				lbl.Position = UDim2.new(0, xOffset, 0, yOffset)
				lbl.Visible = true
				xOffset = xOffset + measured.X
			end
		end
	end

	for poolIndex = usedLabels + 1, #tokenLabelPool do
		tokenLabelPool[poolIndex].Visible = false
	end

	local neededHeight = math.max(#lines * LINE_HEIGHT + 20, editorScroll.AbsoluteSize.Y)
	highlightContainer.Size = UDim2.new(1, -12, 0, neededHeight)
	codeBox.Size = UDim2.new(1, -12, 0, neededHeight)
	gutterText.Size = UDim2.new(1, -6, 0, neededHeight)

	local gutterLines = {}
	for i = 1, #lines do
		gutterLines[i] = tostring(i)
	end
	gutterText.Text = table.concat(gutterLines, "\n")

	editorScroll.CanvasSize = UDim2.new(0, 0, 0, neededHeight)
	gutterFrame.CanvasSize = UDim2.new(0, 0, 0, neededHeight)
end

local function updateErrors()
	local errors = checkErrors(codeBox.Text)

	local children = errorPanel:GetChildren()
	for index = 1, #children do
		if children[index]:IsA("TextLabel") then
			children[index]:Destroy()
		end
	end

	if #errors == 0 then
		local okLabel = Instance.new("TextLabel")
		okLabel.BackgroundTransparency = 1
		okLabel.Size = UDim2.new(1, -8, 0, 20)
		okLabel.Font = FONT
		okLabel.TextSize = 12
		okLabel.TextColor3 = Color3.fromRGB(180, 220, 180)
		okLabel.TextXAlignment = Enum.TextXAlignment.Left
		okLabel.Text = "  No errors detected"
		okLabel.Parent = errorPanel
	else
		for index = 1, #errors do
			local err = errors[index]
			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Size = UDim2.new(1, -8, 0, 20)
			lbl.Font = FONT
			lbl.TextSize = 12
			lbl.TextColor3 = COLOR_ERROR
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextWrapped = true
			lbl.AutomaticSize = Enum.AutomaticSize.Y
			lbl.Text = "  Ln " .. err.line .. ": " .. err.msg
			lbl.Parent = errorPanel
		end
	end

	errorPanel.CanvasSize = UDim2.new(0, 0, 0, errorPanelLayout.AbsoluteContentSize.Y + 8)
	return errors
end

local function updateStatus()
	local text = codeBox.Text
	local cursorPos = codeBox.CursorPosition
	if cursorPos < 0 then
		cursorPos = #text + 1
	end
	local line, col = computeLineCol(text, cursorPos)
	local errors = checkErrors(text)
	local errWord = "errors"
	if #errors == 1 then
		errWord = "error"
	end
	statusLabel.Text = "Ln " .. line .. ", Col " .. col .. "   " .. #text .. " chars   " .. #errors .. " " .. errWord
	currentLineHighlight.Position = UDim2.new(0, 0, 0, 4 + (line - 1) * LINE_HEIGHT)

	local lineTop = (line - 1) * LINE_HEIGHT
	local lineBottom = lineTop + LINE_HEIGHT
	local viewTop = editorScroll.CanvasPosition.Y
	local viewBottom = viewTop + editorScroll.AbsoluteSize.Y
	if lineTop < viewTop then
		editorScroll.CanvasPosition = Vector2.new(editorScroll.CanvasPosition.X, math.max(0, lineTop - 8))
	elseif lineBottom > viewBottom then
		editorScroll.CanvasPosition = Vector2.new(editorScroll.CanvasPosition.X, lineBottom - editorScroll.AbsoluteSize.Y + 8)
	end

	return line, col
end

local function getWordBeforeCursor()
	local text = codeBox.Text
	local cursorPos = codeBox.CursorPosition
	if cursorPos < 0 then
		cursorPos = #text + 1
	end
	local before = text:sub(1, cursorPos - 1)
	local wordStart = #before
	while wordStart > 0 and before:sub(wordStart, wordStart):match("[%w_]") do
		wordStart = wordStart - 1
	end
	local word = before:sub(wordStart + 1)
	local dotOwner = nil
	local sepChar = before:sub(wordStart, wordStart)
	if sepChar == "." or sepChar == ":" then
		local ownerEnd = wordStart - 1
		local ownerStart = ownerEnd
		while ownerStart > 0 and before:sub(ownerStart, ownerStart):match("[%w_]") do
			ownerStart = ownerStart - 1
		end
		dotOwner = before:sub(ownerStart + 1, ownerEnd)
	end
	return word, wordStart + 1, dotOwner
end

local function updateVarsPanel()
	local children = varsPanel:GetChildren()
	for index = 1, #children do
		if children[index]:IsA("TextButton") then
			children[index]:Destroy()
		end
	end

	local declaredNames = scanDeclaredNames(codeBox.Text)

	if #declaredNames == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Size = UDim2.new(1, -8, 0, 20)
		emptyLabel.Font = FONT
		emptyLabel.TextSize = 12
		emptyLabel.TextColor3 = COLOR_GUTTER_TEXT
		emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
		emptyLabel.Text = "  No variables declared yet"
		emptyLabel.Name = "EmptyLabel"
		emptyLabel.Parent = varsPanel
	else
		for index = 1, #declaredNames do
			local entry = declaredNames[index]
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 26)
			btn.BackgroundColor3 = COLOR_AUTO
			btn.BorderSizePixel = 0
			btn.Font = FONT
			btn.TextSize = 13
			btn.TextColor3 = COLOR_TEXT
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Text = "  " .. entry.label .. "   (" .. entry.detail .. ")"
			btn.LayoutOrder = index
			btn.ZIndex = 7
			btn.AutoButtonColor = false
			btn.Parent = varsPanel

			local function insertVarName()
				local text = codeBox.Text
				local cursorPos = codeBox.CursorPosition
				if cursorPos < 0 then
					cursorPos = #text + 1
				end
				local word, wordStart = getWordBeforeCursor()
				local replaceStart = wordStart
				if word == "" then
					replaceStart = cursorPos
				end
				local newText = text:sub(1, replaceStart - 1) .. entry.label .. text:sub(cursorPos)
				ignoreNextTextChanged = true
				codeBox.Text = newText
				codeBox.CursorPosition = replaceStart + #entry.label
				ignoreNextTextChanged = false
				lastKnownText = newText
				varsPanel.Visible = false
				updateHighlight()
				updateErrors()
				updateStatus()
			end

			btn.MouseButton1Click:Connect(insertVarName)
			btn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then
					insertVarName()
				end
			end)
		end
	end

	varsPanel.CanvasSize = UDim2.new(0, 0, 0, varsPanelLayout.AbsoluteContentSize.Y + 8)
end

local function closeAutocomplete()
	autoFrame.Visible = false
	autoOpen = false
	currentSuggestions = {}
end

local function renderAutocomplete()
	local children = autoScroll:GetChildren()
	for index = 1, #children do
		if children[index]:IsA("TextButton") then
			children[index]:Destroy()
		end
	end

	local capturedText = codeBox.Text
	local capturedCursorPos = codeBox.CursorPosition
	if capturedCursorPos < 0 then
		capturedCursorPos = #capturedText + 1
	end
	local capturedWord, capturedWordStart = getWordBeforeCursor()

	for idx = 1, #currentSuggestions do
		local entry = currentSuggestions[idx]
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 32)
		if idx == selectedSuggestionIndex then
			btn.BackgroundColor3 = COLOR_AUTO_SEL
		else
			btn.BackgroundColor3 = COLOR_AUTO
		end
		btn.BorderSizePixel = 0
		btn.Font = FONT
		btn.TextSize = 13
		btn.TextColor3 = COLOR_TEXT
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextYAlignment = Enum.TextYAlignment.Top
		btn.Text = "  " .. entry.label
		btn.LayoutOrder = idx
		btn.ZIndex = 11
		btn.AutoButtonColor = false
		btn.Parent = autoScroll

		local subLabel = Instance.new("TextLabel")
		subLabel.BackgroundTransparency = 1
		subLabel.Position = UDim2.new(0, 8, 0, 16)
		subLabel.Size = UDim2.new(1, -12, 0, 14)
		subLabel.Font = FONT
		subLabel.TextSize = 11
		subLabel.TextColor3 = COLOR_GUTTER_TEXT
		subLabel.TextXAlignment = Enum.TextXAlignment.Left
		local detailText = entry.detail
		if detailText == nil then
			detailText = ""
		end
		subLabel.Text = detailText
		subLabel.ZIndex = 12
		subLabel.Parent = btn

		local function applySuggestion()
			selectedSuggestionIndex = idx
			local insertWord = entry.label:match("^[%w_]+")
			if insertWord == nil then
				insertWord = entry.label
			end
			local newText = capturedText:sub(1, capturedWordStart - 1) .. insertWord .. capturedText:sub(capturedCursorPos)
			ignoreNextTextChanged = true
			codeBox.Text = newText
			codeBox.CursorPosition = capturedWordStart + #insertWord
			ignoreNextTextChanged = false
			lastKnownText = newText
			closeAutocomplete()
			updateHighlight()
			updateErrors()
			updateStatus()
		end

		btn.MouseButton1Click:Connect(applySuggestion)

		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				applySuggestion()
			end
		end)
	end

	autoScroll.CanvasSize = UDim2.new(0, 0, 0, #currentSuggestions * 32)
end

local function updateAutocomplete()
	local text = codeBox.Text
	local cursorPos = codeBox.CursorPosition
	if cursorPos < 0 then
		cursorPos = #text + 1
	end
	if isCursorInStringOrComment(text, cursorPos) then
		closeAutocomplete()
		return
	end

	local word, wordStart, dotOwner = getWordBeforeCursor()

	local pool = {}
	if dotOwner ~= nil and INTELLISENSE[dotOwner] ~= nil then
		pool = INTELLISENSE[dotOwner]
	elseif dotOwner ~= nil then
		pool = INTELLISENSE.instance
	else
		for k in pairs(KEYWORDS) do
			pool[#pool + 1] = {label = k, detail = "keyword"}
		end
		for k in pairs(BUILTINS) do
			pool[#pool + 1] = {label = k, detail = "global"}
		end
		for index = 1, #GLOBAL_SNIPPETS do
			pool[#pool + 1] = GLOBAL_SNIPPETS[index]
		end
		local declaredNames = scanDeclaredNames(codeBox.Text)
		for index = 1, #declaredNames do
			pool[#pool + 1] = declaredNames[index]
		end
	end

	if #word < 1 and dotOwner == nil then
		closeAutocomplete()
		return
	end

	local lowerWord = word:lower()
	local matches = {}
	for index = 1, #pool do
		local entry = pool[index]
		local baseLabel = entry.label:match("^[%w_]+")
		if baseLabel == nil then
			baseLabel = entry.label
		end
		if baseLabel:lower():sub(1, #lowerWord) == lowerWord and baseLabel ~= word then
			matches[#matches + 1] = entry
		end
	end

	if #matches == 0 then
		closeAutocomplete()
		return
	end

	table.sort(matches, function(a, b)
		return #a.label < #b.label
	end)

	local limited = {}
	local maxCount = math.min(#matches, 8)
	for i = 1, maxCount do
		limited[i] = matches[i]
	end
	currentSuggestions = limited
	selectedSuggestionIndex = 1
	autoOpen = true
	autoFrame.Visible = true

	local text = codeBox.Text
	local cursorPos = codeBox.CursorPosition
	if cursorPos < 0 then
		cursorPos = #text + 1
	end
	local line = computeLineCol(text, cursorPos)
	local yPos = TITLE_BAR_HEIGHT + 4 + line * LINE_HEIGHT - editorScroll.CanvasPosition.Y
	local popupHeight = math.min(#currentSuggestions * 32, 150)
	local availableWidth = mainFrame.AbsoluteSize.X - GUTTER_WIDTH - 40
	local minWidth = 160
	local popupWidth = math.max(minWidth, math.min(availableWidth, 320))
	autoFrame.Size = UDim2.new(0, popupWidth, 0, popupHeight)

	local maxY = mainFrame.AbsoluteSize.Y - 22 - popupHeight
	local minY = TITLE_BAR_HEIGHT
	local clampedY = minY
	if maxY >= minY then
		clampedY = math.max(minY, math.min(yPos, maxY))
	end
	autoFrame.Position = UDim2.new(0, GUTTER_WIDTH + 20, 0, clampedY)

	renderAutocomplete()
end

local function acceptSuggestion()
	if not autoOpen or #currentSuggestions == 0 then
		return false
	end
	local entry = currentSuggestions[selectedSuggestionIndex]
	local word, wordStart = getWordBeforeCursor()
	local text = codeBox.Text
	local cursorPos = codeBox.CursorPosition
	if cursorPos < 0 then
		cursorPos = #text + 1
	end
	local insertWord = entry.label:match("^[%w_]+")
	if insertWord == nil then
		insertWord = entry.label
	end
	local newText = text:sub(1, wordStart - 1) .. insertWord .. text:sub(cursorPos)
	codeBox.Text = newText
	codeBox.CursorPosition = wordStart + #insertWord
	closeAutocomplete()
	return true
end

local function getLineIndent(line)
	local indent = line:match("^[ \t]*")
	if indent == nil then
		indent = ""
	end
	return indent
end

local function shouldIndentAfter(line)
	local trimmed = line:gsub("%s+$", "")
	if trimmed:match("then$") then
		return true
	end
	if trimmed:match("do$") then
		return true
	end
	if trimmed:match("function[%w_%s]*%(.-%)$") then
		return true
	end
	if trimmed:match("{$") then
		return true
	end
	if trimmed:match("%($") then
		return true
	end
	if trimmed:match("%[$") then
		return true
	end
	if trimmed:match("else$") then
		return true
	end
	if trimmed:match("repeat$") then
		return true
	end
	return false
end

local function insertAtCursor(insertText)
	local text = codeBox.Text
	local cursorPos = codeBox.CursorPosition
	if cursorPos < 0 then
		cursorPos = #text + 1
	end
	local newText = text:sub(1, cursorPos - 1) .. insertText .. text:sub(cursorPos)
	ignoreNextTextChanged = true
	codeBox.Text = newText
	codeBox.CursorPosition = cursorPos + #insertText
	ignoreNextTextChanged = false
end

local refreshScheduled = false
local function scheduleRefresh()
	if refreshScheduled then
		return
	end
	refreshScheduled = true
	task.defer(function()
		refreshScheduled = false
		updateHighlight()
		updateErrors()
		updateStatus()
	end)
end

local function countUnclosedOnLine(lineText)
	local opens = 0
	local i = 1
	local n = #lineText
	local inString = nil
	while i <= n do
		local c = lineText:sub(i, i)
		if inString ~= nil then
			if c == BS then
				i = i + 1
			elseif c == inString then
				inString = nil
			end
		else
			if c == DQ or c == "'" then
				inString = c
			elseif c == "(" or c == "[" or c == "{" then
				opens = opens + 1
			elseif c == ")" or c == "]" or c == "}" then
				opens = opens - 1
			end
		end
		i = i + 1
	end
	return opens, inString
end

codeBox:GetPropertyChangedSignal("Text"):Connect(function()
	if ignoreNextTextChanged then
		lastKnownText = codeBox.Text
		return
	end

	lastKnownText = codeBox.Text
	scheduleRefresh()
	updateAutocomplete()
end)

local function applyEnterCompletion()
	local text = codeBox.Text
	local cursorPos = codeBox.CursorPosition
	if cursorPos < 0 then
		cursorPos = #text + 1
	end
	local lines = getLines(text)
	local line = computeLineCol(text, cursorPos)
	local prevLine = lines[line - 1]
	if prevLine ~= nil then
		local unclosedCount, unclosedQuote = countUnclosedOnLine(prevLine)
		if unclosedQuote ~= nil or unclosedCount > 0 then
			local before = text:sub(1, cursorPos - 1)
			local prevLineEndPos = before:match(".*\n()")
			if prevLineEndPos ~= nil then
				local insertPos = prevLineEndPos - 1
				local closers = ""
				if unclosedQuote ~= nil then
					closers = closers .. unclosedQuote
				end
				if unclosedCount > 0 then
					for i = 1, unclosedCount do
						closers = closers .. ")"
					end
				end
				text = text:sub(1, insertPos - 1) .. closers .. text:sub(insertPos)
				cursorPos = cursorPos + #closers
				ignoreNextTextChanged = true
				codeBox.Text = text
				ignoreNextTextChanged = false
			end
		end
	end
	if prevLine ~= nil then
		local indent = getLineIndent(prevLine)
		if shouldIndentAfter(prevLine) then
			indent = indent .. "\t"
		end
		if #indent > 0 then
			local curLineStart = cursorPos
			local newText = text:sub(1, curLineStart - 1) .. indent .. text:sub(curLineStart)
			ignoreNextTextChanged = true
			codeBox.Text = newText
			codeBox.CursorPosition = curLineStart + #indent
			ignoreNextTextChanged = false
		else
			codeBox.CursorPosition = cursorPos
		end
	end
	lastKnownText = codeBox.Text
	scheduleRefresh()
end

local function handleEnterPressedDesktop()
	if autoOpen then
		acceptSuggestion()
		scheduleRefresh()
	end
	task.defer(function()
		applyEnterCompletion()
	end)
end

local function handleEnterPressedMobile()
	if autoOpen then
		acceptSuggestion()
	end
	local text = codeBox.Text
	local cursorPos = codeBox.CursorPosition
	if cursorPos < 0 then
		cursorPos = #text + 1
	end
	local hasNewlineAtCursor = text:sub(cursorPos - 1, cursorPos - 1) == "\n"
	if not hasNewlineAtCursor then
		local newText = text:sub(1, cursorPos - 1) .. "\n" .. text:sub(cursorPos)
		ignoreNextTextChanged = true
		codeBox.Text = newText
		codeBox.CursorPosition = cursorPos + 1
		ignoreNextTextChanged = false
		lastKnownText = newText
	end
	applyEnterCompletion()
	if not codeBox:IsFocused() then
		codeBox:CaptureFocus()
	end
end

codeBox.ReturnPressedFromOnScreenKeyboard:Connect(function()
	handleEnterPressedMobile()
end)

codeBox.FocusLost:Connect(function(enterPressed)
	if enterPressed and not codeBox:IsFocused() then
		task.defer(function()
			codeBox:CaptureFocus()
		end)
	end
end)

codeBox:GetPropertyChangedSignal("CursorPosition"):Connect(function()
	updateStatus()
	updateAutocomplete()
end)

editorScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	gutterFrame.CanvasPosition = Vector2.new(0, editorScroll.CanvasPosition.Y)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not codeBox:IsFocused() then
		return
	end

	if input.KeyCode == Enum.KeyCode.Tab then
		if autoOpen then
			acceptSuggestion()
			updateHighlight()
			updateErrors()
			updateStatus()
		else
			local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			if shift then
				local text = codeBox.Text
				local cursorPos = codeBox.CursorPosition
				if cursorPos < 0 then
					cursorPos = #text + 1
				end
				local before = text:sub(1, cursorPos - 1)
				local ls = before:match(".*()\n")
				if ls == nil then
					ls = 0
				end
				local lineBegin = ls + 1
				local removed = 0
				if text:sub(lineBegin, lineBegin) == "\t" then
					removed = 1
				elseif text:sub(lineBegin, lineBegin + TAB_WIDTH - 1) == string.rep(" ", TAB_WIDTH) then
					removed = TAB_WIDTH
				end
				if removed > 0 then
					local newText = text:sub(1, lineBegin - 1) .. text:sub(lineBegin + removed)
					ignoreNextTextChanged = true
					codeBox.Text = newText
					codeBox.CursorPosition = math.max(lineBegin, cursorPos - removed)
					ignoreNextTextChanged = false
				end
			else
				insertAtCursor("\t")
			end
		end
		scheduleRefresh()
	elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
		handleEnterPressedDesktop()
	elseif input.KeyCode == Enum.KeyCode.Escape then
		if autoOpen then
			closeAutocomplete()
		end
	elseif input.KeyCode == Enum.KeyCode.Down then
		if autoOpen then
			selectedSuggestionIndex = math.min(selectedSuggestionIndex + 1, #currentSuggestions)
			renderAutocomplete()
		end
	elseif input.KeyCode == Enum.KeyCode.Up then
		if autoOpen then
			selectedSuggestionIndex = math.max(selectedSuggestionIndex - 1, 1)
			renderAutocomplete()
		end
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

statusButtonOverlay.MouseButton1Click:Connect(function()
	errorPanel.Visible = not errorPanel.Visible
	if errorPanel.Visible then
		varsPanel.Visible = false
	end
end)

clearBtn.MouseButton1Click:Connect(function()
	codeBox.Text = ""
	codeBox.CursorPosition = 1
	updateHighlight()
	updateErrors()
	updateStatus()
end)

varsBtn.MouseButton1Click:Connect(function()
	varsPanel.Visible = not varsPanel.Visible
	if varsPanel.Visible then
		errorPanel.Visible = false
		updateVarsPanel()
	end
end)

local function applyFontSize(newSize)
	newSize = math.clamp(newSize, 10, 28)
	if newSize == FONT_SIZE then
		return
	end
	FONT_SIZE = newSize
	LINE_HEIGHT = math.floor(newSize * 1.125)
	gutterText.TextSize = FONT_SIZE
	codeBox.TextSize = FONT_SIZE
	currentLineHighlight.Size = UDim2.new(1, 0, 0, LINE_HEIGHT)
	for poolIndex = 1, #tokenLabelPool do
		tokenLabelPool[poolIndex].TextSize = FONT_SIZE
	end
	updateHighlight()
	updateErrors()
	updateStatus()
end

fontUpBtn.MouseButton1Click:Connect(function()
	applyFontSize(FONT_SIZE + 2)
end)

fontDownBtn.MouseButton1Click:Connect(function()
	applyFontSize(FONT_SIZE - 2)
end)

local titleTapCount = 0
local titleTapResetScheduled = false

titleLabel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		titleTapCount = titleTapCount + 1
		if not titleTapResetScheduled then
			titleTapResetScheduled = true
			task.delay(0.4, function()
				if titleTapCount >= 2 then
					codeBox:CaptureFocus()
					codeBox.CursorPosition = 1
					codeBox.SelectionStart = 1
					codeBox.CursorPosition = #codeBox.Text + 1
				end
				titleTapCount = 0
				titleTapResetScheduled = false
			end)
		end
	end
end)

updateHighlight()
updateErrors()
updateStatus()
