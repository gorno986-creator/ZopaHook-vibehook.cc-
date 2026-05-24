-- [[ Zopahook | Garry's Mod Premium Client ]] --

-- 1. Цветовая палитра Onetap v3 Style
local OTC_BG = Color( 34, 34, 38 )
local OTC_DARK = Color( 25, 25, 28 )
local OTC_ACCENT = Color( 235, 150, 65 )
local OTC_TEXT = Color( 220, 220, 220 )
local OTC_MUTED = Color( 120, 120, 125 )

-- Переменные конфигурации (Config)
local menuon = false
local cheatwindow = nil
local active_tab = "Visual"

-- Настройки функций (Visuals)
local esp_enabled = false
local esp_distance = 2000

-- Настройки Chams (Починенные)
local chams_enabled = false
local chams_mode = "Color"
local chams_color = Color(235, 150, 65)

-- Настройки Ghost Chams (Backtrack & Fake Lag)
local bt_chams_enabled = false
local bt_chams_color = Color(200, 200, 200)

local fl_chams_enabled = false
local fl_chams_color = Color(150, 150, 255)
local fl_pos = Vector(0, 0, 0)
local fl_ang = Angle(0, 0, 0)

-- Настройки Anti-Aim & Desync & Fake Lag
local aa_enabled = false
local aa_pitch_mode = "Down"
local aa_yaw_mode = "Static"
local aa_yaw_offset = 180
local aa_jitter_range = 45
local aa_spin_enabled = false
local aa_spin_speed = 15
local aa_hideshots = false

local desync_enabled = false
local desync_range = 58

local fakelag_enabled = false
local fakelag_limit = 14
local choke_count = 0

local tp_enabled = false
local tp_distance = 100

-- Настройки Rage / Aimbot & Backtrack
local aim_enabled = false
local aim_silent = true
local aim_fov = 180
local norecoil_enabled = true
local auto_shoot = false
local auto_stop = false

local backtrack_enabled = false
local backtrack_ticks = 12
local backtrack_records = {}

local hud_enabled = true

-- Настройки для BunnyHop
local bhop_enabled = true
local autostrafe_enabled = true

-- Изоляция углов обзора через прямой ввод мыши
local my_view = Angle(0, 0, 0)
local current_spin_yaw = 0
local jitter_side = false
local initialized = false

-- Надежные сгенерированные материалы для Chams
local mat_flat = CreateMaterial("Zopahook_FlatMat", "UnlitGeneric", { ["$basetexture"] = "color/white", ["$model"] = 1, ["$ignorez"] = 1 })
local mat_wire = Material("models/wireframe")
local mat_glow = CreateMaterial("Zopahook_GlowMat", "VertexLitGeneric", { ["$basetexture"] = "color/white", ["$additive"] = "1", ["$envmap"] = "models/effects/cube_white", ["$envmaptint"] = "[1 1 1]", ["$model"] = 1, ["$ignorez"] = 1 })
local mat_metal = CreateMaterial("Zopahook_MetalMat", "VertexLitGeneric", { ["$basetexture"] = "color/white", ["$envmap"] = "env_cubemap", ["$envmaptint"] = "[1 1 1]", ["$model"] = 1, ["$ignorez"] = 1 })

-- 2. Создание шрифтов
surface.CreateFont( "Zopahook_HUD_Font", { font = "Verdana", size = 12, weight = 600, antialias = true } )
surface.CreateFont( "OTC_Title", { font = "Verdana", size = 20, weight = 700, antialias = true } )
surface.CreateFont( "OTC_Tab", { font = "Verdana", size = 14, weight = 600, antialias = true } )
surface.CreateFont( "OTC_Text", { font = "Verdana", size = 12, weight = 500, antialias = true } )
surface.CreateFont( "ZopahookESP", { font = "Tahoma", size = 11, weight = 600, antialias = true } )

-- 3. Вспомогательные функции
local function CorrectMovement( cmd, old_angles )
local fmove = cmd:GetForwardMove()
local smove = cmd:GetSideMove()

local old_yaw = old_angles.y
if old_yaw < 0 then old_yaw = old_yaw + 360 end
    local new_yaw = cmd:GetViewAngles().y
    if new_yaw < 0 then new_yaw = new_yaw + 360 end

        local yaw_diff = new_yaw - old_yaw
        if yaw_diff < 0 then yaw_diff = yaw_diff + 360 end

            local rad = math.rad(yaw_diff)
            cmd:SetForwardMove( math.cos(rad) * fmove - math.sin(rad) * smove )
            cmd:SetSideMove( math.sin(rad) * fmove + math.cos(rad) * smove )
            end

            local function GetHeadPos(ent)
            if not IsValid(ent) then return Vector(0,0,0) end
                local head_bone = ent:LookupBone("ValveBiped.Bip01_Head1")
                if head_bone then
                    local matrix = ent:GetBoneMatrix(head_bone)
                    if matrix then return matrix:GetTranslation() end
                        end
                        return ent:LocalToWorld(ent:OBBCenter())
                        end

                        -- 4. Функция поиска цели для Аимбота + Backtrack
                        local function GetAimbotTarget( ply, eye_pos, eye_angles )
                        local best_target = nil
                        local best_fov = aim_fov
                        local targets = {}
                        table.Add( targets, player.GetAll() )
                        table.Add( targets, ents.FindByClass("npc_*") )
                        table.Add( targets, ents.FindByClass("nextbot_*") )

                        for _, ent in ipairs( targets ) do
                            if not IsValid(ent) or ent == ply then continue end

                                local hp = ent:IsPlayer() and ent:Health() or (ent.Health and ent:Health() or 1)
                                if hp <= 0 then continue end
                                    if ent:IsPlayer() and (not ent:Alive() or ent:Team() == TEAM_SPECTATOR) then continue end

                                        if backtrack_enabled and backtrack_records[ent] then
                                            for _, rec in ipairs(backtrack_records[ent]) do
                                                local tr = util.TraceLine({ start = eye_pos, endpos = rec.pos, filter = {ply, ent}, mask = MASK_SHOT })
                                                if tr.Fraction < 1 then continue end

                                                    local fWD = eye_angles:Forward()
                                                    local dir = (rec.pos - eye_pos):GetNormalized()
                                                    local dot = fWD:Dot(dir)
                                                    local fov_deg = math.deg(math.acos(math.Clamp(dot, -1, 1)))

                                                    if fov_deg < best_fov then
                                                        best_fov = fov_deg
                                                        best_target = { ent = ent, pos = rec.pos, tick = rec.tick }
                                                        end
                                                        end
                                                        else
                                                            local t_pos = GetHeadPos(ent)
                                                            local tr = util.TraceLine({ start = eye_pos, endpos = t_pos, filter = {ply, ent}, mask = MASK_SHOT })
                                                            if tr.Fraction < 1 then continue end

                                                                local fWD = eye_angles:Forward()
                                                                local dir = (t_pos - eye_pos):GetNormalized()
                                                                local dot = fWD:Dot(dir)
                                                                local fov_deg = math.deg(math.acos(math.Clamp(dot, -1, 1)))

                                                                if fov_deg < best_fov then best_fov = fov_deg; best_target = { ent = ent, pos = t_pos, tick = nil } end
                                                                    end
                                                                    end
                                                                    return best_target
                                                                    end

                                                                    -- 5. Главная логика CreateMove
                                                                    hook.Add( "CreateMove", "Zopahook_MainLogic", function( cmd )
                                                                    if cmd:CommandNumber() == 0 then return end

                                                                        local lp = LocalPlayer()
                                                                        if not IsValid(lp) or not lp:Alive() then return end

                                                                            -- Запись Backtrack позиций (для аимбота и чамсов)
                                                                    if backtrack_enabled then
                                                                        for _, ent in ipairs(player.GetAll()) do
                                                                            if ent ~= lp and ent:Alive() and ent:Team() ~= TEAM_SPECTATOR then
                                                                                backtrack_records[ent] = backtrack_records[ent] or {}
                                                                                table.insert(backtrack_records[ent], 1, {
                                                                                    tick = cmd:GetTickCount(),
                                                                                             pos = GetHeadPos(ent),
                                                                                             origin = ent:GetPos(),
                                                                                             angles = ent:GetAngles(),
                                                                                             sequence = ent:GetSequence(),
                                                                                             cycle = ent:GetCycle()
                                                                                })
                                                                                while #backtrack_records[ent] > backtrack_ticks do table.remove(backtrack_records[ent]) end
                                                                                    end
                                                                                    end
                                                                                    end

                                                                                    -- Логика Fake Lag и сохранение позиции для Fake Lag Chams
                                                                                    local send_packet = true
                                                                                    if fakelag_enabled then
                                                                                        choke_count = choke_count + 1
                                                                                        if choke_count >= fakelag_limit then send_packet = true; choke_count = 0 else send_packet = false end
                                                                                            end

                                                                                            if _G.bSendPacket ~= nil then _G.bSendPacket = send_packet end

                                                                                                if send_packet then
                                                                                                    fl_pos = lp:GetPos()
                                                                                                    fl_ang = Angle(0, my_view.y, 0)
                                                                                                    end

                                                                                                    if not initialized then my_view = cmd:GetViewAngles(); initialized = true end

                                                                                                        local delta_pitch, delta_yaw = 0, 0
                                                                                                        if not menuon and not gui.IsConsoleVisible() and not gui.IsGameUIVisible() and not vgui.CursorVisible() then
                                                                                                            local sens = GetConVar("sensitivity"):GetFloat()
                                                                                                            local m_pitch = GetConVar("m_pitch"):GetFloat()
                                                                                                            local m_yaw = GetConVar("m_yaw"):GetFloat()

                                                                                                            delta_pitch = cmd:GetMouseY() * m_pitch * sens
                                                                                                            delta_yaw = -cmd:GetMouseX() * m_yaw * sens
                                                                                                            end

                                                                                                            my_view.p = math.Clamp(my_view.p + delta_pitch, -89, 89)
                                                                                                            my_view.y = my_view.y + delta_yaw
                                                                                                            my_view:Normalize()
                                                                                                            my_view.r = 0

                                                                                                            local old_angles = Angle(my_view.p, my_view.y, my_view.r)
                                                                                                            cmd:SetViewAngles(my_view)

                                                                                                            if bhop_enabled and cmd:KeyDown( IN_JUMP ) then
                                                                                                                local flags = lp:GetFlags()
                                                                                                                if bit.band( flags, FL_ONGROUND ) == 0 and lp:GetMoveType() != MOVETYPE_LADDER and lp:WaterLevel() < 2 then
                                                                                                                    cmd:SetButtons( bit.band( cmd:GetButtons(), bit.bnot( IN_JUMP ) ) )
                                                                                                                    if autostrafe_enabled and delta_yaw != 0 then cmd:SetSideMove( delta_yaw > 0 and -450 or 450 ) end
                                                                                                                        end
                                                                                                                        end

                                                                                                                        local is_aiming = false
                                                                                                                        local target = (aim_enabled or auto_shoot) and GetAimbotTarget( lp, lp:EyePos(), my_view ) or nil

                                                                                                                        if auto_stop and target and (cmd:KeyDown(IN_ATTACK) or auto_shoot) then
                                                                                                                            cmd:SetForwardMove( 0 ); cmd:SetSideMove( 0 )
                                                                                                                            cmd:RemoveKey(IN_FORWARD); cmd:RemoveKey(IN_BACK); cmd:RemoveKey(IN_MOVELEFT); cmd:RemoveKey(IN_MOVERIGHT)
                                                                                                                            end

                                                                                                                            if auto_shoot and target then cmd:SetButtons( bit.bor( cmd:GetButtons(), IN_ATTACK ) ) end

                                                                                                                                if aim_enabled and (cmd:KeyDown( IN_ATTACK ) or auto_shoot) then
                                                                                                                                    if target then
                                                                                                                                        local aim_angles = (target.pos - lp:EyePos()):Angle()
                                                                                                                                        aim_angles:Normalize()
                                                                                                                                        cmd:SetViewAngles( aim_angles )
                                                                                                                                        is_aiming = true

                                                                                                                                        if backtrack_enabled and target.tick then cmd:SetTickCount(target.tick) end
                                                                                                                                            if not aim_silent then my_view = aim_angles else lp:SetEyeAngles( my_view ) end
                                                                                                                                                end
                                                                                                                                                end

                                                                                                                                                local is_attacking = cmd:KeyDown( IN_ATTACK )
                                                                                                                                                if aa_enabled and (not is_aiming or (aa_hideshots and is_attacking)) then
                                                                                                                                                    local aa_pitch = my_view.p
                                                                                                                                                    local aa_yaw = my_view.y

                                                                                                                                                    if aa_pitch_mode == "Down" then aa_pitch = 89
                                                                                                                                                        elseif aa_pitch_mode == "Up" then aa_pitch = -89
                                                                                                                                                            elseif aa_pitch_mode == "Emotion" then aa_pitch = 180 end

                                                                                                                                                                if aa_spin_enabled then
                                                                                                                                                                    current_spin_yaw = (current_spin_yaw + aa_spin_speed) % 360
                                                                                                                                                                    aa_yaw = aa_yaw + current_spin_yaw
                                                                                                                                                                    else
                                                                                                                                                                        aa_yaw = aa_yaw + aa_yaw_offset
                                                                                                                                                                        if aa_yaw_mode == "Jitter" then
                                                                                                                                                                            jitter_side = not jitter_side
                                                                                                                                                                            aa_yaw = aa_yaw + (jitter_side and aa_jitter_range or -aa_jitter_range)
                                                                                                                                                                            end
                                                                                                                                                                            end

                                                                                                                                                                            if desync_enabled and not send_packet then aa_yaw = aa_yaw + desync_range end

                                                                                                                                                                                if aa_hideshots and is_attacking then
                                                                                                                                                                                    aa_pitch = -aa_pitch; aa_yaw = aa_yaw + 90
                                                                                                                                                                                    if _G.bSendPacket ~= nil then _G.bSendPacket = false end
                                                                                                                                                                                        end

                                                                                                                                                                                        local aa_angles = Angle(aa_pitch, aa_yaw, 0)
                                                                                                                                                                                        aa_angles:Normalize()
                                                                                                                                                                                        cmd:SetViewAngles( aa_angles )
                                                                                                                                                                                        end

                                                                                                                                                                                        if norecoil_enabled and cmd:KeyDown(IN_ATTACK) then
                                                                                                                                                                                            local punch = lp:GetPunchAngle()
                                                                                                                                                                                            if punch and (punch.p != 0 or punch.y != 0) then
                                                                                                                                                                                                local comp = cmd:GetViewAngles() - punch
                                                                                                                                                                                                comp:Normalize(); cmd:SetViewAngles(comp)
                                                                                                                                                                                                end
                                                                                                                                                                                                end

                                                                                                                                                                                                CorrectMovement( cmd, old_angles )
                                                                                                                                                                                                end )

                                                                    hook.Add( "CalcView", "Zopahook_ViewManager", function( ply, pos, angles, fov )
                                                                    if not IsValid(ply) or not ply:Alive() then return end
                                                                        if not tp_enabled then return { origin = pos, angles = my_view, fov = fov, drawviewer = false } end

                                                                            local trace = util.TraceLine( { start = pos, endpos = pos - ( my_view:Forward() * tp_distance ), filter = ply } )
                                                                            return { origin = trace.HitPos + ( my_view:Right() * 2 ), angles = my_view, fov = fov, drawviewer = true }
                                                                            end )

                                                                    -- 7. Visuals: ESP & HUD
                                                                    hook.Add( "HUDPaint", "Zopahook_Visuals", function()
                                                                    local lp = LocalPlayer()
                                                                    if not IsValid(lp) then return end

                                                                        if esp_enabled then
                                                                            for _, ent in ipairs( ents.GetAll() ) do
                                                                                if ent == lp then continue end
                                                                                    if not (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then continue end
                                                                                        if ent:IsPlayer() and (not ent:Alive() or ent:Team() == TEAM_SPECTATOR) then continue end
                                                                                            if ent:Health() and ent:Health() <= 0 then continue end
                                                                                                if lp:GetPos():Distance(ent:GetPos()) > esp_distance then continue end

                                                                                                    local pos = ent:GetPos()
                                                                                                    local topPos = pos + Vector(0, 0, ent:OBBMaxs().z)

                                                                                                    local p1 = pos:ToScreen()
                                                                                                    local p2 = topPos:ToScreen()

                                                                                                    if p1.visible and p2.visible then
                                                                                                        local h = math.abs(p1.y - p2.y)
                                                                                                        local w = h * 0.6
                                                                                                        local x = p1.x - w / 2
                                                                                                        local y = p2.y

                                                                                                        surface.SetDrawColor(0, 0, 0, 255)
                                                                                                        surface.DrawOutlinedRect(x - 1, y - 1, w + 2, h + 2)
                                                                                                        surface.DrawOutlinedRect(x + 1, y + 1, w - 2, h - 2)

                                                                                                        surface.SetDrawColor(ent:IsPlayer() and OTC_ACCENT or Color(0, 200, 255))
                                                                                                        surface.DrawOutlinedRect(x, y, w, h)

                                                                                                        local name = ent:IsPlayer() and ent:Nick() or ent:GetClass()
                                                                                                        draw.SimpleText(name, "ZopahookESP", p1.x, y - 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                                                                                                        end
                                                                                                        end
                                                                                                        end

                                                                                                        if hud_enabled then
                                                                                                            local fps = math.Round( 1 / RealFrameTime() )
                                                                                                            local ping = IsValid(lp) and lp:Ping() or 0
                                                                                                            local hud_text = string.format( "Zopahook | %s | %d FPS | %d player | %d ms", lp:Nick() or "user", fps, #player.GetAll(), ping )

                                                                                                            surface.SetFont( "Zopahook_HUD_Font" )
                                                                                                            local t_w, t_h = surface.GetTextSize( hud_text )
                                                                                                            local box_w, box_h, box_x, box_y = t_w + 30, 24, ScrW() - t_w - 50, 15

                                                                                                            surface.SetDrawColor( Color( 20, 20, 22, 245 ) )
                                                                                                            surface.DrawRect( box_x, box_y, box_w, box_h )

                                                                                                            for i = 0, box_w - 1 do
                                                                                                                local hue = ( ( i / box_w ) * 360 + ( CurTime() * 50 ) ) % 360
                                                                                                                surface.SetDrawColor( HSVToColor( hue, 1, 1 ) )
                                                                                                                surface.DrawRect( box_x + i, box_y, 1, 3 )
                                                                                                                end
                                                                                                                draw.SimpleText( hud_text, "Zopahook_HUD_Font", box_x + 15, box_y + 5, OTC_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
                                                                                                                end
                                                                                                                end )

                                                                    -- Починенные Обычные Chams
                                                                    hook.Add( "PrePlayerDraw", "Zopahook_PlayerChams", function( ply )
                                                                    if not chams_enabled or ply == LocalPlayer() then return end
                                                                        if not ply:Alive() or ply:Team() == TEAM_SPECTATOR then return end
                                                                            if LocalPlayer():GetPos():Distance(ply:GetPos()) > esp_distance then return end

                                                                                local active_mat = mat_flat
                                                                                if chams_mode == "Wireframe" then active_mat = mat_wire
                                                                                    elseif chams_mode == "Glow" then active_mat = mat_glow
                                                                                        elseif chams_mode == "Metallic" then active_mat = mat_metal end

                                                                                            render.MaterialOverride( active_mat )
                                                                                            render.SetColorModulation( chams_color.r / 255, chams_color.g / 255, chams_color.b / 255 )
                                                                                            cam.IgnoreZ( true )
                                                                                            end )

                                                                    hook.Add( "PostPlayerDraw", "Zopahook_PlayerChamsPost", function( ply )
                                                                    if not chams_enabled or ply == LocalPlayer() then return end
                                                                        cam.IgnoreZ( false )
                                                                        render.MaterialOverride( nil )
                                                                        render.SetColorModulation( 1, 1, 1 )
                                                                        end )

                                                                    -- Логика отрисовки Ghost Chams (Backtrack & Fake Lag)
                                                                    local ghost_mdl = nil
                                                                    local function GetGhostEntity()
                                                                    if not IsValid(ghost_mdl) then
                                                                        ghost_mdl = ClientsideModel("models/player/kleiner.mdl", RENDERGROUP_OPAQUE)
                                                                        ghost_mdl:SetNoDraw(true)
                                                                        end
                                                                        return ghost_mdl
                                                                        end

                                                                        hook.Add( "PostDrawTranslucentRenderables", "Zopahook_GhostChams", function()
                                                                        local lp = LocalPlayer()
                                                                        if not IsValid(lp) then return end

                                                                            local ghost = GetGhostEntity()
                                                                            if not IsValid(ghost) then return end

                                                                                -- Backtrack Chams
                                                                                if bt_chams_enabled and backtrack_enabled then
                                                                                    for ply, records in pairs(backtrack_records) do
                                                                                        if IsValid(ply) and ply:Alive() and ply ~= lp then
                                                                                            local rec = records[#records] -- Самый старый (дальний) тик
                                                                                            if rec and rec.origin and rec.angles then
                                                                                                local mdl = ply:GetModel()
                                                                                                if mdl and mdl ~= "" and ghost:GetModel() ~= mdl then ghost:SetModel(mdl) end

                                                                                                    ghost:SetPos(rec.origin)
                                                                                                    ghost:SetAngles(rec.angles)
                                                                                                    ghost:SetSequence(rec.sequence or 0)
                                                                                                    ghost:SetCycle(rec.cycle or 0)
                                                                                                    ghost:SetupBones()

                                                                                                    render.MaterialOverride(mat_flat)
                                                                                                    render.SetColorModulation(bt_chams_color.r/255, bt_chams_color.g/255, bt_chams_color.b/255)
                                                                                                    render.SetBlend(0.6)
                                                                                                    cam.IgnoreZ(true)
                                                                                                    ghost:DrawModel()
                                                                                                    cam.IgnoreZ(false)
                                                                                                    end
                                                                                                    end
                                                                                                    end
                                                                                                    end

                                                                                                    -- Fake Lag Chams
                                                                                                    if fl_chams_enabled and fakelag_enabled and lp:Alive() then
                                                                                                        if fl_pos and fl_ang then
                                                                                                            local mdl = lp:GetModel()
                                                                                                            if mdl and mdl ~= "" and ghost:GetModel() ~= mdl then ghost:SetModel(mdl) end

                                                                                                                ghost:SetPos(fl_pos)
                                                                                                                ghost:SetAngles(fl_ang)
                                                                                                                ghost:SetSequence(lp:GetSequence())
                                                                                                                ghost:SetCycle(lp:GetCycle())
                                                                                                                ghost:SetupBones()

                                                                                                                render.MaterialOverride(mat_flat)
                                                                                                                render.SetColorModulation(fl_chams_color.r/255, fl_chams_color.g/255, fl_chams_color.b/255)
                                                                                                                render.SetBlend(0.6)
                                                                                                                ghost:DrawModel()
                                                                                                                end
                                                                                                                end

                                                                                                                render.MaterialOverride()
                                                                                                                render.SetColorModulation(1, 1, 1)
                                                                                                                render.SetBlend(1)
                                                                                                                end )

                                                                        -- Меню открывается на клавишу INSERT
                                                                        local menu_pressed = false
                                                                        hook.Add("Think", "Zopahook_MenuToggle", function()
                                                                        if input.IsKeyDown(KEY_INSERT) then
                                                                            if not menu_pressed then
                                                                                menu_pressed = true
                                                                                if not menuon then OpenCheatMenu() else if IsValid(cheatwindow) then cheatwindow:Close() end; menuon = false end
                                                                                    end
                                                                                    else
                                                                                        menu_pressed = false
                                                                                        end
                                                                                        end)

                                                                        -- 8. Главное меню (Onetap v3 Layout)
                                                                        function OpenCheatMenu()
                                                                        menuon = true
                                                                        cheatwindow = vgui.Create( "DFrame" )
                                                                        cheatwindow:SetSize( 560, 480 )
                                                                        cheatwindow:Center()
                                                                        cheatwindow:SetTitle( "" )
                                                                        cheatwindow:ShowCloseButton( false )
                                                                        cheatwindow:MakePopup()

                                                                        cheatwindow.Paint = function( self, w, h )
                                                                        draw.RoundedBox( 0, 0, 0, w, h, OTC_BG )
                                                                        draw.RoundedBox( 0, 0, 0, w, 4, OTC_ACCENT )
                                                                        draw.SimpleText( "Zopahook", "OTC_Title", 20, 20, OTC_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
                                                                        end

                                                                        local close_btn = vgui.Create( "DButton", cheatwindow )
                                                                        close_btn:SetSize( 20, 20 )
                                                                        close_btn:SetPos( cheatwindow:GetWide() - 30, 20 )
                                                                        close_btn:SetText( "X" )
                                                                        close_btn:SetFont( "OTC_Text" )
                                                                        close_btn:SetTextColor( OTC_MUTED )
                                                                        close_btn.Paint = function() end
                                                                        close_btn.DoClick = function() cheatwindow:Close() menuon = false end

                                                                        local content_panel = vgui.Create( "DPanel", cheatwindow )
                                                                        content_panel:SetPos( 20, 70 )
                                                                        content_panel:SetSize( cheatwindow:GetWide() - 40, cheatwindow:GetTall() - 90 )
                                                                        content_panel.Paint = function() end

                                                                        local function RebuildMenu()
                                                                        if not IsValid(content_panel) then return end
                                                                            content_panel:Clear()

                                                                            local function AddCheckbox(parent, x, y, label, var_get, var_set)
                                                                            local btn = vgui.Create("DButton", parent)
                                                                            btn:SetSize(14, 14); btn:SetPos(x, y); btn:SetText("")
                                                                            btn.Paint = function(s, w, h)
                                                                            draw.RoundedBox(2, 0, 0, w, h, OTC_BG)
                                                                            if var_get() then draw.RoundedBox(2, 2, 2, w-4, h-4, OTC_ACCENT) end
                                                                                end
                                                                                btn.DoClick = function() var_set(not var_get()) end
                                                                                local lbl = vgui.Create("DLabel", parent)
                                                                                lbl:SetPos(x + 25, y - 2); lbl:SetText(label); lbl:SetFont("OTC_Text")
                                                                                lbl:SetTextColor(var_get() and OTC_TEXT or OTC_MUTED); lbl:SizeToContents()
                                                                                end

                                                                                local function AddCombo(parent, x, y, width, label, options, current_val, on_change)
                                                                                local lbl = vgui.Create("DLabel", parent)
                                                                                lbl:SetPos(x, y); lbl:SetText(label); lbl:SetFont("OTC_Text"); lbl:SetTextColor(OTC_TEXT); lbl:SizeToContents()
                                                                                local cb = vgui.Create("DComboBox", parent)
                                                                                cb:SetPos(x, y + 18); cb:SetSize(width, 20); cb:SetValue(tostring(current_val or options[1]))
                                                                                for _, opt in ipairs(options) do cb:AddChoice(opt) end
                                                                                    cb.OnSelect = function(_, _, _, val) on_change(val) end
                                                                                    cb.Paint = function(s, w, h) draw.RoundedBox(2, 0, 0, w, h, OTC_BG); cb:SetTextColor(OTC_TEXT) end
                                                                                    end

                                                                                    local function AddSlider(parent, x, y, width, max_val, label, current_val, on_change)
                                                                                    local lbl = vgui.Create( "DLabel", parent )
                                                                                    lbl:SetPos( x, y ); lbl:SetFont( "OTC_Text" ); lbl:SetTextColor( OTC_TEXT ); lbl:SetText( label .. ": " .. math.Round(current_val) ); lbl:SizeToContents()
                                                                                    local sld = vgui.Create( "DSlider", parent )
                                                                                    sld:SetPos( x, y + 18 ); sld:SetSize( width, 10 ); sld:SetSlideX( current_val / max_val )
                                                                                    sld.Paint = function( self, w, h ) draw.RoundedBox( 2, 0, 4, w, 3, OTC_BG ); draw.RoundedBox( 2, 0, 4, w * self:GetSlideX(), 3, OTC_ACCENT ) end
                                                                                    sld.Knob.Paint = function( self, w, h ) draw.RoundedBox( 6, 2, -1, 8, 8, color_white ) end
                                                                                    sld.OnValueChanged = function( self, x_val, y_val )
                                                                                    local calc = x_val * max_val; on_change(calc); lbl:SetText( label .. ": " .. math.Round(calc) )
                                                                                    end
                                                                                    end

                                                                                    if active_tab == "Rage" then
                                                                                        local group_aim = vgui.Create( "DPanel", content_panel )
                                                                                        group_aim:SetSize( 240, 300 ); group_aim:SetPos( 10, 10 )
                                                                                        group_aim.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "Aimbot & Backtrack", "OTC_Text", 15, 10, OTC_ACCENT ) end

                                                                                        AddCheckbox(group_aim, 15, 40, "Enable Aimbot", function() return aim_enabled end, function(v) aim_enabled = v; RebuildMenu() end)
                                                                                        AddCheckbox(group_aim, 15, 65, "Silent Aim", function() return aim_silent end, function(v) aim_silent = v; RebuildMenu() end)
                                                                                        AddCheckbox(group_aim, 15, 90, "Enable Backtrack", function() return backtrack_enabled end, function(v) backtrack_enabled = v; RebuildMenu() end)
                                                                                        AddCheckbox(group_aim, 15, 115, "No Recoil", function() return norecoil_enabled end, function(v) norecoil_enabled = v; RebuildMenu() end)
                                                                                        AddCheckbox(group_aim, 15, 140, "Auto Shoot", function() return auto_shoot end, function(v) auto_shoot = v; RebuildMenu() end)
                                                                                        AddCheckbox(group_aim, 15, 165, "Auto Stop", function() return auto_stop end, function(v) auto_stop = v; RebuildMenu() end)

                                                                                        AddSlider(group_aim, 15, 205, 210, 180, "Aimbot FOV", aim_fov, function(v) aim_fov = v end)
                                                                                        AddSlider(group_aim, 15, 250, 210, 24, "Backtrack Ticks", backtrack_ticks, function(v) backtrack_ticks = math.max(1, v) end)

                                                                                        elseif active_tab == "Anti-Aim" then
                                                                                            local group_aa = vgui.Create( "DPanel", content_panel )
                                                                                            group_aa:SetSize( 240, 320 ); group_aa:SetPos( 10, 10 )
                                                                                            group_aa.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "Rage Anti-Aim", "OTC_Text", 15, 10, OTC_ACCENT ) end

                                                                                            AddCheckbox(group_aa, 15, 35, "Enabled", function() return aa_enabled end, function(v) aa_enabled = v; RebuildMenu() end)
                                                                                            AddCheckbox(group_aa, 15, 60, "Hide Shots", function() return aa_hideshots end, function(v) aa_hideshots = v; RebuildMenu() end)
                                                                                            AddCheckbox(group_aa, 15, 85, "Enable Desync", function() return desync_enabled end, function(v) desync_enabled = v; RebuildMenu() end)

                                                                                            AddCombo(group_aa, 15, 115, 210, "Pitch Mode", {"Off", "Down", "Up", "Emotion"}, aa_pitch_mode, function(val) aa_pitch_mode = val end)
                                                                                            AddCombo(group_aa, 15, 165, 210, "Yaw Mode", {"Static", "Jitter"}, aa_yaw_mode, function(val) aa_yaw_mode = val end)

                                                                                            AddSlider(group_aa, 15, 220, 210, 360, "Yaw Offset", aa_yaw_offset, function(v) aa_yaw_offset = v end)
                                                                                            AddSlider(group_aa, 15, 265, 210, 180, "Jitter Range", aa_jitter_range, function(v) aa_jitter_range = v end)

                                                                                            local group_spin = vgui.Create( "DPanel", content_panel )
                                                                                            group_spin:SetSize( 240, 110 ); group_spin:SetPos( 260, 10 )
                                                                                            group_spin.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "Spinbot", "OTC_Text", 15, 10, OTC_ACCENT ) end
                                                                                            AddCheckbox(group_spin, 15, 35, "Enable Spinbot", function() return aa_spin_enabled end, function(v) aa_spin_enabled = v; RebuildMenu() end)
                                                                                            AddSlider(group_spin, 15, 65, 210, 50, "Spin Speed", aa_spin_speed, function(v) aa_spin_speed = v end)

                                                                                            local group_fakelag = vgui.Create( "DPanel", content_panel )
                                                                                            group_fakelag:SetSize( 240, 110 ); group_fakelag:SetPos( 260, 130 )
                                                                                            group_fakelag.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "Fake Lag", "OTC_Text", 15, 10, OTC_ACCENT ) end
                                                                                            AddCheckbox(group_fakelag, 15, 35, "Enable Fake Lag", function() return fakelag_enabled end, function(v) fakelag_enabled = v; RebuildMenu() end)
                                                                                            AddSlider(group_fakelag, 15, 65, 210, 14, "Choke Limit", fakelag_limit, function(v) fakelag_limit = math.max(1, v) end)
                                                                                            AddSlider(group_fakelag, 15, 140, 210, 60, "Desync Range", desync_range, function(v) desync_range = v end)

                                                                                            elseif active_tab == "Visual" then
                                                                                                -- Left Column
                                                                                                local group_esp = vgui.Create( "DPanel", content_panel )
                                                                                                group_esp:SetSize( 240, 160 ); group_esp:SetPos( 10, 10 )
                                                                                                group_esp.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "ESP & Normal Chams", "OTC_Text", 15, 10, OTC_ACCENT ) end
                                                                                                AddCheckbox(group_esp, 15, 35, "Enable Box ESP", function() return esp_enabled end, function(v) esp_enabled = v; RebuildMenu() end)
                                                                                                AddCheckbox(group_esp, 15, 60, "Enable XQZ Chams", function() return chams_enabled end, function(v) chams_enabled = v; RebuildMenu() end)
                                                                                                AddCombo(group_esp, 15, 85, 210, "Chams Mode", {"Color", "Wireframe", "Glow", "Metallic"}, chams_mode, function(val) chams_mode = val end)
                                                                                                AddSlider(group_esp, 15, 130, 210, 5000, "Max Distance", esp_distance, function(v) esp_distance = v end)

                                                                                                local group_ghost = vgui.Create("DPanel", content_panel)
                                                                                                group_ghost:SetSize(240, 85); group_ghost:SetPos(10, 180)
                                                                                                group_ghost.Paint = function(s,w,h) draw.RoundedBox(4,0,0,w,h,OTC_DARK); draw.SimpleText("Ghost Chams", "OTC_Text", 15, 10, OTC_ACCENT) end
                                                                                                AddCheckbox(group_ghost, 15, 35, "Backtrack Chams", function() return bt_chams_enabled end, function(v) bt_chams_enabled = v; RebuildMenu() end)
                                                                                                AddCheckbox(group_ghost, 15, 60, "Fake Lag Chams", function() return fl_chams_enabled end, function(v) fl_chams_enabled = v; RebuildMenu() end)

                                                                                                local group_tp = vgui.Create( "DPanel", content_panel )
                                                                                                group_tp:SetSize( 240, 85 ); group_tp:SetPos( 10, 275 )
                                                                                                group_tp.Paint = function( s, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "Thirdperson", "OTC_Text", 15, 10, OTC_ACCENT ) end
                                                                                                AddCheckbox(group_tp, 15, 30, "Thirdperson View", function() return tp_enabled end, function(v) tp_enabled = v; RebuildMenu() end)
                                                                                                AddSlider(group_tp, 15, 55, 210, 300, "Camera Distance", tp_distance, function(v) tp_distance = math.max(30, v) end)

                                                                                                -- Right Column
                                                                                                local group_color = vgui.Create( "DPanel", content_panel )
                                                                                                group_color:SetSize( 240, 135 ); group_color:SetPos( 260, 10 )
                                                                                                group_color.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "Normal Chams Color", "OTC_Text", 15, 10, OTC_ACCENT ); draw.RoundedBox( 2, w - 35, 10, 20, 14, chams_color ) end
                                                                                                AddSlider(group_color, 15, 35, 210, 255, "R", chams_color.r, function(v) chams_color.r = v end)
                                                                                                AddSlider(group_color, 15, 65, 210, 255, "G", chams_color.g, function(v) chams_color.g = v end)
                                                                                                AddSlider(group_color, 15, 95, 210, 255, "B", chams_color.b, function(v) chams_color.b = v end)

                                                                                                local group_bt_clr = vgui.Create("DPanel", content_panel)
                                                                                                group_bt_clr:SetSize(240, 115); group_bt_clr:SetPos(260, 155)
                                                                                                group_bt_clr.Paint = function( s, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "BT Ghost Color", "OTC_Text", 15, 10, OTC_ACCENT ); draw.RoundedBox( 2, w - 35, 10, 20, 14, bt_chams_color ) end
                                                                                                AddSlider(group_bt_clr, 15, 30, 210, 255, "R", bt_chams_color.r, function(v) bt_chams_color.r = v end)
                                                                                                AddSlider(group_bt_clr, 15, 60, 210, 255, "G", bt_chams_color.g, function(v) bt_chams_color.g = v end)
                                                                                                AddSlider(group_bt_clr, 15, 90, 210, 255, "B", bt_chams_color.b, function(v) bt_chams_color.b = v end)

                                                                                                local group_fl_clr = vgui.Create("DPanel", content_panel)
                                                                                                group_fl_clr:SetSize(240, 115); group_fl_clr:SetPos(260, 280)
                                                                                                group_fl_clr.Paint = function( s, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "FL Ghost Color", "OTC_Text", 15, 10, OTC_ACCENT ); draw.RoundedBox( 2, w - 35, 10, 20, 14, fl_chams_color ) end
                                                                                                AddSlider(group_fl_clr, 15, 30, 210, 255, "R", fl_chams_color.r, function(v) fl_chams_color.r = v end)
                                                                                                AddSlider(group_fl_clr, 15, 60, 210, 255, "G", fl_chams_color.g, function(v) fl_chams_color.g = v end)
                                                                                                AddSlider(group_fl_clr, 15, 90, 210, 255, "B", fl_chams_color.b, function(v) fl_chams_color.b = v end)

                                                                                                elseif active_tab == "Misc" then
                                                                                                    local group_misc = vgui.Create( "DPanel", content_panel )
                                                                                                    group_misc:SetSize( 240, 80 ); group_misc:SetPos( 10, 10 )
                                                                                                    group_misc.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "HUD Settings", "OTC_Text", 15, 10, OTC_ACCENT ) end

                                                                                                    AddCheckbox(group_misc, 15, 40, "Enable Zopahook HUD", function() return hud_enabled end, function(v) hud_enabled = v; RebuildMenu() end)

                                                                                                    local group_movement = vgui.Create( "DPanel", content_panel )
                                                                                                    group_movement:SetSize( 240, 120 ); group_movement:SetPos( 260, 10 )
                                                                                                    group_movement.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, OTC_DARK ); draw.SimpleText( "Movement", "OTC_Text", 15, 10, OTC_ACCENT ) end

                                                                                                    AddCheckbox(group_movement, 15, 40, "BunnyHop", function() return bhop_enabled end, function(v) bhop_enabled = v; RebuildMenu() end)
                                                                                                    AddCheckbox(group_movement, 15, 65, "Auto-Strafe", function() return autostrafe_enabled end, function(v) autostrafe_enabled = v; RebuildMenu() end)
                                                                                                    end
                                                                                                    end

                                                                                                    local tabs = { "Legit", "Rage", "Anti-Aim", "Visual", "Misc" }
                                                                                                    for i, tab_name in ipairs( tabs ) do
                                                                                                        local tab_btn = vgui.Create( "DButton", cheatwindow )
                                                                                                        tab_btn:SetText( tab_name ); tab_btn:SetFont( "OTC_Tab" ); tab_btn:SetSize( 75, 25 ); tab_btn:SetPos( 140 + ( (i - 1) * 78 ), 20 )
                                                                                                        tab_btn.Paint = function( self ) self:SetTextColor( active_tab == tab_name and OTC_ACCENT or (self:IsHovered() and OTC_TEXT or OTC_MUTED) ) end
                                                                                                        tab_btn.DoClick = function() active_tab = tab_name; RebuildMenu() end
                                                                                                        end

                                                                                                        RebuildMenu()
                                                                                                        end

                                                                                                        concommand.Add( "govno", function()
                                                                                                        if not menuon then OpenCheatMenu() else if IsValid(cheatwindow) then cheatwindow:Close() end; menuon = false end
                                                                                                            end )
