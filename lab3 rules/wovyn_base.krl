ruleset wovyn_base {
  meta {
    shares __testing
    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "post", "type": "test",
                              "attrs": [ "temp", "baro" ] } ] }
    
    temperature_threshold = 70
    text_to = "12082513706"
    text_from = "16013854081"
    text_message = "Temperature Threshold Exceeded"
  }
 
  rule process_heartbeat {
    select when wovyn heartbeat 
    pre {
      genericThing = event:attr("genericThing").klog("attrs")
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
        temperature = event:attr("temperature").klog("find_high_temps reached. temperature: ")
        timestamp = event:attr("timestamp").klog("timestamp: ")
        temperature_message = temperature > temperature_threshold => 
        "Temperature threshold exceeded!" | "Temperature under threshold"
    }
    send_directive("say", {"data":genericThing})
    always{
      raise wovyn event "threshold_violation" if temperature > temperature_threshold
    }
  }

  rule send_threshold_violation_message {
    select when wovyn threshold_violation
    twilio:send_sms(text_to, text_from, text_message)
  }  

}