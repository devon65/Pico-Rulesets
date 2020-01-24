ruleset io.picolabs.twilio_v2 {
    meta {
      configure using account_sid = ""
                      auth_token = ""
      provides
          send_sms,
          get_messages
    }
   
    global {
      send_sms = defaction(to, from, message) {
         base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
         http:post(base_url + "Messages.json", form = {
                  "From":from,
                  "To":to,
                  "Body":message
              })
      }

      get_messages = function(to, from, page_size) {
        
        base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}//Messages.json>>
        http:get(base_url + "Messages.json", form = {
                 "From":from,
                 "To":to
             })
      }
    }
  }