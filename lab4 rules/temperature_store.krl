ruleset temperature_store {
    meta {
      shares temperatures, threshold_violations, inrange_temperatures
      provides temperatures, threshold_violations, inrange_temperatures
    }
    global {
      temperature_threshold = 80

      temperatures = function() {
        return ent:temperature_entries.values()
      }

      threshold_violations = function() {
        return ent:violation_entries.values()
      }

      inrange_temperatures = function() {
        violation_keys = ent:violation_entries.keys()
        filter_violations = function(v, k){
            not violation_keys.any(function(x){x == k})
        }
        result = ent:temperature_entries.filter(filter_violations)
        return result
      }
    }
   
    rule collect_temperatures {
      select when wovyn new_temperature_reading 
      pre{
        temperature = event:attr("temperature")
        timestamp = event:attr("timestamp")
      }
      always{
          ent:temperature_entries{timestamp} := [timestamp, temperature]
          current_entries = ent:temperature_entries.klog("Temperature Entries: ")
      }
    }

    rule collect_threshold_violations {
        select when wovyn threshold_violation
        pre{
            temperature = event:attr("temperature")
            timestamp = event:attr("timestamp")
        }
        always{
            ent:violation_entries{timestamp} := [timestamp, temperature]
            current_entries = ent:violation_entries.klog("Violation Entries: ")
        }
    }

    rule clear_temperatures {
        select when sensor reading_reset
        send_directive("say", {"Clearing Temperature Readings".klog(): ":)"})
        always{
            clear ent:temperature_entries
            clear ent:temperature_entries
        }
    }
}