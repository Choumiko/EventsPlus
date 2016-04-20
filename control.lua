require "defines"
require "stdlib.log.logger"
require "stdlib.entity.entity"
require "Events"

MOD_NAME = "EventsPlus"

local Logger = Logger.new(MOD_NAME, "EventsPlus", true)

local function init_global()
  global = global or {}
  global.players = global.players or {}
  --setMetatables()
end

local function init_player(player)
  global.players[player.index] = global.players[player.index] or { opened = game.players[player.index].opened, active = false }
end

local function init_players()
  for i,player in pairs(game.players) do
    init_player(player)
  end
end

local function on_init()
  Events.generate()
  init_global()
  init_players()
end

local function on_load()
  Events.generate()
end

local function on_configuration_changed(data)
  if data.mod_changes[MOD_NAME] then
    local newVersion = data.mod_changes[MOD_NAME].new_version
    local oldVersion = data.mod_changes[MOD_NAME].old_version
    if oldVersion then

    end
    on_init()
  end
  --setMetatables()
end

local function on_player_created(event)
  init_player(game.players[event.player_index])
end

function mark_active(player)
  global.players[player.index].active = true
end

local function on_tick(event)
  if event.tick%10==9  then
    local status,err = pcall(
      function()
        for pi, player in pairs(game.players) do
          if player.connected then
            if player.opened ~= nil and not global.players[player.index].opened then
              Events.dispatch_player_opened(player)
            end
            if global.players[player.index].opened and player.opened == nil then
              Events.dispatch_player_closed(player)
            end
            if player.opened_self and not global.players[player.index].opened_self then
              Events.dispatch_player_opened_self(player)
            end
            if global.players[player.index].opened_self and not player.opened_self then
              Events.dispatch_player_closed_self(player)
            end
          end
        end
      end)
    if not status then
      log(err)
    end
  end
end

function on_player_opened(event)
  log("opened")
  log(serpent.line(event))
end

function on_player_closed(event)
  log("closed")
  log(serpent.line(event))
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_created, on_player_created)

script.on_event(defines.events.on_tick, on_tick)
--script.on_event(Events.get("on_player_opened"), on_player_opened)
--script.on_event(Events.get("on_player_closed"), on_player_closed)

local interface = {}

interface.getEvent = function(name)
  return Events.get(name)
end

--alternative for script.on_event/game.raise_event ??
interface.on_event = function(name, interface)
  Events.on_event(name, interface)
end

interface.rename_entity = function(entity, name)
  local old_name = Entity.get_backer_name(entity)
  if old_name and old_name ~= name then
    Entity.set_backer_name(entity,name)
    Events.dispatch_entity_renamed({},entity,old_name,name)  
    return true
  end
  return false
end

remote.add_interface("EventsPlus", interface)
