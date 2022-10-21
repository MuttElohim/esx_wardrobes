local wardrobes = {}

local wardrobeblips = {}

RegisterNetEvent('esx_wardrobes:UpdateWardrobes')
AddEventHandler('esx_wardrobes:UpdateWardrobes', function(_wardrobes)
	wardrobes = {}

	if Config.ShowBlips then
		for _,blip in pairs(wardrobeblips) do
			RemoveBlip(blip)
		end
		
		wardrobeblips = {}
	end

	CreateThread(function()
		for i, k in pairs(_wardrobes) do
			wardrobes[i] = vector3(k.x, k.y, k.z)
			
			if Config.ShowBlips then
				local blip = AddBlipForCoord(k.x, k.y, k.z)

				SetBlipSprite(blip, Config.BlipSprite)
				SetBlipColour(blip, Config.BlipColour)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName('STRING')
				AddTextComponentSubstringPlayerName(Config.BlipName)
				EndTextCommandSetBlipName(blip)
				
				wardrobeblips[i] = blip
			end
		end
	end)
end)

TriggerServerEvent('esx_wardrobes:GetWardrobes')

local subwardrobe = false

function OpenWardrobe(selector, data, origin, confirm, cancel, closed)	
	if selector == 'confirm' then
		elements = {
			{unselectable = true, icon = "fas fa-question", title = TranslateCap('confirm')},
			{value = "yes", title = TranslateCap('yes'), icon = "fas fa-check"},
			{value = "no", title = TranslateCap('no'), icon = "fas fa-xmark"},
		}
		local confirmed = false
		ESX.OpenContext("left", elements, function(menu, element) 
			if element.value == 'yes' then
				confirmed = true
				confirm()
			end
			ESX.CloseContext()
		end, function()
			if not confirmed and cancel then cancel() end
			OpenWardrobe(origin, data)
		end)
	elseif selector == 'outfit' then
		local elements = {
			{unselectable = true, icon = "fas fa-box-archive", title = data[2]},
			{value = 'dress', title = TranslateCap('title_dressoutfit'), icon = "fas fa-tshirt"},
			{value = 'delete', title = TranslateCap('title_deleteoutfit'), icon = "fas fa-trash"},
		}

		ESX.OpenContext("left", elements, function(menu, element)
			if element.value == 'dress' then
				TriggerEvent('skinchanger:getSkin', function(skin)
					ESX.TriggerServerCallback('esx_wardrobes:getPlayerOutfit', function(clothes)
						TriggerEvent('skinchanger:loadClothes', skin, clothes)

						OpenWardrobe('confirm', data, selector, function()
							TriggerEvent('skinchanger:getSkin', function(skin)
								TriggerEvent('esx_skin:setLastSkin', skin)
								TriggerServerEvent('esx_skin:save', skin)
								ESX.ShowNotification(TranslateCap('notify_dressedoutfit'), 2000, "success")
							end)
						end, function() TriggerEvent('skinchanger:loadSkin', skin) end)
					end, data[1])
				end)
			else
				TriggerEvent('skinchanger:getSkin', function(skin)
					ESX.TriggerServerCallback('esx_wardrobes:getPlayerOutfit', function(clothes)
						TriggerEvent('skinchanger:loadClothes', skin, clothes)

						OpenWardrobe('confirm', data, selector, function()
							ESX.TriggerServerCallback('esx_wardrobes:delPlayerOutfit', function(clothes)
								TriggerEvent('skinchanger:loadSkin', skin)
								ESX.ShowNotification(TranslateCap('notify_deletedoutfit'), 2000, "success")
								ESX.CloseContext()
							end, data[1])
						end, function() TriggerEvent('skinchanger:loadSkin', skin) end)
					end, data[1])
				end)
			end
		end, function()
			OpenWardrobe()
		end)
	else
		ESX.TriggerServerCallback('esx_wardrobes:getPlayerDressing', function(dressing)
			if #dressing == 0 then return ESX.ShowNotification(TranslateCap('notify_nothingtoshow'), 2000, "info") end
			
			local elements = {{unselectable = true, icon = "fas fa-box-archive", title = TranslateCap('wardrobe')}}

			for i=1, #dressing, 1 do
				elements[#elements + 1] = {
					title = dressing[i],
					value = i,
					icon = "fas fa-tshirt"
				}
			end

			elements[#elements + 1] = {value = 'delete', title = TranslateCap('title_deleteoutfits'), icon = "fas fa-trash"}

			ESX.OpenContext("left", elements, function(menu, element)
				if element.value == 'delete' then
					OpenWardrobe('confirm', data, selector, function() ESX.TriggerServerCallback('esx_wardrobes:delPlayerOutfits', function() ESX.ShowNotification(TranslateCap('notify_deletedoutfits'), 2000, "success") end) end)
				else
					OpenWardrobe('outfit', {element.value, element.title})
				end
			end, function() if subwardrobe then OpenWardrobeMenu() subwardrobe = false end end)
		end)
	end
end

function OpenWardrobeMenu(selector, data, origin, confirm)
	local elements = {}
	
	local cb = function() end
	
	local cb2 = false
	
	if selector == 'confirm' then
		elements = {
			{unselectable = true, icon = "fas fa-question", title = TranslateCap('confirm')},
			{value = "yes", title = TranslateCap('yes'), icon = "fas fa-check"},
			{value = "no", title = TranslateCap('no'), icon = "fas fa-xmark"},
		}
		cb = function(menu, element) 
			if element.value == 'yes' then
				confirm()
			end
			ESX.CloseContext()
		end
		cb2 = function()
			OpenWardrobeMenu(origin, data)
		end
	elseif selector == 'options' then
		elements = {
			{unselectable = true, icon = "fas fa-wrench", title = TranslateCap('title_wardrobeoptions')},
			{value = "tp", title = TranslateCap('title_tp'), icon = "fas fa-arrow-right"},
			{value = "delete", title = TranslateCap('title_delete'), icon = "fas fa-trash"},
		}
		cb = function(menu, element) 
			if element.value == 'tp' then
				TriggerServerEvent('esx_wardrobes:TPWardrobe', {x = wardrobes[data].x, y = wardrobes[data].y, z = wardrobes[data].z})
				ESX.ShowNotification(TranslateCap('notify_tpsuccess'), 2000, "success")
			elseif element.value == 'delete' then
				OpenWardrobeMenu('confirm', data, selector, function() ESX.TriggerServerCallback('esx_wardrobes:DeleteWardrobe', function() ESX.ShowNotification(TranslateCap('notify_deletedwardrobe'), 2000, "success") ESX.CloseContext() end, data) end)
			end
		end
		cb2 = function()
			Wait()
			if #wardrobes > 0 then
				OpenWardrobeMenu('list')
			else
				OpenWardrobeMenu()
			end
		end
	elseif selector == 'list' then
		elements = {{unselectable = true, icon = "fas fa-box-archive", title = TranslateCap('wardrobes')}}

		for i=1, #wardrobes, 1 do
			elements[#elements + 1] = {
				title = TranslateCap('wardrobe') .. ' ' .. i,
				value = i,
				icon = "fas fa-tshirt"
			}
		end

		cb = function(menu, element)
			OpenWardrobeMenu('options', element.value)
		end

		cb2 = function()
			OpenWardrobeMenu()
		end
	else
		elements = {
			{unselectable = true, icon = "fas fa-tshirt", title = TranslateCap('title_wardrobemenu')},
			{title = TranslateCap('title_create'), value = "create", icon = "fas fa-plus"},
			{title = TranslateCap('title_delete'), value = "delete", icon = "fas fa-trash"},
			{title = TranslateCap('title_deleteall'), value = "deleteall", icon = "fas fa-trash"},
			{title = TranslateCap('title_list'), value = "list", icon = "fas fa-box-archive"},
			{title = TranslateCap('wardrobe'), value = "wardrobe", icon = "fas fa-tshirt"},
		}

		cb = function(menu, element)
			if element.value == "create" then
				local position = GetEntityCoords(PlayerPedId())

				for _,w in pairs(wardrobes) do
					if #(w - position) < Config.WardrobeSeparation then return ESX.ShowNotification(TranslateCap('notify_toonear'), 2000, "error") end
				end
				
				OpenWardrobeMenu('confirm', data, selector, function() TriggerServerEvent('esx_wardrobes:CreateWardrobe', position) ESX.ShowNotification(TranslateCap('notify_createdwardrobe'), 2000, "success") end)
			elseif element.value == "delete" then
				local position = GetEntityCoords(PlayerPedId())

				for i,w in pairs(wardrobes) do
					if #(w - position) < Config.UsageDistance then return OpenWardrobeMenu('confirm', data, selector, function() ESX.TriggerServerCallback('esx_wardrobes:DeleteWardrobe', function() ESX.ShowNotification(TranslateCap('notify_deletedwardrobe'), 2000, "success") end, i) end) end
				end

				ESX.ShowNotification(TranslateCap('notify_notfound'), 2000, "error") 
			elseif element.value == "deleteall" then
				if #wardrobes > 0 then
					OpenWardrobeMenu('confirm', data, selector, function() TriggerServerEvent('esx_wardrobes:DeleteWardrobes') ESX.ShowNotification(TranslateCap('notify_deletedwardrobes'), 2000, "success") end)
				else
					ESX.ShowNotification(TranslateCap('notify_notfound'), 2000, "error") 
				end
			elseif element.value == "list" then
				if #wardrobes > 0 then
					OpenWardrobeMenu('list')
				else
					ESX.ShowNotification(TranslateCap('notify_nothingtoshow'), 2000, "info")
				end
			elseif element.value == "wardrobe" then
				subwardrobe = true
				OpenWardrobe()
			end
		end
	end

	ESX.OpenContext("left", elements, cb, cb2)
end

RegisterNetEvent('esx_wardrobes:OpenMenu')
AddEventHandler('esx_wardrobes:OpenMenu', function()
	OpenWardrobeMenu()
end)

Citizen.CreateThread(function()
	while true do
		local sleep = 1500
		local ped = PlayerPedId()
		local position = GetEntityCoords(ped)
		for _,w in pairs(wardrobes) do
			if #(w - position) < Config.DrawDistance then
				sleep = 0
				DrawMarker(Config.MarkerType, w.x, w.y, w.z-1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)
				if #(w - position) < Config.UsageDistance then
					ESX.ShowHelpNotification(TranslateCap('notify_wardrobe'))
					if IsControlJustReleased(0, 38) then
						OpenWardrobe()
					end
				end
			end
		end
		Wait(sleep)
	end
end)