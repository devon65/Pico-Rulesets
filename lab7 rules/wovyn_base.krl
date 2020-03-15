ruleset wovyn_base {
    meta {
        use module io.picolabs.subscription alias subscriptions
        use module io.picolabs.lesson_keys
        use module io.picolabs.twilio_v2 alias twilio
            with account_sid = keys:twilio{"account_sid"}
                auth_token =  keys:twilio{"auth_token"}
        use module sensor_profile alias profile
    }
    global {
        hostname = "http://localhost:8080"
        event_url = "/sky/event/"
        
        notify_manager_threshold_violation = defaction(url, query_map){
            http:post(url, form=query_map)
        }
    
        text_to = function(){
            result = profile:profile_info()
            return result{"notify_number"}
        }
        text_from = "16013854081"
        text_message = "Temperature Threshold Exceeded"
    }
   
    rule process_heartbeat {
      select when wovyn heartbeat 
      pre {
        genericThing = event:attr("genericThing").klog("Attrs: ")
      }
      if genericThing then 
        send_directive("say", {"data":genericThing})
  
      fired {
        raise wovyn event "new_temperature_reading"
          attributes {
            "temperature": genericThing{["data", "temperature"]}[0]{"temperatureF"}.klog("Temperature: "),
            "timestamp": time:now().klog("Timestamp: ")
          }
      }
    }
  
    rule find_high_temps {
        select when wovyn new_temperature_reading
        pre {
            temperature = event:attr("temperature")
            timestamp = event:attr("timestamp")
            temperature_message = temperature > profile:temperature_threshold() => 
            "Temperature threshold exceeded!" | "Temperature under threshold"
        }
        send_directive("say", {"data":temperature_message.klog("New Temperature Message: ")})
        always{
            raise wovyn event "threshold_violation"
            attributes{
                "temperature": temperature,
                "timestamp": timestamp
            }
            if temperature > profile:temperature_threshold()
        }
    }
  
    rule send_threshold_violation_message {
        select when wovyn threshold_violation
            foreach subscription:established("Tx_role","sensor_manager") setting (sub)
            pre{
                temperature =event:attr("temperature")
                timestamp = event:attr("timestamp")
                host = sub{"Tx_host"}.defaultsTo(hostname)
                eci = sub{"Tx"}
                url = <<#{host}#{event_url}#{eci}/sensor/sensor_management/threshold_violation>>.klog("notify_managers URL:")
                query_map = {"threshold": profile:temperature_threshold(), "temperature": temperature, "timestamp":timestamp}
            }
            notify_manager_threshold_violation(url, query_map)
    }  
  
}