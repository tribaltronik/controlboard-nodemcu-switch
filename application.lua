-- file : application.lua
local module = {}  
m = nil
config = require("config")

 -- set pin index 1 to GPIO mode, and set the pin to high.
pin=1
gpio.mode(pin, gpio.OUTPUT)
    

-- Sends a simple ping to the broker
local function send_ping()  
    if wifi.sta.status() == 5 then 
        print("Send Ping")
        m:publish(config.ID .. "/ping",'{"id":"' .. config.ID..'","ip":"' .. wifi.sta.getip()..'"}',0,0)
        
     else
        m:close()
        mqtt_start()
     end   
end

-- Sends my id to the broker for registration
local function register_myself()  
    m:subscribe(config.ID.."/switch",0,function(conn)
        print("Successfully subscribed to data endpoint: "..config.ID)
    end)
    m:subscribe(config.ID.."/status",0,function(conn)
        print("Successfully subscribed to status topic: "..config.ID)
    end)
end

local function mqtt_start()  
    print("start mqtt")
    print("ID:"..config.ID)
    print("User:"..config.user.." Pass:"..config.pass)
    m = mqtt.Client(config.ID, 120, config.user, config.pass)
    -- register message callback beforehand
    m:on("message", function(conn, topic, data) 
      if data ~= nil then
        print(topic .. ": " .. data)
        if topic == config.ID.."/switch" then
            
            if data == '{"value":1}' then
                print(pin .. " mudou para 1")
                gpio.write(pin, gpio.HIGH)
            else
                print(pin .. " mudou para 0")
                gpio.write(pin, gpio.LOW)
            end
        end
        if topic == config.ID.."/status" then
            if data == "alive" then
                m:publish(config.ID .. "/status",'{"id":"' .. config.ID..'","ip":"' .. wifi.sta.getip()..'"}',0,0)
            end      
        end
        -- do something, we have received a message
      end
    end)
    -- Connect to broker
    m:connect(config.HOST, config.PORT, 0, 1, function(con) 
        rgb.color("green") -- Green
        register_myself()
        -- And then pings each 1000 milliseconds
        tmr.stop(6)
        send_ping() 
        tmr.alarm(6, 60000, 1, send_ping)
    end) 

end

function module.start()  
  mqtt_start()
end

return module  
