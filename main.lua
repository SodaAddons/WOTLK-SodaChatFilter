local set = {}

function set.Add(t, key)
  t[key] = true
end

function set.Remove(t, key)
  t[key] = nil
end

function set.Contains(t, key)
  return t[key] ~= nil
end

function set.GetSize(t)
  local i = 0
  for k, v in pairs(t) do
    i = i + 1
  end
  return i
end

function set.Print(t)
  for k, v in pairs(t) do
    print(k)
  end
end

local debugEnabled = false
local lastLineID = nil
local filters = {}
local playerName, realm = UnitName("player");

local frame = CreateFrame("FRAME"); -- Create a frame to respond to events
frame:RegisterEvent("ADDON_LOADED"); -- Fires when saved variables are loaded
frame:RegisterEvent("PLAYER_LOGOUT"); -- Fires when user is about to log out
frame:RegisterEvent("PLAYER_ENTERING_WORLD"); --Fires when character is loaded in

function frame:OnEvent(event, arg1, arg2)
  if event == "ADDON_LOADED" and arg1 == "SodaChatFilter" then
    if ChatFilters == nil then
      ChatFilters = {}
    else
      filters = ChatFilters
      local filterCount = set.GetSize(filters)
      if filterCount > 0 then
        print("SCF currently uses : " .. filterCount .. " filters. Type /SCF print to list them.")
      else
        print("SCF currently contains 0 filters. Type \"/SCF add\" followed by the word or sentence_containing_multiple_words")
      end
    end
  end
  if event == "PLAYER_LOGOUT" then
    ChatFilters = filters
  end
end

frame:SetScript("OnEvent", frame.OnEvent);

local function PrintFilters()
  print("SCF Print:")
  set.Print(filters)
end

local function RemoveIcons(msg)
  msg = msg:gsub("{%a+%d+}", "");
  msg = msg:gsub("{%a+}", "");
  return msg
end

local function PrintDebugMessage(msg)
  print("|cFFFFFF00", "[SCF] message filtered:", msg, "|r")
end

SLASH_SCF1 = "/SCF"
local function MyCommands(msg, editbox)
  local case, text = strsplit(" ", msg, 2)
  if case == "add" then
    for word in text:gmatch("%S+") do
      if word:find("_") then
        word = gsub(word, "_", " ")
      end
      if not set.Contains(filters, word) then
        word = string.lower(word)
        set.Add(filters, word)
        print("SCF Added: " .. word)
      end
    end
  elseif case == "remove" then
    for word in text:gmatch("%S+") do
      if word:find("_") then
        word = gsub(word, "_", " ")
      end
      if set.Contains(filters, word) then
        word = string.lower(word)
        set.Remove(filters, word)
        print("SCF Removed: " .. word)
      end
    end
  elseif case == "debug" then
    debugEnabled = not debugEnabled
    local val = debugEnabled and "ON" or "OFF"
    print("SCF debugging toggled", val)
  elseif case == "clear" then
    for filter, v in pairs(filters) do
      set.Remove(filters, filter)
    end
    print("SCF Cleared")
  elseif case == "print" then
    PrintFilters()
  else
    print("SCF: Unknown parameter. Valid parameters: add x, remove x, clear, debug")
  end
end

SlashCmdList["SCF"] = MyCommands

local function MyChatFilter(self, event, msg, author, ...)
  local authorName, realm = strsplit("-", author, 2)
  local _, channel, _, _, _, _, asdf, _, lineID, _ = ...

  if authorName == playerName then
    return false, msg, author, ... --do not filter player, return early
  end

  local shouldFilter = false
  msg = RemoveIcons(msg)
  loweredMsg = string.lower(msg)

  for filter, _ in pairs(filters) do
    local startPos, endPos = string.find(loweredMsg, filter)
    if endPos ~= nil then --there is a match
      if endPos + 1 > #loweredMsg then --the text is longer than full message
        shouldFilter = true
        break
      end
      local followingChar = string.sub(loweredMsg, endPos + 1, endPos + 1)
      if string.match(followingChar, "[^a-zA-Z%d]") then --following char is whitespace or non-alphanumeric, filter the message
        shouldFilter = true
        break
      end
    end
  end

  if shouldFilter then
    if debugEnabled and lineID ~= lastLineID then
      PrintDebugMessage(msg)
    end
  end

  lastLineID = lineID

  return shouldFilter, msg, author, ... --if shouldfilter is true the message is filtered out
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", MyChatFilter)
