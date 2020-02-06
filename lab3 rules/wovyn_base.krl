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
    
    temperature_threshold = 80
    text_to = "12082513706"
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
        temperature_message = temperature > temperature_threshold => 
        "Temperature threshold exceeded!" | "Temperature under threshold"
    }
    send_directive("say", {"data":temperature_message.klog("New Temperature Message: ")})
    always{
      raise wovyn event "threshold_violation"
        attributes{
          "temperature": temperature,
          "timestamp": timestamp
        }
       if temperature > temperature_threshold
    }
  }

  rule send_threshold_violation_message {
    select when wovyn threshold_violation
    pre{
      message = text_message + 
                " Threshold: " + temperature_threshold + 
                " Current Temperature: " + event:attr("temperature") + 
                " Time: " + event:attr("timestamp")
    }
    twilio:send_sms(text_to, text_from, message.klog("Text Message: "))
  }  

}