local wardrobes = json.decode(LoadResourceFile(GetCurrentResourceName(), 'server/wardrobes.txt'))

function UpdateWardrobes(player, cb)
	TriggerClientEvent('esx_wardrobes:UpdateWardrobes', player or -1, wardrobes)
	if cb then cb() end
end

RegisterNetEvent('esx_wardrobes:GetWardrobes')
RegisterServerEvent('esx_wardrobes:GetWardrobes', function()
	UpdateWardrobes(source)
end)

RegisterServerEvent('esx_wardrobes:CreateWardrobe')
AddEventHandler('esx_wardrobes:CreateWardrobe', function(position)
	table.insert(wardrobes, position)
	
	SaveResourceFile(GetCurrentResourceName(), 'server/wardrobes.txt', json.encode(wardrobes))
	
	UpdateWardrobes()
end)

ESX.RegisterServerCallback('esx_wardrobes:DeleteWardrobe', function(src, cb, position)
    table.remove(wardrobes, position)

	SaveResourceFile(GetCurrentResourceName(), 'server/wardrobes.txt', json.encode(wardrobes))
	
	UpdateWardrobes(false, cb)
end)

RegisterNetEvent('esx_wardrobes:DeleteWardrobes')
RegisterServerEvent('esx_wardrobes:DeleteWardrobes', function()
	wardrobes = {}
	SaveResourceFile(GetCurrentResourceName(), 'server/wardrobes.txt','{}')
	UpdateWardrobes()
end)

RegisterNetEvent('esx_wardrobes:TPWardrobe')
RegisterServerEvent('esx_wardrobes:TPWardrobe', function(wardrobe)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.setCoords(wardrobe)
end)

ESX.RegisterServerCallback('esx_wardrobes:getPlayerDressing', function(source, cb) -- esx_property:getPlayerDressing
  local xPlayer = ESX.GetPlayerFromId(source)

  TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
    local count = store.count('dressing')
    local labels = {}

    for i = 1, count, 1 do
      local entry = store.get('dressing', i)
      table.insert(labels, entry.label)
    end

    cb(labels)
  end)
end)

ESX.RegisterServerCallback('esx_wardrobes:getPlayerOutfit', function(source, cb, num) -- esx_property:getPlayerOutfit
  local xPlayer = ESX.GetPlayerFromId(source)

  TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
    local outfit = store.get('dressing', num)
    cb(outfit.skin)
  end)
end)

ESX.RegisterServerCallback('esx_wardrobes:delPlayerOutfit', function(source, cb, num)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
		local outfit = store.get('dressing', num)
		
		local dressing = store.get('dressing')

		for i, v in pairs(dressing) do if outfit.label == v.label then table.remove(dressing, i) break end end
		
		store.set('dressing', dressing)
		store.save()
		
		cb()
	end)
end)

ESX.RegisterServerCallback('esx_wardrobes:delPlayerOutfits', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
		store.set('dressing', {})
		store.save()
		cb()
	end)
end)

RegisterServerEvent('esx_wardrobes:saveOutfit') -- 'esx_clotheshop:saveOutfit
AddEventHandler('esx_wardrobes:saveOutfit', function(label, skin)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
		local dressing = store.get('dressing')

		if dressing == nil then
			dressing = {}
		end

		table.insert(dressing, {
			label = label,
			skin  = skin
		})

		store.set('dressing', dressing)
		store.save()
	end)
end)

ESX.RegisterCommand('wardrobesmenu', 'admin', function(xPlayer, args, showError)
	TriggerClientEvent('esx_wardrobes:OpenMenu', xPlayer.source)
end, false, {help = TranslateCap('command_openmenu')})