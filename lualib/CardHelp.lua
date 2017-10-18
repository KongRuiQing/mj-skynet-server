
local K = {}

local Mask = {
  CHI = 0x01,
  PENG = 0x02,
  GANG = 0x04,
}

function K.getStateAtStart(card_list)
  local num = {}
  local state = 0
  for i,c in pairs(card_list) do
    if num[c] then
      num[c] = num[c] + 1
    else
      num[c] = 1
    end
    if num[c] == 4 then
      state = (state | Mask.GANG)
    end
  end
  return state
end

function K.canChi(card_list,card)
  if card == nil then
    return false
  end
  if ((card & 0xF0) >> 4) == 0x04 then
    return false
  end
  local card_set = {}
  for i,c in pairs(card_list) do
    if card_set[c] then
      card_set[c] = card_set[c] + 1
    else
      card_set[c] = 1
    end
  end

  local card_point = card & 0x0F
  if card_point == 1 then
    local y = (card & 0xF0) + 2
    local z = (card & 0xF0) + 3
    if card_set[y] and card_set[z] then
      return true
    end
  elseif card_point == 9 then
    local x = (card & 0xF0) + 7
    local y = (card & 0xF0) + 8
    if card_set[x] and card_set[y] then
      return true
    end
  else
    local x = (card & 0xF0) + (card_point - 1)
    local z = (card & 0xF0) + (card_point + 1)
    if card_set[x] and card_set[z] then
      return true
    end
  end

  return false
end

return K
