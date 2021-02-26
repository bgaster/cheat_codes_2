-- PAD mappings
-- Bottom left is (0,0) (nn 36)
-- Top Right is (7,7) (nn 99)

-- LCD button mappings
-- Top row: CC 102 - 109 mapped to 0 .. 7
-- Bottom row: CC 20 - 27 mapped to 8 .. 15

local PAD_BL_NOTE=36

local Push = {}
Push.__index = Push

Push.p = nil

Push.midi_signal_in = nil
Push.midi_signal_out = nil

Push.connected = false

Push.on_midi_event = function(data)
    if Push.p ~= nil then    
        msg = midi.to_msg(data)
        if Push.p.key ~= nil then
            -- TODO: we could simply return velocity here is make it a bit
            --       more flexiable  
            if msg.type == 'note_on' then
                x, y = note_to_index(msg.note)
                Push.p.key(x,y,1)
            end
            if msg.type == 'note_off' then
                x, y = note_to_index(msg.note)
                Push.p.key(x,y,0)
            end
        end 

        if msg.type == 'cc' and Push.p.enc ~= nil and Push.p.button ~= nil then
            -- left most two encoders, numbered 0 and 2
            if msg.cc == 14 or msg.cc == 15 then
                if msg.val == 127 then
                    Push.p.enc(msg.cc - 14, -1)
                else
                    Push.p.enc(msg.cc - 14, 1)
                end
            -- remaining encoders, numbered 3, 4, .. 10
            elseif msg.cc >= 71 and msg.cc <= 79 then
                if msg.val == 127 then
                    Push.p.enc(msg.cc - 69, -1)
                else
                    Push.p.enc(msg.cc - 69, 1)
                end
            elseif msg.cc >= 102 and msg.cc <= 109 then
                if msg.val == 127 then
                    Push.p.button(msg.cc - 102, 1)
                else
                    Push.p.button(msg.cc - 102, 0)
                end
            elseif msg.cc >= 20 and msg.cc <= 27 then
                if msg.val == 127 then
                    Push.p.button(msg.cc - 12, 1)
                else
                    Push.p.button(msg.cc - 12, 0)
                end
            end
        end
    end
end

function Push.new()
    local p = setmetatable({}, Push)

    p.RGB_BLACK = 0
    p.RGB_WHITE = 122
    p.RGB_LIGHT_GRAY = 123
    p.RGB_DARK_GRAY = 124
    p.RGB_BLUE  = 125
    p.RGB_GREEN  = 126 
    p.RGB_RED = 127

    p.key = nil
    p.enc = nil
    p.button = nil

    p.device = true

    return p
end

--- create device, returns object with handler and send.
-- @static
function Push.connect()
    local p = Push.new()

    for id,y in pairs(midi.vports) do
        if y.name == "Ableton Push 2 1" then
            Push.midi_signal_in = midi.connect(id)
            Push.midi_signal_in.event = Push.on_midi_event
            Push.midi_signal_out = midi.connect(id)
            Push.connected = true
        end
    end

    Push.p = p

    return p
end

--- set state of single LED pad on this Push device.
-- @tparam integer x : column index (1-based!)
-- @tparam integer y : row index (1-based!)
-- @tparam integer color : LED Color
function Push:led(x,y,color)
    --print(color)
    y = math.abs(y-8)
  
    note = PAD_BL_NOTE + (x-1) + (y)*8
    data = {0x90, note, color}
    -- if color == 0 then
    --     data = {0x90, note,self.RGB_BLACK}
    --     --Push.midi_signal_out:send(data)
    -- elseif color == 4 then
    --     data = {0x90, note,self.RGB_DARK_GRAY}
    --     --Push.midi_signal_out:send(data)
    -- elseif color == 8 then
    --     data = {0x90, note,self.RGB_LIGHT_GRAY} 
    -- elseif color == 12 then
    --     data = {0x90, note,self.RGB_BLUE}
    -- else
    --     data = {0x90, note, self.RGB_WHITE}
    -- end
    Push.midi_signal_out:send(data)
end

function Push:handle_event(data)
    Push.on_midi_event(data)
end

function Push:refresh()
end

function Push:rotation(val)
end

function Push:all(color)
    for x=0, 7 do
        for y=0, 7 do
            note = PAD_BL_NOTE + x + y*8
            data = {0x90, note, color}
            Push.midi_signal_out:send(data)
        end
    end
end

--- set state of single LED button on this Push device.
-- @tparam integer id : button index
--      Top row: id is one of 0 .. 7
--      Bottom row: id is one of 8 .. 15
-- @tparam integer color : LED Color
function Push:set_button(id,color)
    if id >= 8 and id <= 15 then
        data = {0xb0, id + 12, color}
    else 
        data = {0xb0, id + 102, color}
    end
    
    Push.midi_signal_out:send(data)
end

function Push:is_connected() 
    return Push.connected
end

function note_to_index(note)
    local r = note - PAD_BL_NOTE
    x = math.fmod(r,8) + 1
    y = (r // 8)

    y = math.abs(y-7)

    --print(x,y+1)

    return x, y+1
end

-- function init()
--     connect()

--     for i=99, 36, -1 do
--         pads[i] = RGB_LIGHT_GRAY
--         x = {0x90, i, pads[i]}
--         midi_signal_out:send(x)
--     end

--     print('init')

--     redraw()
-- end
  
-- function connect()
--     for id,y in pairs(midi.vports) do
--         if y.name == "Ableton Push 2 1" then
--             midi_signal_in = midi.connect(id)
--             midi_signal_in.event = on_midi_event
--             midi_signal_out = midi.connect(id)
--         end
--     end
--     -- midi_signal_in = midi.connect(1)
--     -- midi_signal_in.event = on_midi_event
--     -- midi_signal_out = midi.connect(2)
-- end

-- function on_midi_event(data)
--     msg = midi.to_msg(data)
    
--     if msg.type == 'note_on' then
--         print(msg.note)
--         if pads[msg.note] == RGB_LIGHT_GRAY then
--             pads[msg.note] = RGB_RED
--         else
--             pads[msg.note] = RGB_LIGHT_GRAY
--         end
--         x = {0x90, msg.note, pads[msg.note]}
--         midi_signal_out:send(x)
--     end
--     -- print(msg)
-- end

-- -- Interactions

-- function key(id,state)
--     print('key',id,state)
--     if id == 2 then
--         x = {0x90, 0x24,0x7E}
--         midi_signal_out:send(x)
--     end
--     if id == 3 then
--         x = {0x90, 0x24, 0}
--         midi_signal_out:send(x)
--     end

-- end

-- function enc(id,delta)
-- print('enc',id,delta)
-- end

-- -- Render

-- function redraw()
--     for i,v in pairs(midi.devices) do
--         tab.print(midi.devices[i])
--         print("-")
--       end
-- screen.clear()
-- screen.update()
-- end
  
--   -- Executed on script close/change/quit
  
--   function cleanup()
--     print('cleanup')
--   end

return Push