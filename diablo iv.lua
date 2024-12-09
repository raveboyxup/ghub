--[[
按键宏脚本说明：
1. 使用滚轮锁定键(Scroll Lock)控制整个脚本的开关
2. 按住左Ctrl键时只循环鼠标左键
3. 释放左Ctrl键时恢复所有按键的循环
4. 按下鼠标5号键(通常是侧键)启动脚本
5. 在key_config中配置需要循环的按键和时间间隔
6. time设置为-1时按键将持续按下，直到状态改变
]]--

-- 按键配置（时间单位：毫秒，-1表示持续按下）
local key_config = {
    -- 要循环的按键在下面添加或注释
    -- ["q"] = {time = 500, last_press = 0},    -- Q键每500ms按一次
    ["w"] = {time = 500, last_press = 0},    -- W键每500ms按一次
    ["e"] = {time = 500, last_press = 0},     -- E键持续按下
    ["r"] = {time = 500, last_press = 0},    -- R键每500ms按一次
    ["left"] = {time = 50, last_press = 0},  -- 鼠标左键每50ms按一次
    ["right"] = {time = 50, last_press = 0}, -- 鼠标右键每50ms按一次
    -- ["space"] = {time = 50, last_press = 0}  -- 空格键每50ms按一次
}

-- 暂停状态标志（用于标记是否只循环鼠标左键）
local is_paused = false

-- 记录持续按下的按键状态
local pressed_keys = {}

-- 启用鼠标主按键事件监听
EnablePrimaryMouseButtonEvents(true)

-- 按键处理函数
-- @param key: 要按下的键名
-- @param is_continuous: 是否是持续按下模式
function PressButton(key, is_continuous)
    if is_continuous then
        -- 持续按下模式：只在按键未被按下时执行
        if not pressed_keys[key] then
            if key == "left" then
                PressMouseButton(1)
                OutputLogMessage("持续按下鼠标左键\n")
            elseif key == "right" then
                PressMouseButton(3)
                OutputLogMessage("持续按下鼠标右键\n")
            elseif key == "space" then
                PressKey("spacebar")
            else
                PressKey(key)
            end
            pressed_keys[key] = true
            OutputLogMessage("持续按下按键: %s\n", key)
        end
    else
        -- 普通点击模式：按下后立即释放
        if key == "left" then
            PressAndReleaseMouseButton(1)
        elseif key == "right" then
            PressAndReleaseMouseButton(3)
        elseif key == "space" then
            PressAndReleaseKey("spacebar")
        else
            PressAndReleaseKey(key)
        end
    end
end

-- 释放所有持续按下的按键
function ReleaseAllKeys()
    for key, _ in pairs(pressed_keys) do
        if key == "left" then
            ReleaseMouseButton(1)
        elseif key == "right" then
            ReleaseMouseButton(3)
        elseif key == "space" then
            ReleaseKey("spacebar")
        else
            ReleaseKey(key)
        end
        OutputLogMessage("释放按键: %s\n", key)
    end
    pressed_keys = {}
end

-- 主循环函数
function LianxuAnjian()
    -- 初始化所有按键的最后按下时间
    local current_time = GetRunningTime()
    for k, v in pairs(key_config) do
        v.last_press = current_time
    end

    -- 当滚轮锁定键开启时持续运行
    while (IsKeyLockOn("scrolllock")) do
        -- 检查左Ctrl键状态
        if IsModifierPressed("lctrl") then
            -- 如果当前正在执行所有按键的循环，则释放持续按下的按键
            if not is_paused then
                is_paused = true
                OutputLogMessage("---------- 只循环鼠标左键 ----------\n")
                -- 释放所有持续按下的按键
                ReleaseAllKeys()
            end
            
            -- 只执行鼠标左键的循环
            current_time = GetRunningTime()
            local left_config = key_config["left"]
            if (current_time - left_config.last_press) >= left_config.time then
                PressButton("left", false)
                left_config.last_press = current_time
            end
        else
            -- 如果当前是暂停状态，则恢复所有按键的循环
            if is_paused then
                is_paused = false
                OutputLogMessage("---------- 恢复所有按键循环 ----------\n")
                -- 重置所有按键的最后按下时间
                current_time = GetRunningTime()
                for k, v in pairs(key_config) do
                    v.last_press = current_time
                end
            end

            -- 执行所有按键的循环
            current_time = GetRunningTime()
            for key, config in pairs(key_config) do
                if config.time == -1 then
                    -- 持续按下模式
                    PressButton(key, true)
                elseif (current_time - config.last_press) >= config.time then
                    -- 普通点击模式
                    PressButton(key, false)
                    config.last_press = current_time
                end
            end
        end
        
        Sleep(10) -- 短暂休眠，防止CPU占用过高
    end
    
    -- 循环结束时释放所有按下的按键
    ReleaseAllKeys()
end

-- 事件处理函数
-- @param event: 事件类型
-- @param arg: 事件参数
function OnEvent(event, arg)
    -- 当按下鼠标5号键时启动脚本
    if (event == "MOUSE_BUTTON_RELEASED" and arg == 4) then
        OutputLogMessage("========== 开始连续按键 ==========\n")
        LianxuAnjian()
    end
end
