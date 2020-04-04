ruleset manage_sensors {
    meta {
        use module io.picolabs.subscription alias subscriptions
    }

    global{
        HEARTBEAT_INTERVAL_DEFAULT = 5

        needed_messages_by_eci = function(eci){
            rumor_messages = ent:seen_messages{eci}.filter(function(message_num, pico_id) {
                message_num.as("Number") < ent:my_seen_messages{pico_id}.as("Number")
            })
            seen_messages = ent:seen_messages{eci}.filter(function(message_num, pico_id) {
                message_num.as("Number") != ent:my_seen_messages{pico_id}.as("Number")
            })
            return {"eci":eci, "rumor": rumor_messages, "seen":seen_messages}
        }

        peers_needing_message = function(){
            peers_and_messages = subscriptions:established("Tx_role","gossip_friend").map(function(subscription) {
                needed_messages_by_eci(subscription.klog("subscription: "){"Tx"})
            })
            peers_in_need = peers_and_messages.filter(function(peer) {
                peer.klog("peer in need: "){"rumor"}.length() > 0 => true |
                                                peer{"seen"} > 0 => true | false
            })
            return peers_in_need.klog("All Peers in need: ")
        }

        getPeer = function(){
            peers = peers_needing_message()
            return peers[random:integer(peers.length() - 1)]
        }
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
            message_number = ent:rumor_messages{meta:picoId}.length().defaultsTo(0) 
            message_id = random:uuid() + ":" + message_number
            sensor_id = meta:picoId
        }
        always{
            ent:rumor_messages{sensor_id} := {
                "MessageID": message_id,
                "SensorID": sensor_id,
                "Temperature": temperature,
                "Timestamp": timestamp
            }.klog("New Temperature Message: ")
        }
    }

    rule handle_heartbeat{
        select when gossip heartbeat
        pre{
            
        }
    }

    rule handle_rumor_message{
        select when gossip rumor
        pre{
            rumor = event:attr("rumor_message")
            sensor_id = rumor{"Sensor_id"}
            new_message_number = rumor{"MessageId"}.split(re#:#)[1].as("Number")
            old_message_number = ent:my_seen_messages{sensor_id}.as("Number")
            message_number = (old_message_number + 1 == new_message_number) => 
                                new_message_number | old_message_number
        }
        if rumor.isnull() then noop()
        notfired{
            ent:rumor_messages{sensor_id} := rumor
            ent:my_seen_messages{rumor{"Sensor_id"}} := message_number.klog("message_number")
        }
    }

    rule handle_seen_message{
        select when gossip seen 
        pre{
            message = event:attr("seen_message")
            sender = event:attr("sender_eci")
        }
        if message.isnull() then noop()
        notfired{
            ent:seen_messages{sender} := message
        }
    }
}