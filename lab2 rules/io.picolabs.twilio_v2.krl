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

      get_messages = function(to, from, page_size, page, page_token) {
        query_map = {}
        query_map = to.isnull() == false => query_map.put("To", to) | query_map
        query_map = from.isnull() == false => query_map.put("From", from) | query_map
        query_map = page_size.isnull() == false => query_map.put("PageSize", page_size) | query_map
        query_map = page.isnull() == false => query_map.put("Page", page) | query_map
        query_map = page_token.isnull() == false => query_map.put("PageToken", page_token) | query_map

        base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json>>
        http:get(base_url,
            qs = query_map.klog("Query Map: ")){"content"}.decode()
      }
    }
  }