local Timeouts, OpenedMenus, MenuType, isThreadActive = {}, {}, 'dialog', false

local function openMenuDialog(namespace, name, data)
	for i = 1, #Timeouts, 1 do
		Framework.ClearTimeout(Timeouts[i])
	end

	OpenedMenus[namespace .. '_' .. name] = true

	if Framework.Table.Length(OpenedMenus) > 0 then
		RunThread()
	else
		isThreadActive = false
	end

	SendNUIMessage({
		action = 'openMenuDialog',
		namespace = namespace,
		name = name,
		data = data
	})

	local timeoutId = Framework.SetTimeout(200, function()
		SetNuiFocus(true, true)
	end)

	table.insert(Timeouts, timeoutId)
end

local function closeMenuDialog(namespace, name)
	OpenedMenus[namespace .. '_' .. name] = nil

	if Framework.Table.Length(OpenedMenus) > 0 then
		RunThread()
	else
		isThreadActive = false
		SetNuiFocus(false)
	end

	SendNUIMessage({
		action = 'closeMenuDialog',
		namespace = namespace,
		name = name,
	})

end

Framework.UI.Menu.RegisterType(MenuType, openMenuDialog, closeMenuDialog)

RegisterNUICallback('menu_dialog_submit', function(data, cb)
	local menu = Framework.UI.Menu.GetOpened(MenuType, data._namespace, data._name)
	local cancel = false

	if menu.submit then
		-- is the submitted data a number?
		if tonumber(data.value) then
			data.value = Framework.Math.Round(tonumber(data.value))

			-- check for negative value
			if tonumber(data.value) <= 0 then
				cancel = true
			end
		end

		data.value = Framework.Math.Trim(data.value)

		-- don't submit if the value is negative or if it's 0
		if cancel then
			Framework.ShowNotification('That input is not allowed!')
		else
			menu.submit(data, menu)
		end
	end
	cb('OK')
end)

RegisterNUICallback('menu_dialog_cancel', function(data, cb)
	local menu = Framework.UI.Menu.GetOpened(MenuType, data._namespace, data._name)

	if menu.cancel ~= nil then
		menu.cancel(data, menu)
	end
	cb('OK')
end)

RegisterNUICallback('menu_dialog_change', function(data, cb)
	local menu = Framework.UI.Menu.GetOpened(MenuType, data._namespace, data._name)

	if menu.change ~= nil then
		menu.change(data, menu)
	end
	cb('OK')
end)

function RunThread()
	if isThreadActive then return end
	isThreadActive = true
	CreateThread(function()
		while isThreadActive do
			DisableControlAction(0, 1,   true) -- LookLeftRight
			DisableControlAction(0, 2,   true) -- LookUpDown
			DisableControlAction(0, 142, true) -- MeleeAttackAlternate
			DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
			DisableControlAction(0, 12, true) -- WeaponWheelUpDown
			DisableControlAction(0, 14, true) -- WeaponWheelNext
			DisableControlAction(0, 15, true) -- WeaponWheelPrev
			DisableControlAction(0, 16, true) -- SelectNextWeapon
			DisableControlAction(0, 17, true) -- SelectPrevWeapon
			Wait(0)
		end
	end)
end