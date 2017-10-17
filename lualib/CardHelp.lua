
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
      table.insert(num,c,1)
    end
    if num[c] == 4 then
      state = (state | Mask.GANG)
    end
  end

  return state
end

return K
