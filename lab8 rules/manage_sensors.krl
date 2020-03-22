ruleset manage_sensors {
    meta {
        shares sensors, temperatures, temperature_sensor_reports
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subscriptions
    }
    global {
        default_temp_thresh = 82
        default_notify_number = "12082513706"
        hostname = "http://localhost:8080"
        cloud_url = "/sky/cloud/"
        event_url = "/sky/event/"

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

        temperature_sensor_reports = function() {
            reports = ent:temperature_reports.filter(function(v,k){k.as("Number") >= ent:next_report_id - 5})
            return reports.reverse()
        }
    }

    rule request_sensor_reports {
        select when sensor request_reports
        foreach subscriptions:established("Tx_role","sensor") setting (subscription)
            pre {
                host = subscription{"Tx_host"}.defaultsTo(hostname)
                my_eci = subscription{"Rx"}
                server_eci = subscription{"Tx"}
                report_id = ent:next_report_id.defaultsTo(0).as("Number")
                attrs = {"report_id": report_id, "client_eci": my_eci, "server_eci": server_eci}
                sensor_count = ent:temperature_reports{[report_id, "temperature_sensors"]}.defaultsTo(0).as("Number") + 1
            }
            event:send({"eci": server_eci, 
                        "domain":"sensor", 
                        "type":"send_report", 
                        "attrs":attrs}, host=host)
            always {
                ent:temperature_reports{[report_id, "temperature_sensors"]} := sensor_count
                ent:next_report_id := report_id + 1 on final
            }

    }

    rule collect_sensor_reports {
        select when sensor collect_reports
        pre {
            report_id = event:attr("report_id").klog("AAAAAAAAAAAAAAAAAAAAAAAAAAA")
            temps = event:attr("temperatures")
            sensor_name_id = event:attr("sensor_name_id")
            num_sensor_responses = ent:temperature_reports{[report_id, "responding"]}.defaultsTo(0).as("Number") + 1
        }
        always {
            ent:temperature_reports{[report_id, "responding"]} := num_sensor_responses
            ent:temperature_reports{[report_id, "temperatures", sensor_name_id]} := temps
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