--- Events module
-- @module Events

Events = {}
Events.available = {on_player_closed = true, on_player_opened = true, on_entity_renamed = true}
Events.registered = {on_player_closed={}}
Events.__on_player_opened = false
Events.__on_player_closed = false
Events.__on_entity_renamed = false

Events.get = function(name)
  if Events["__"..name] == false then
    Events["__"..name] = script.generate_event_name()
    log("generated event: "..name.." with id: "..Events["__"..name])
  end
  return Events["__"..name]
end

Events.generate = function()
  for name, _ in pairs(Events.available) do
    Events.get(name)
  end
end

Events.dispatch_player_opened = function(player)
  global.players[player.index].opened = player.opened
  global.players[player.index].opened_name = Entity.get_backer_name(player.opened)
  game.raise_event( Events.get("on_player_opened"), { entity = player.opened, player_index = player.index } )
end

Events.dispatch_player_closed = function(player)
  local opened = global.players[player.index].opened.valid and global.players[player.index].opened or {valid=false}
  if opened.valid then
    local backer_name = Entity.get_backer_name(opened)
    if backer_name and backer_name ~= global.players[player.index].opened_name then
      Events.dispatch_entity_renamed(player, opened, global.players[player.index].opened_name, opened.backer_name)
      global.players[player.index].opened_name = nil
    end
  end
  game.raise_event( Events.get("on_player_closed"), { entity = opened, player_index = player.index } )
  global.players[player.index].opened = nil
end

Events.dispatch_entity_renamed = function(player, entity, old_name, new_name)
  game.raise_event( Events.get("on_entity_renamed"), { entity = entity, player_index = player.index, old_name = old_name, new_name = new_name } )
end

--alternative for script.on_event/game.raise_event ??
Events.on_event = function(name, interface)
  if interface.callback then
    table.insert(Events.registered[name], interface)
  else
    local remove = false
    for i=#Events.registered[name],1,-1 do
      if interface.name == Events.registered[name][i].name then
        remove = i
      end
    end
    if remove then
      table.remove(Events.registered[name], remove)
    end
  end
end
