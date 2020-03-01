ruleset manage_sensors {
    meta {
        use module io.picolabs.wrangler alias wrangler
    }
    global {
        
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
        }
        always{
            ent:sensors := ent:sensors.defaultsTo({});
            ent:sensors{[sensor_name]} := {"eci":eci, "id":id}
        }
    }
}