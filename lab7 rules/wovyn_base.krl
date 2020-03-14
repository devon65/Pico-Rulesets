ruleset wovyn_base {
    meta {
      shares __testing
      use module io.picolabs.lesson_keys
      use module io.picolabs.twilio_v2 alias twilio
          with account_sid = keys:twilio{"account_sid"}
               auth_token =  keys:twilio{"auth_token"}
      use module sensor_profile alias profile
    }
    global {
        __testing = { "queries": [ { "name": "__testing" } ],
                        "events": [ { "domain": "post", "type": "test",
                                    "attrs": [ "temp", "baro" ] } ] }
        
        notify_managers_threshold_violation = function(threshold, temperature, timestamp){
            subscriptions:established("Tx_role","sensor_manager").map(function(subscription) {
                    host = subscription{"Tx_host"}.defaultsTo(hostname)
                    eci = subscription{"Tx"}
                    url = <<#{host}#{cloud_url}#{eci}/sensor_management/threshold_violation>>.klog("notify_managers URL:")
                    query_map = {"threshold": threshold, "temperature": temperature, "timestamp":timestamp}
                    response = http:post(url, form=query_map)
                    response["content"].decode().klog()
            })
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
        pre{
            temperature =event:attr("temperature")
            timestamp = event:attr("timestamp")
        }
        notify_managers_threshold_violation(profile:temperature_threshold(), temperature, timestamp)
    }  
  
}