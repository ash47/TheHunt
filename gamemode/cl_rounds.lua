AddCSLuaFile()

if(SERVER) then return end

net.Receive('RoundShit', function(len)
  theHunt.round = net.ReadUInt(4)
  theHunt.roundEnd = net.ReadFloat()
  theHunt.roundSort = net.ReadUInt(theHunt.ROUND_SORT_BITCOUNT)
end)
