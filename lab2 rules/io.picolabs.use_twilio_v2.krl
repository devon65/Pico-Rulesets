ruleset io.picolabs.use_twilio_v2 {
  meta {
    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
  }
 
  rule test_send_sms {
    select when test new_message
    twilio:send_sms(event:attr("to"),
                    event:attr("from"),
                    event:attr("message")
                   )
  }

  rule test_get_messages {
    select when test get_messages
    pre {
      content = twilio:get_messages(event:attr("To").klog("To: "),
                                    event:attr("From").klog("From: "),
                                    event:attr("PageSize").klog("PageSize: "),
                                    event:attr("Page").klog("Page: "),
                                    event:attr("PageToken").klog("Page Token: ")
                                  )
    }
    send_directive("say", {"data":content})
  }
} 