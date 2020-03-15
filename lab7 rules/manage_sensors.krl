ruleset manage_sensors {
    meta {
        shares sensors, temperatures
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subscriptions
    }
    global {
        default_temp_thresh = 82
        default_notify_number = "12082513706"
        hostname = "http://localhost:8080"
        cloud_url = "/sky/cloud/"


        sensors = function() {
            return subscriptions:established("Tx_role","sensor")
        }

        temperatures = function() {
            all_temperatures = subscriptions:established("Tx_role","sensor").map(function(subscription) {
                host = subscription{"Tx_host"}.defaultsTo(hostname)
                eci = subscription{"Tx"}
                response = http:get(<<#{host}#{cloud_url}#{eci}/temperature_store/temperatures>>.klog("getTemp URL:"))
                response["content"].decode().klog()
            })
            return all_temperatures
        }

        get_temp_attrs = function(eci, tx_host){
            attrs = { "eci": eci, "eid": "subscription",
            "domain": "sensor", "type": "get_temps" }
            attrs = tx_host.isnull() == false => attrs.put("Tx_host", tx_host) | attrs
            return attrs
        }
    }

    rule sensor_introduction {
        select when sensor cousin_sensor
        pre {
            eci = event:attr("eci")
            name = event:attr("name")
        }
    }
   
    rule sensor_already_exists {
        select when sensor new_sensor
        pre {
            sensor_name = event:attr("sensor_name").defaultsTo("Sensor")
            exists = ent:sensors >< sensor_name
        }
        if exists then
            send_directive("sensor_ready", {"sensor_name": sensor_name})
    }

    rule sensor_needed {
        select when sensor new_sensor
        pre {
            sensor_name = event:attr("sensor_name").defaultsTo("Sensor")
            exists = ent:sensors >< sensor_name
        }
        if not exists 
        then
            noop()
        fired {
            ent:sensors := ent:sensors.defaultsTo({});
            ent:sensors{[sensor_name]} := {}
            raise wrangler event "child_creation"
                attributes { "name": sensor_name,
                            "color": "#ffff00",
                            "Tx_role": "sensor",
                            "rids": ["sensor_profile", "temperature_store", "wovyn_base"]  }
        }
    }

    rule on_sensor_created {
        select when wrangler child_initialized
        pre {
            eci = event:attr("eci")
            id = event:attr("id")
            name = event:attr("name")
            tx_role = event:attr("Tx_role").defaultsTo("unknown")
            exists = ent:sensors >< name
        }
        if exists then
            event:send({"eci": eci, 
                        "domain":"sensor", 
                        "type":"profile_updated", 
                        "attrs":{"name": name,
                                "temperature_threshold": default_temp_thresh,
                                "notify_number": default_notify_number}})
        fired{
            ent:sensors{[name]} := {"eci":eci, "id":id}
            raise wrangler event "subscription" attributes
                { "name" : name,
                    "Rx_role": "sensor_manager",
                    "Tx_role": tx_role,
                    "channel_type": "subscription",
                    "wellKnown_Tx" : eci
                }
        }
    }

    rule subscribe_to_outside_sensor {
        select when sensor subscribe_outside_sensor
        pre{
            ip_addr = event:attr("ip")
            name = event:attr("name")
            eci = event:attr("eci")
        }
        always{
            raise wrangler event "subscription" attributes
                {   "name" : name,
                    "Rx_role": "sensor_manager",
                    "Tx_role": "sensor",
                    "channel_type": "subscription",
                    "wellKnown_Tx" : eci,
                    "Tx_host": <<http://#{ip_addr}>>
                }
        }
        
    }

    rule get_managed_temps {
        select when sensor get_managed_temps
        foreach Subscriptions:established("Tx_role","sensor") setting (subscription)
          pre {
            thing_subs = subscription.klog("subs")
            tx_host = subscription{"Tx_host"}
            attrs = get_temp_attrs(subscription("Tx"), tx_host)
          }
          event:send(attrs)
    }

    rule delete_sensor{
        select when sensor unneeded_sensor
        pre {
            sensor_name = event:attr("sensor_name")
            exists = ent:sensors >< sensor_name
        }
        if exists then
            send_directive("deleting_sensor", {"sensor_name":sensor_name})
        fired {
            raise wrangler event "child_deletion"
                attributes {"name": sensor_name};
            clear ent:sensors{[sensor_name]}
        }
    }
}