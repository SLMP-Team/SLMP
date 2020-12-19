local sync = {}

function get_dist(x1, y1, z1, x2, y2, z2)
  return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

function update_stream(client)
  local pointer = clients.list[client]
  if pointer == 0 then return end
  local x, y, z = pointer.pos[1], pointer.pos[2], pointer.pos[3]

  -- PLAYERS STREAMING

  clients.foreach(function(index, value)
    if client ~= index then

      local pX, pY, pZ = value.pos[1], value.pos[2], value.pos[3]
      local distance = get_dist(x, y, z, pX, pY, pZ)

      -- if player streamed for us
      if clients.is_streamed(index, client) then

        if distance > 300.0 or value.world ~= pointer.world or value.gamestate == 2 then

          -- we need to unstream player
          -- first of all we should delete player from table

          for i = #pointer.stream.players, 1, -1 do
            if pointer.stream.players[i] == index then
              -- delete player from our stream
              table.remove(pointer.stream.players, i)
              break
            end
          end

          -- now we should notify players about it

          local data = bstream.new()
          data:write(BS_UINT16, index)
          rpc.send(rpc["list"]["ID_STREAMED_OUT"],
          data, pointer.address, pointer.port)

          -- good, now players unstreamed for each other
          inner_function("onPlayerStreamOut", true, true, index, client)

        end

      else -- if player not streamed for us

        if distance <= 300.0 and value.world == pointer.world and value.gamestate ~= 2 then

          -- we need to stream players for each other
          table.insert(pointer.stream.players, index)

          -- perfect, now we will notify players

          local data = bstream.new()
          data:write(BS_UINT16, index)
          data:write(BS_UINT16, value.skin)
          data:write(BS_FLOAT, value.pos[1])
          data:write(BS_FLOAT, value.pos[2])
          data:write(BS_FLOAT, value.pos[3])
          rpc.send(rpc["list"]["ID_STREAMED_IN"],
          data, pointer.address, pointer.port)

          -- nice, now players streamed for each other
          inner_function("onPlayerStreamIn", true, true, index, client)

        end

      end

    end
  end)

  -- OBJECTS STREAMING

  objects.foreach(function(index, value)
    local pX, pY, pZ = value.pos[1], value.pos[2], value.pos[3]
    local distance = get_dist(x, y, z, pX, pY, pZ)

    -- if object streamed for us
    if clients.is_streamed_object(index, client) then

      if distance > value.stream_dist or (value.world ~= -1 and value.world ~= pointer.world)
      or (value.interior ~= -1 and value.interior ~= pointer.interior) then

        -- we need to unstream object

        for i = #pointer.stream.objects, 1, -1 do
          if pointer.stream.objects[i] == index then
            table.remove(pointer.stream.objects, i)
            break
          end
        end

        -- notify player about it

        local data = bstream.new()
        data:write(BS_UINT32, index)
        rpc.send(rpc["list"]["ID_OBJECT_DELETE"],
        data, pointer.address, pointer.port)

      end

    -- if object unstreamed for us
    else

      if distance <= value.stream_dist and (value.world == -1 or value.world == pointer.world)
      and (value.interior == -1 or value.interior == pointer.interior) then

        -- we need to stream object

        table.insert(pointer.stream.objects, index)

        -- perfect, now we will notify players

        local data = bstream.new()
        data:write(BS_UINT32, index)
        data:write(BS_UINT32, value.modelid)
        data:write(BS_FLOAT, value.pos[1])
        data:write(BS_FLOAT, value.pos[2])
        data:write(BS_FLOAT, value.pos[3])
        data:write(BS_FLOAT, value.rot[1])
        data:write(BS_FLOAT, value.rot[2])
        data:write(BS_FLOAT, value.rot[3])
        rpc.send(rpc["list"]["ID_OBJECT_CREATE"],
        data, pointer.address, pointer.port)

      end

    end

  end)

end

function sync.restream(bs, address, port)
  local client = clients.by_address(address, port)
  if client == 0 then return end update_stream(client)
end

function sync.spectating(bs, address, port)
  local client = clients.by_address(address, port)
  if client == 0 then return end
  local ptr = clients.list[client]
  if ptr.gamestate ~= 2 then return end
  local keys = bs:read(BS_UINT32)
  local x, y, z = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)

  ptr.pos = {x, y, z}

  if os.time() - ptr.last_sync >= 1 then
    ptr.last_sync = os.time()
    update_stream(client)
  end

  inner_function("onPlayerUpdate", true, true, client)
  if ptr.keys ~= keys then
    inner_function("onPlayerKeyStateChange",
    true, true, client, ptr.keys, keys)
    ptr.keys = keys
  end
end

function sync.onfoot(bs, address, port)
  local client = clients.by_address(address, port)
  if client == 0 then return end
  local ptr = clients.list[client]
  if ptr.gamestate ~= 1 then return end

  local lrKey = bs:read(BS_INT16)
  local udKey = bs:read(BS_INT16)
  local keys = bs:read(BS_UINT32)
  local x, y, z = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
  local qx, qy, qz, qw = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
  local health, armour = bs:read(BS_UINT8), bs:read(BS_UINT8)
  local is_duck, is_walk = bs:read(BS_BOOLEAN), bs:read(BS_BOOLEAN)
  local weap_id, action_id = bs:read(BS_UINT8), bs:read(BS_UINT8)
  local vx, vy, vz = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
  local rot = bs:read(BS_FLOAT)

  ptr.pos = {x, y, z}
  ptr.quat = {qx, qy, qz}
  ptr.vec = {vx, vy, vz}
  ptr.rot = rot
  ptr.health = health
  ptr.armour = armour

  local data = bstream.new(bs.bytes); data.write_ptr = 1
  data:write(BS_UINT16, client); data:write(BS_UINT16, ptr.skin)

  if os.time() - ptr.last_sync >= 1 then
    ptr.last_sync = os.time()
    update_stream(client)
  end

  clients.foreach(function(i, v)
    if i ~= client and clients.is_streamed(client, i) then
      packets.send(packets["list"]["ID_ONFOOT_SYNC"], data, v.address, v.port)
    end
  end)

  inner_function("onPlayerUpdate", true, true, client)
  if ptr.keys ~= keys then
    inner_function("onPlayerKeyStateChange",
    true, true, client, ptr.keys, keys)
    ptr.keys = keys
  end
end

return sync