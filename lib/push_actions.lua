grid_actions = {}

held_query = {}
for i = 1,3 do
  held_query[i] = 0
end

zilches = 
{ 
    [2] = {{},{},{}} 
  , [3] = {{},{},{}} 
  , [4] = {{},{},{}}
}
for i = 1,3 do
  zilches[4][i].held = 0
  for j = 1,4 do
    zilches[4][i][j] = false
  end
end
for i = 1,3 do
  zilches[3][i].held = 0
  for j = 1,3 do
    zilches[3][i][j] = false
  end
end
for i = 1,3 do
  zilches[2][i].held = 0
  for j = 1,3 do
    zilches[2][i][j] = false
  end
end

function grid_actions.init(x,y,z)
  
  if osc_communication == true then osc_communication = false end
  
  -- 64 grid / grid 64
  --if params:string("grid_size") == "64" then
  if grid_page_64 == 0 then
    
    local b = bank[bank_64]

    if x <=3 and y == 1 and z ==1  then
      bank_64 = x
      b = bank[x]
    end
    
    if grid_alt or b.alt_lock then
      if x == 8 and y == 4 and z == 1 then
        b.focus_hold = not b.focus_hold
        mc.mft_redraw(b[b.focus_hold and b.focus_pad or b.id],"all")
      end
    end

    --arc parameters
    if y == 2 then
      if x == 6 or x ==7 or x == 8 then
        if not grid_alt then
          if z == 1 then
            table.insert(arc_switcher[bank_64],x)
            held_query[bank_64] = #arc_switcher[bank_64]
          elseif z == 0 then
            held_query[bank_64] = held_query[bank_64] - 1
            if held_query[bank_64] == 0 then
              if #arc_switcher[bank_64] == 1 then
                arc_param[bank_64] = arc_switcher[bank_64][1] == 6 and 1 or (arc_switcher[bank_64][1] == 7 and 2 or 3)
              elseif #arc_switcher[bank_64] == 2 then
                total = arc_switcher[bank_64][1] + arc_switcher[bank_64][2]
                if total == 13 then
                  arc_param[bank_64] = 5
                elseif total == 15 then
                  arc_param[bank_64] = 6
                end
              elseif #arc_switcher[bank_64] == 3 then
                arc_param[bank_64] = 4
              elseif #arc_switcher[bank_64] > 3 then
                arc_switcher[bank_64] = {}
              end
              arc_switcher[bank_64] = {}
            end
          end
        end
      end
    end
    
    --arc recorders
    if x == 8 and y == 3 and z == 0 then
      local current = bank_64
      local a_p; -- this will index the arc encoder recorders
      if arc_param[current] == 1 or arc_param[current] == 2 or arc_param[current] == 3 then
        a_p = 1
      else
        a_p = arc_param[current] - 2
      end
      if grid_alt then
        arc_pat[current][a_p]:rec_stop()
        arc_pat[current][a_p]:stop()
        arc_pat[current][a_p]:clear()
      elseif arc_pat[current][a_p].rec == 1 then
        arc_pat[current][a_p]:rec_stop()
        arc_pat[current][a_p]:start()
      elseif arc_pat[current][a_p].count == 0 then
        arc_pat[current][a_p]:rec_start()
      elseif arc_pat[current][a_p].play == 1 then
        arc_pat[current][a_p]:stop()
      else
        arc_pat[current][a_p]:start()
      end
    end
    
    if z == 1 and x <= 4 and y >= 4 and y <= 7 then
      if b.focus_hold == false then
        if not grid_alt then
          selected[bank_64].x = (y-3)+(5*(bank_64-1))
          selected[bank_64].y = 9-x
          selected[bank_64].id = (4*(y-4))+x
          b.id = selected[bank_64].id
          which_bank = bank_64
          pad_clipboard = nil
          if b.quantize_press == 0 then
            if arp[bank_64].enabled and grid_pat[bank_64].rec == 0 and not arp[bank_64].pause then
              if arp[bank_64].down == 0 and params:string("arp_"..bank_64.."_hold_style") == "last pressed" then
                for j = #arp[bank_64].notes,1,-1 do
                  table.remove(arp[bank_64].notes,j)
                end
              end
              arp[bank_64].time = b[b.id].arp_time
              arps.momentary(bank_64, b.id, "on")
              arp[bank_64].down = arp[bank_64].down + 1
            else
              if rytm.track[bank_64].k == 0 then
                cheat(bank_64, b.id)
              end
              grid_pattern_watch(bank_64)
            end
          else
            table.insert(quantize_events[bank_64],selected[bank_64].id)
          end
        else
          local released_pad = (4*(y-4))+x
          arps.momentary(i, released_pad, "off")
        end
      else
        if not grid_alt then
          b.focus_pad = (4*(y-4))+x
          mc.mft_redraw(b[b.focus_pad],"all")
        elseif grid_alt then
          if not pad_clipboard then
            pad_clipboard = {}
            b.focus_pad = (4*(y-4))+x
            pad_copy(pad_clipboard, b[b.focus_pad])
          else
            b.focus_pad = (4*(y-4))+x
            pad_copy(b[b.focus_pad], pad_clipboard)
            pad_clipboard = nil
          end
        end
      end
      if menu ~= 1 then screen_dirty = true end
    elseif z == 0 and x <= 4 and y >= 4 and y <= 7 then
      if not b.focus_hold then
        local released_pad = (4*(y-4))+x
        if b[released_pad].play_mode == "momentary" then
          softcut.rate(bank_64+1,0)
        end
        if (arp[bank_64].enabled and not arp[bank_64].hold) or (menu == 9 and not arp[bank_64].hold) then
          arps.momentary(bank_64, released_pad, "off")
          arp[bank_64].down = arp[bank_64].down - 1
        elseif (arp[bank_64].enabled and arp[bank_64].hold and not arp[bank_64].pause) or (menu == 9 and arp[bank_64].hold and not arp[bank_64].pause) then
          arp[bank_64].down = arp[bank_64].down - 1
        end
      end
    end
    
    -- zilchmo 3+4 handling
    -- if x == 4 or x == 5 or x == 9 or x == 10 or x == 14 or x == 15 then
    if y == 6 or y == 7 or y == 8 then
      if ((y == 6 and x >=7) or (y == 7 and x >= 6) or (y == 8 and x >= 5)) then
        local zilch_id = (y == 8 and 4 or (y == 7 and 3 or 2))
        local zmap = zilches[zilch_id]
        local k1 = bank_64
        local k2 = (zilch_id == 3 and x-5 or (zilch_id == 4 and x-4 or x-6))
        if z == 1 then
          zmap[k1][k2] = true
          zmap[k1].held = zmap[k1].held + 1
          zilch_leds[zilch_id][k1][k2] = 1
          grid_dirty = true
        elseif z == 0 then
          if zmap[k1].held > 0 then
            local coll = {}
            for j = 1,4 do
              if zmap[k1][j] == true then
                table.insert(coll,j)
              end
            end
            coll.con = table.concat(coll)
            local previous_rate = bank[k1][bank[k1].id].rate
            rightangleslice.init(zilch_id,k1,coll.con)
            if zilch_id == 4 then
              record_zilchmo_4(previous_rate,k1,4,coll.con)
            end
            for j = 1,4 do
              zmap[k1][j] = false
            end
          end
          zmap[k1].held = 0
          zilch_leds[zilch_id][k1][k2] = 0
          grid_dirty = true
          if menu ~= 1 then screen_dirty = true end
        end
      end
    end

    if z == 0 and x == 8 and y == 5 then
      local i = bank_64
      if grid_pat[i].quantize == 0 then -- still relevant
        if bank[i].alt_lock and not grid_alt then
          if grid_pat[i].play == 1 then
            grid_pat[i].overdub = grid_pat[i].overdub == 0 and 1 or 0
          end
        else
          if grid_alt then -- still relevant
            grid_pat[i]:rec_stop()
            grid_pat[i]:stop()
            --grid_pat[i].external_start = 0
            grid_pat[i].tightened_start = 0
            grid_pat[i]:clear()
            pattern_saver[i].load_slot = 0
          elseif grid_pat[i].rec == 1 then -- still relevant
            grid_pat[i]:rec_stop()
            midi_clock_linearize(i)
            if grid_pat[i].auto_snap == 1 then
              print("auto-snap")
              snap_to_bars(i,how_many_bars(i))
            end
            if grid_pat[i].mode ~= "quantized" then
              --grid_pat[i]:start()
              start_pattern(grid_pat[i])
            --TODO: CONFIRM THIS IS OK...
            elseif grid_pat[i].mode == "quantized" then
              start_pattern(grid_pat[i])
            end
            grid_pat[i].loop = 1
          elseif grid_pat[i].count == 0 then
            if grid_pat[i].playmode ~= 2 then
              grid_pat[i]:rec_start()
            --new!
            else
              grid_pat[i].rec_clock = clock.run(synced_record_start,grid_pat[i],i)
            end
            --/new!
          elseif grid_pat[i].play == 1 then
            --grid_pat[i]:stop()
            stop_pattern(grid_pat[i])
          else
            start_pattern(grid_pat[i])
          end
        end
      else
        if grid_alt then
          grid_pat[i]:rec_stop()
          grid_pat[i]:stop()
          grid_pat[i].tightened_start = 0
          grid_pat[i]:clear()
          pattern_saver[i].load_slot = 0
        else
          --table.insert(grid_pat_quantize_events[i],i)
          better_grid_pat_q_clock(i)
        end
      end
    end
    
    if x == 5 and y == 6 and z == 1 then
      grid_actions.toggle_pad_loop(bank_64)
    end
    
    if x == 1 and y == 8 then
      grid_alt = z == 1 and true or false
      arc_alt = z
      if menu ~= 1 then screen_dirty = true end
    end
    
    if x == 5 or x == 6 or x == 7 then
      if y == 4 then
        local which_pad = nil
        local current = bank_64
        if z == 1 then
          if not bank[current].alt_lock and not grid_alt then
            if bank[current].focus_hold == false then
              jump_clip(current, bank[current].id, x-4)
            else
              jump_clip(current, bank[current].focus_pad, x-4)
            end
          elseif bank[current].alt_lock or grid_alt then
            for j = 1,16 do
              jump_clip(current, j, x-4)
            end
          end
        end
        if z == 0 then
          if menu ~= 1 then screen_dirty = true end
          if bank[current].focus_hold == false then
            if params:string("preview_clip_change") == "yes" or bank[current][bank[current].id].loop then
              cheat(current,bank[current].id)
            end
          end
        end
      end
    end

    if (y == 5 and (x == 5 or x == 6)) and z == 1 then
      local which_pad = nil
      local current = bank_64
      
      if not bank[current].alt_lock and not grid_alt then
        local target = bank[current].focus_hold == false and bank[current][bank[current].id] or bank[current][bank[current].focus_pad]
        local old_mode = target.mode
        target.mode = x-4
        if old_mode ~= target.mode then
          change_mode(target, old_mode)
        end

      elseif bank[current].alt_lock or grid_alt then
        for k = 1,16 do
          local old_mode = bank[current][k].mode
          bank[current][k].mode = x-4
          if old_mode ~= bank[current][k].mode then
            change_mode(bank[current][k], old_mode)
          end
        end
      end

      if bank[current].focus_hold == false then
        which_pad = bank[current].id
      else
        which_pad = bank[current].focus_pad
      end


      if bank[current].focus_hold == false then
        if params:string("preview_clip_change") == "yes" then
          cheat(current,bank[current].id)
        end
      end

    end
    
    if y == 2 and x <= 3 and z == 1 then
      if rec.focus ~= x then
        rec.focus = x
      else
        toggle_buffer(x)
        if grid_alt then
          buff_flush()
        end
      end
    end
    
    if y == 8 and x == 4 then
      if not grid_alt then
        bank[bank_64].alt_lock = z == 1 and true or false
      else
        if z == 1 then
          bank[bank_64].alt_lock = not bank[bank_64].alt_lock
        end
      end
    end
    
    if y == 6 and x == 6 and z == 1 then
      if not bank[bank_64].alt_lock and not grid_alt then
        grid_actions.arp_handler(bank_64)
      else
        grid_actions.kill_arp(bank_64)
      end
    end

    if y == 7 and x == 5 and z == 1 then
      local i = bank_64
      if bank[i].alt_lock or grid_alt then
        if not bank[i].focus_hold then
          for j = 1,16 do
            bank[i][j].rate = 1
            if bank[i][j].fifth == true then
              bank[i][j].fifth = false
            end
          end
          softcut.rate(i+1,1*bank[i][bank[i].id].offset)
        else
          bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
          for j = 1,16 do
            bank[i][j].crow_pad_execute = bank[i][bank[i].focus_pad].crow_pad_execute
          end
        end
      else
        if bank[i].focus_hold then
          bank[i][bank[i].focus_pad].crow_pad_execute = (bank[i][bank[i].focus_pad].crow_pad_execute + 1)%2
        end
      end
      screen_dirty = true
    end

    if y == 5 and x == 7 and z == 1 and (grid_alt or bank[bank_64].alt_lock) then
      random_grid_pat(bank_64,3)
    end

    if x == 8 and y == 1 and z == 1 then
      grid_page_64 = 1
    end

  elseif grid_page_64 == 1 then

    if x == 3 or x == 6 then
      if y <= 2 and z == 1 then
        local changes = {"double", "halve", "sync"}
        del.change_duration(x == 3 and 1 or 2, x == 3 and 2 or 1, changes[y])
      elseif y == 3 and z == 1 then
        del.quick_action(x == 3 and 1 or 2, "reverse")
      elseif y >= 4 and y <= 8 then
        if z == 1 then
          del.set_value(x == 3 and 1 or 2, math.abs(3-y), "level")
        end
      -- elseif y == 9 then
      --   del.quick_action(x == 3 and 1 or 2,"level_mute",z)
      end
    elseif x == 4 or x == 5 then
      if y >= 4 and y <= 8 then
        if z == 1 then
          del.set_value(x == 4 and 1 or 2, math.abs(3-y), "feedback")
        end
      elseif y == 1 and z == 1 then
        del.change_rate(x == 4 and 1 or 2, "double")
      elseif y == 2 and z == 1 then
        del.change_rate(x == 4 and 1 or 2, "halve")
      elseif y == 3 then
        del.change_rate(x == 4 and 1 or 2,z == 1 and "wobble" or "restore")
      -- elseif y == 9 then
      --   if grid_alt then
      --     del.quick_action(6-y, "clear")
      --   end
      --   del.quick_action(6-y,"feedback_mute",z)
      end
    elseif x == 1 or x == 8 then

    elseif x == 2 or x == 7 then
      if y == 8 then
        del.quick_action(x == 2 and 1 or 2,"feedback_mute",z)
      elseif y == 7 then
        del.quick_action(x == 2 and 1 or 2,"level_mute",z)
      elseif (y == 1 or y == 2 or y == 3) and z == 1 then
        delay_grid.bank = y
        local current_level = x == 2 and bank[delay_grid.bank][bank[delay_grid.bank].id].left_delay_level or bank[delay_grid.bank][bank[delay_grid.bank].id].right_delay_level
        del.set_value(x == 2 and 1 or 2, current_level > 0 and 5 or 1,"send all")
      elseif y == 4 and z == 1 then
        params:set("delay "..(x == 2 and "L:" or "R:").." external input", params:get("delay "..(x == 2 and "L:" or "R:").." external input") > 0 and 0 or 1)
      end
      -- if x >= 10 and x <=14 then
      --   if z == 1 then
      --     del.set_value(y == 8 and 1 or 2,x-9,grid_alt == true and "send all" or "send")
      --   end
      -- elseif x == 15 then
      --   del.quick_action(y == 8 and 1 or 2,"send_mute",z)
      -- end
    end

    if x == 1 or x == 8 then
      if y >= 3 and y <= 7 then
        if z == 1 then
          local bundle = (y-2)
          local target = x == 1 and 1 or 2
          local saved_already = delay_bundle[target][bundle].saved
          if not saved_already then
            delay[target].saver_active = true
            clock.run(del.build_bundle,target,bundle)
          elseif saved_already then
            -- if grid.alt_delay then
            if grid_alt then
              del.clear_bundle(target,bundle)
            else
              del.restore_bundle(target,bundle)
              delay[target].selected_bundle = bundle
            end
          end
        elseif z == 0 then
          delay[x<=2 and 1 or 2].saver_active = false
        end
      end
    end

    if x == 1 and y == 8 then
      grid_alt = z == 1 and true or false
    end

    if x == 8 and y == 1 and z == 1 then
      grid_page_64 = 0
    end

  end
  grid_dirty = true
  
end

function grid_actions.arp_handler(i)
  if not arp[i].enabled then
    arp[i].enabled = true
  elseif not arp[i].hold then
    if #arp[i].notes > 0 then
      arp[i].hold = true
    else
      arp[i].enabled = false
    end
  else
    if #arp[i].notes > 0 then
      if arp[i].playing == true then
        -- arp[i].pause = true
        -- arp[i].playing = false
        arps.toggle("stop",i)
      else
        arps.toggle("start",i)
        -- local arp_start =
        -- {
        --   ["fwd"] = arp[i].start_point - 1
        -- , ["bkwd"] = arp[i].end_point + 1
        -- , ["pend"] = arp[i].start_point
        -- , ["rnd"] = arp[i].start_point - 1
        -- }
        -- arp[i].step = arp_start[arp[i].mode]
        -- arp[i].pause = false
        -- arp[i].playing = true
        -- if arp[i].mode == "pend" then
        --   arp_direction[i] = "negative"
        -- end
      end
    end
  end
end

function grid_actions.kill_arp(i)
  page.arp_page_sel = i
  arp[i].hold = false
  if not arp[i].hold then
    arps.clear(i)
  end
  arp[i].down = 0
  arp[i].enabled = false
end

function grid_actions.toggle_pad_loop(i)
  -- which_bank = i
  local which_pad = bank[i].focus_hold == true and bank[i].focus_pad or bank[i].id
  bank[i][which_pad].loop = not bank[i][which_pad].loop
  if bank[i].alt_lock or grid_alt then
    for j = 1,16 do
      bank[i][j].loop = bank[i][which_pad].loop
    end
  end
  if bank[i].focus_hold == false then
    softcut.loop(i+1,bank[i][which_pad].loop == true and 1 or 0)
  end
  if menu ~= 1 then screen_dirty = true end
end

return grid_actions