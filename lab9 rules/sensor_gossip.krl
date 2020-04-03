ruleset manage_sensors {
    meta {
        shares sensors, temperatures, temperature_sensor_reports
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subscriptions
    }

    global{
        HEARTBEAT_INTERVAL_DEFAULT = 5
    }


    rule start_heartbeat{
        select when gossip start_heartbeat
        always{
            schedule gossip event "heartbeat" at time:add(time:now(), 
            {"seconds": ent:heartbeat_interval.defaultsTo(HEARTBEAT_INTERVAL_DEFAULT)})
        }
    }

    rule update_heartbeat{
        select when gossip update_heartbeat
        pre{
            heartbeat_interval = event:attr("heartbeat_interval")
        }
        if heartbeat.isnull() then noop()
        notfired{
            ent:heartbeat_interval := heartbeat_interval
        }
    }

    rule pause_gossip{
        select when gossip pause
        pre{
            is_pause = event:attr("is_pause").as("Boolean").defaultsTo(false)
        }
        if is_pause then
            noop()
        always{
            ent:is_gossip_paused := is_pause
        }
        
    }

    rule collect_internal_temperatures {
        select when wovyn new_temperature_reading 
        pre{
            temperature = event:attr("temperature")
            timestamp = event:attr("timestamp")
            message_number = ent:internal_temperature_messages.length().defaultsTo(0) 
            message_id = random:uuid() + ":" + message_number
            sensor_id = meta:picoId
        }
        always{
            ent:current_temperature := temperature
            ent:temperature_messages{message_number} := {
                "MessageID": message_id,
                "SensorID": sensor_id,
                "Temperature": temperature,
                "Timestamp": timestamp
            }
        }
    }

    rule handle_heartbeat{
        select when gossip heartbeat

    }

    rule handle_rumor_message{
        select when gossip rumor
        pre{
            rumor = event:attr("rumor_message")
            message_number = rumor{"MessageId"}.split(re#;#)
        }
        if rumor.isnull() then noop()
        notfired{
            ent:rumor_messages{rumor{"Sensor_id"}} := rumor
            ent:my_seen_messages
        }
    }

    rule handle_seen_message{
        select when gossip seen 
        pre{
            message = event:attr("seen_message")
            sender = event:attr("sender")
        }
        if message.isnull() then noop()
        notfired{
            ent:seen_messages{sender} := message
        }
    }
}