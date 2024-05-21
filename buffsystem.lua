local config = {
    actionId = 56501,
    storageBase = 880110,
    siObtieneLosBuffos = "Recibiste Mejoras de los Dioses.",
    mensajeDelJugador = "Me siento mucho mas fuerte!",
    efectoCuandoObtengaElBuffo = CONST_ME_MAGIC_GREEN,
    mensajeDeFallo = "tu ya tienes el buffo!",
    efectoDeFallo = CONST_ME_MAGIC_RED,
	storageNecesario = "Tu no tienes la quest completada o mision.", -- Mensaje de error
    skillQueObtendran = {
        { type = SKILL_SWORD, value = 3 },
        { type = SKILL_AXE, value = 3 },
        { type = SKILL_CLUB, value = 3 },
        { type = SKILL_DISTANCE, value = 3 },
        { type = SKILL_SHIELD, value = 3 },
        { type = SKILL_FIST, value = 3 },
        { type = SKILL_FISHING, value = 3 },
        { type = SKILL_CRITICAL_HIT_CHANCE, value = 3 },
        { type = SKILL_CRITICALHITAMOUNT, value = 3 },
        { type = SKILL_LIFELEECHCHANCE, value = 3 },
        { type = SKILL_LIFELEECHAMOUNT, value = 3 },
        { type = SKILL_MANALEECHCHANCE, value = 3 },
        { type = SKILL_MANALEECHAMOUNT, value = 3 },
        { type = STAT_MAXHITPOINTS, value = 500 },
        { type = STAT_MAXMANAPOINTS, value = 500 },
        { type = STAT_MAGICPOINTS, value = 3 },
    }
}

local conditions = {
    CONDITION_PARAM_SKILL_SWORD,
    CONDITION_PARAM_SKILL_AXE,
    CONDITION_PARAM_SKILL_CLUB,
    CONDITION_PARAM_SKILL_DISTANCE,
    CONDITION_PARAM_SKILL_SHIELD,
    CONDITION_PARAM_SKILL_FIST,
    CONDITION_PARAM_SKILL_FISHING,
    CONDITION_PARAM_SKILL_CRITICAL_HIT_CHANCE,
    CONDITION_PARAM_SKILL_CRITICAL_HIT_DAMAGE,
    CONDITION_PARAM_SKILL_LIFE_LEECH_CHANCE,
    CONDITION_PARAM_SKILL_LIFE_LEECH_AMOUNT,
    CONDITION_PARAM_SKILL_MANA_LEECH_CHANCE,
    CONDITION_PARAM_SKILL_MANA_LEECH_AMOUNT,
    CONDITION_PARAM_STAT_MAXHITPOINTS,
    CONDITION_PARAM_STAT_MAXMANAPOINTS,
    CONDITION_PARAM_STAT_MAGICPOINTS
}

local function getCustomSkillLevel(player, index)
    return player:getStorageValue(config.storageBase + index) or 0
end

local function setCustomSkillLevel(player, index, skillId, value)
    player:setStorageValue(config.storageBase + index, value)
    local conditionParam = conditions[index]
    if not conditionParam then
        print("Error: Invalid condition parameter!")
        return
    end
    if not value or value == 0 then
        local condition = player:getCondition(CONDITION_ATTRIBUTES, CONDITIONID_DEFAULT, config.storageBase + index)
        if not condition then
            print("Removing condition for index " .. index)
            return
        end
        return player:removeCondition(condition)
    end
    local condition = Condition(CONDITION_ATTRIBUTES, CONDITIONID_DEFAULT)
    condition:setParameter(CONDITION_PARAM_TICKS, -1)
    condition:setParameter(CONDITION_PARAM_SUBID, config.storageBase + index)
    condition:setParameter(conditionParam, value)
    print("Adding condition for index " .. index)
    return player:addCondition(condition)
end

local function removeDarkEnergyConditions(player)
    for index, _ in ipairs(config.skillQueObtendran) do
        player:removeCondition(CONDITION_ATTRIBUTES, CONDITIONID_DEFAULT, config.storageBase + index)
    end
    player:setStorageValue(config.storageBase, 0)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Tus beneficios de energía oscura han sido removidos.")
end

local function addPlayerDarkEnergy(player, fromPosition)
    if player:getStorageValue(config.storageBase) ~= 1 then
        player:setStorageValue(config.storageBase, 1)
        for index, reward in ipairs(config.skillQueObtendran) do
            setCustomSkillLevel(player, index, reward.type, reward.value)
        end
        player:getPosition():sendMagicEffect(config.efectoCuandoObtengaElBuffo)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, config.siObtieneLosBuffos)
        player:say(config.mensajeDelJugador, TALKTYPE_MONSTER_SAY)
    else
        player:teleportTo(fromPosition)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, config.mensajeDeFallo)
        player:getPosition():sendMagicEffect(config.efectoDeFallo)
    end
end

local moveevent = MoveEvent()

function moveevent.onStepIn(creature, item, pos, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return true
    end

    print("El jugador piso el SQM")

--- AQUI PUEDES DESCOMENTAR TODO ESTO PARA QUE LOS JUGADORES TENGAN QUE REALIZAR UNA QUEST PARA USAR EL SQM.

  --  local requiredStorageValue = 40067 --- aqui el storage o nombre de la quest que deben realizar.
   -- if player:getStorageValue(requiredStorageValue) ~= 1 then
    --    print("El jugador no puede PISAR debido al valor de almacenamiento NO LO TIENE")
--		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, config.storageNecesario) -- Enviar mensaje de error
 --       return false
 --   end

 --   print("El jugador puede pisar el SQM SI TIENE EL STORAGE")
    addPlayerDarkEnergy(player, fromPosition)
	print("el jugador obtubo el beneficio.")
    return true
end

moveevent:aid(config.actionId)
moveevent:register()

local creatureEvent = CreatureEvent("DarkEnergyLoad")

function creatureEvent.onLogin(player)
    if player:getStorageValue(config.storageBase) == 1 then
        for index, reward in ipairs(config.skillQueObtendran) do
            local value = getCustomSkillLevel(player, index)
            if value ~= 0 then
                setCustomSkillLevel(player, index, reward.type, value)
            end
        end
    end
    return true
end

creatureEvent:register()

local logoutEvent = CreatureEvent("DarkEnergyLogout")

function logoutEvent.onLogout(player)
    removeDarkEnergyConditions(player)
    return true
end

logoutEvent:register()

local deathEvent = CreatureEvent("DarkEnergyDeath")

function deathEvent.onDeath(player, corpse, killer, mostDamageKiller, lastHitUnjustified)
    removeDarkEnergyConditions(player)
    return true
end

deathEvent:register()



-- tambien debes registrar en login_events.lua lo siguiente

-- DarkEnergyLoad,
-- DarkEnergyLogout,
-- DarkEnergyDeath,

-- tambien puedes quitar todos los "print" ya que los use para verificar que todo funcione bien.
