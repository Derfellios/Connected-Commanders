function Server_StartGame(game, standing)

	for _, territory in pairs(standing.Territories)  do
		if territory.IsNeutral == false then
			local New_Commander = WL.Commander.Create(territory.OwnerPlayerID)
			territory.NumArmies = WL.Armies.Create(territory.NumArmies.NumArmies, {New_Commander} );
			
		end 
	end

end