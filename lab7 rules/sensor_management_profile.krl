ruleset sensor_management_profile{
    meta{
        use module io.picolabs.lesson_keys
        use module io.picolabs.twilio_v2 alias twilio
            with account_sid = keys:twilio{"account_sid"}
                 auth_token =  keys:twilio{"auth_token"}
    }
    global {
        text_from = "16013854081"
        notification_number = "12082513706"
    }

    rule send_threshold_violation_message {
        select when sensor_management threshold_violation
        pre{
            message = text_message + 
            " Threshold: " + event:attr("threshold") + 
            " Current Temperature: " + event:attr("temperature") + 
            " Time: " + event:attr("timestamp")
        }
        twilio:send_sms(notification_number, text_from, message.klog("Text Message: "))
    }
}