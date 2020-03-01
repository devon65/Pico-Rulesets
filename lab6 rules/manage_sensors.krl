ruleset manage_sensors {
    meta {
        shares sensors
        use module io.picolabs.wrangler alias wrangler
    }
    global {
        default_temp_thresh = 82
        default_notify_number = "12082513706"

        sensors = function() {
            return ent:sensors
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
                            "rids": ["sensor_profile", "temperature_store", "wovyn_base"]  }
        }
    }

    rule on_sensor_created {
        select when wrangler child_initialized
        pre {
            eci = event:attr("eci")
            id = event:attr("id")
            name = event:attr("name")
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
        }
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