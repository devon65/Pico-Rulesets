ruleset sensor_profile {
    meta {
        shares profile_info
        provides sensor_name, sensor_location, temperature_threshold, notify_number
    }
    global {
        default_location = "Home"
        default_name = "User1"
        default_temp_thresh = 75
        default_notify_number = "12082513706"

        sensor_location = function() {
            return ent:location.defaultsTo(default_location)
        }
        sensor_name = function() {
            return ent:name.defaultsTo(default_name)
        }
        temperature_threshold = function(){
            return ent:temper_thresh.defaultsTo(default_temp_thresh)
        }
        notify_number = function() {
            return ent:notify_number.defaultsTo(default_notify_number)
        }

        profile_info = function() {
            result = {"location": sensor_location(),
                     "name": sensor_name(),
                     "temperature_threshold": temperature_threshold(),
                     "notify_number": notify_number()
            }
            return result
        }
    }
   
    rule update_profile {
        select when sensor profile_updated 
        pre{
            t_location = event:attr("location").defaultsTo(sensor_location())
            t_name = event:attr("name").defaultsTo(sensor_name())
            t_temper_thresh = event:attr("temperature_threshold").as("Number").defaultsTo(temperature_threshold())
            t_notify_number = event:attr("notify_number").defaultsTo(notify_number())
        }
        send_directive("say", {"data":"Updating Profile"})
        always{
            ent:location := t_location
            ent:name := t_name
            ent:temper_thresh := t_temper_thresh
            ent:notify_number := t_notify_number
        }
    }
  
  }