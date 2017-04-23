function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if order.proxyType == 'GameOrderStateTransition' then
		skipThisOrder(WL.ModOrderControl.Skip)
	end
	
	if order.proxyType == 'GameOrderAttackTransfer'   and result.IsAttack then 
	if is_commander_killed(result) then
		local Lost_Territories = {}
		local LatestTurn = game.ServerGame.LatestTurnStanding
		local Lost_Terr = order.From
			
		if result.IsSuccessful then 
			Lost_Terr = order.To
		end
		
		local player_lost_com = LatestTurn.Territories[Lost_Terr].OwnerPlayerID
		local index_order = 1
		for Terr_ID, territory in pairs(LatestTurn.Territories) do 
			if index_order > 30 then
				index_order = 1
				addNewOrder(WL.GameOrderEvent.Create(player_lost_com, '', {}, Lost_Territories))
			end
			
			if LatestTurn.Territories[Terr_ID].OwnerPlayerID == player_lost_com and Terr_ID ~= Lost_Terr then
				local new_terr_mod = WL.TerritoryModification.Create(Terr_ID)
				local new_commander_array = {}
				local number_of_comm = is_there_a_commander(Terr_ID, game)
				if number_of_comm > 0 then 
				for i=1, number_of_comm do
					new_commander_array[i] = WL.Commander.Create(player_lost_com)
				end
				end
				new_terr_mod.SetOwnerOpt = player_lost_com
				new_terr_mod.AddSpecialUnits = new_commander_array
				Lost_Territories[index_order] = new_terr_mod
			index_order = index_order + 1
			end
		end
		addNewOrder(WL.GameOrderEvent.Create(player_lost_com, '', {}, Lost_Territories))
		
	end
	end

end


function is_commander_killed(result)
	local Special_Unit_Count = 0
	
	if result.IsSuccessful then
		for _,Player_ID in pairs(result.DefendingArmiesKilled.SpecialUnits) do
			Special_Unit_Count = Special_Unit_Count + 1
		end
		return Special_Unit_Count ~= 0
	end
	
	if not result.IsSuccessful then
		for _,Player_ID in pairs(result.AttackingArmiesKilled.SpecialUnits) do
			Special_Unit_Count = Special_Unit_Count + 1
		end
		return Special_Unit_Count ~= 0
	end
	
end

function is_there_a_commander(Terr_ID, game)
	local Commander_counter = 0
	for _,_ in pairs(game.ServerGame.LatestTurnStanding.Territories[Terr_ID].NumArmies.SpecialUnits) do
		Commander_counter = Commander_counter + 1
	end
	
	return Commander_counter
end

function Server_AdvanceTurn_End(game, addNewOrder)

	local players_with_commanders = {}
	local LatestTurn = game.ServerGame.LatestTurnStanding
	local players_and_territories = {}
	
	for Terr_ID, territory in pairs(LatestTurn.Territories) do
		if LatestTurn.Territories[Terr_ID].IsNeutral == false then
			if players_with_commanders[LatestTurn.Territories[Terr_ID].OwnerPlayerID] == nil then
				players_with_commanders[LatestTurn.Territories[Terr_ID].OwnerPlayerID] = {}
				players_and_territories[LatestTurn.Territories[Terr_ID].OwnerPlayerID] = {}
			end
			local count = 0
			for a,b in pairs(LatestTurn.Territories[Terr_ID].NumArmies.SpecialUnits) do
				count = count + 1
			end
			if count > 0 then
				
				players_with_commanders[LatestTurn.Territories[Terr_ID].OwnerPlayerID][Terr_ID] = ''
			end

			players_and_territories[LatestTurn.Territories[Terr_ID].OwnerPlayerID][Terr_ID] = 'owned'
			
		end
		
	end
	
	for Player_ID, _ in pairs(players_and_territories) do
		local player_connected_territories = {}
		local counter = 1
		
		while counter > 0 do
			counter = 0
			player_connected_territories = players_with_commanders

			for Terr_ID, _ in pairs(player_connected_territories[Player_ID]) do
				for connection_ID, _ in pairs(game.Map.Territories[Terr_ID].ConnectedTo) do
					
					if LatestTurn.Territories[connection_ID].OwnerPlayerID == Player_ID and players_with_commanders[Player_ID][connection_ID] == nil then
						counter = counter + 1
						players_with_commanders[Player_ID][connection_ID] = ''
					end
				end	
			end
		end
	end

	for Player_ID, Terr_IDs in pairs(players_and_territories) do
		for Terr_ID, _ in pairs(Terr_IDs) do
			if players_with_commanders[Player_ID][Terr_ID] == nil then
				local new_order = WL.TerritoryModification.Create(Terr_ID)
				new_order.SetOwnerOpt = WL.PlayerID.Neutral
				addNewOrder(WL.GameOrderEvent.Create(Player_ID, game.Map.Territories[Terr_ID].Name .. ' was disconnect', {}, {new_order}))
			end	
		end	
	end
end