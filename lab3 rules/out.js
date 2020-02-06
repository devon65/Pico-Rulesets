module.exports = {
  "rid": "wovyn_base",
  "meta": {
    "shares": ["__testing"],
    "use": [
      {
        "kind": "module",
        "rid": "io.picolabs.lesson_keys",
        "alias": "io.picolabs.lesson_keys"
      },
      {
        "kind": "module",
        "rid": "io.picolabs.twilio_v2",
        "alias": "twilio",
        "with": async function (ctx) {
          ctx.scope.set("account_sid", await ctx.applyFn(ctx.scope.get("get"), ctx, [
            await ctx.modules.get(ctx, "keys", "twilio"),
            "account_sid"
          ]));
          ctx.scope.set("auth_token", await ctx.applyFn(ctx.scope.get("get"), ctx, [
            await ctx.modules.get(ctx, "keys", "twilio"),
            "auth_token"
          ]));
        }
      }
    ]
  },
  "global": async function (ctx) {
    ctx.scope.set("__testing", {
      "queries": [{ "name": "__testing" }],
      "events": [{
          "domain": "post",
          "type": "test",
          "attrs": [
            "temp",
            "baro"
          ]
        }]
    });
    ctx.scope.set("temperature_threshold", 70);
    ctx.scope.set("text_to", "12082513706");
    ctx.scope.set("text_from", "16013854081");
    ctx.scope.set("text_message", "Temperature Threshold Exceeded");
  },
  "rules": {
    "process_heartbeat": {
      "name": "process_heartbeat",
      "select": {
        "graph": { "wovyn": { "heartbeat": { "expr_0": true } } },
        "state_machine": {
          "start": [[
              "expr_0",
              "end"
            ]]
        }
      },
      "body": async function (ctx, runAction, toPairs) {
        ctx.scope.set("genericThing", await ctx.applyFn(ctx.scope.get("klog"), ctx, [
          await ctx.applyFn(await ctx.modules.get(ctx, "event", "attr"), ctx, ["genericThing"]),
          "attrs"
        ]));
        var fired = ctx.scope.get("genericThing");
        if (fired) {
          await runAction(ctx, void 0, "send_directive", [
            "say",
            { "data": ctx.scope.get("genericThing") }
          ], []);
        }
        if (fired)
          ctx.emit("debug", "fired");
        else
          ctx.emit("debug", "not fired");
        if (fired) {
          await ctx.raiseEvent({
            "domain": "wovyn",
            "type": "new_temperature_reading",
            "attributes": {
              "temperature": await ctx.applyFn(ctx.scope.get("klog"), ctx, [
                await ctx.applyFn(ctx.scope.get("get"), ctx, [
                  await ctx.applyFn(ctx.scope.get("get"), ctx, [
                    await ctx.applyFn(ctx.scope.get("get"), ctx, [
                      ctx.scope.get("genericThing"),
                      [
                        "data",
                        "temperature"
                      ]
                    ]),
                    [0]
                  ]),
                  "temperatureF"
                ]),
                "Temperature: "
              ]),
              "timestamp": await ctx.applyFn(ctx.scope.get("klog"), ctx, [
                await ctx.applyFn(await ctx.modules.get(ctx, "time", "now"), ctx, []),
                "Timestamp: "
              ])
            },
            "for_rid": undefined
          });
        }
      }
    },
    "find_high_temps": {
      "name": "find_high_temps",
      "select": {
        "graph": { "wovyn": { "new_temperature_reading": { "expr_0": true } } },
        "state_machine": {
          "start": [[
              "expr_0",
              "end"
            ]]
        }
      },
      "body": async function (ctx, runAction, toPairs) {
        ctx.scope.set("temperature", await ctx.applyFn(ctx.scope.get("klog"), ctx, [
          await ctx.applyFn(await ctx.modules.get(ctx, "event", "attr"), ctx, ["temperature"]),
          "find_high_temps reached. temperature: "
        ]));
        ctx.scope.set("timestamp", await ctx.applyFn(ctx.scope.get("klog"), ctx, [
          await ctx.applyFn(await ctx.modules.get(ctx, "event", "attr"), ctx, ["timestamp"]),
          "timestamp: "
        ]));
        ctx.scope.set("temperature_message", await ctx.applyFn(ctx.scope.get(">"), ctx, [
          ctx.scope.get("temperature"),
          ctx.scope.get("temperature_threshold")
        ]) ? "Temperature threshold exceeded!" : "Temperature under threshold");
        var fired = true;
        if (fired) {
          await runAction(ctx, void 0, "send_directive", [
            "say",
            { "data": ctx.scope.get("genericThing") }
          ], []);
        }
        if (fired)
          ctx.emit("debug", "fired");
        else
          ctx.emit("debug", "not fired");
        if (await ctx.applyFn(ctx.scope.get(">"), ctx, [
            ctx.scope.get("temperature"),
            ctx.scope.get("temperature_threshold")
          ]))
          await ctx.raiseEvent({
            "domain": "wovyn",
            "type": "threshold_violation",
            "attributes": undefined,
            "for_rid": undefined
          });
      }
    },
    "send_threshold_violation_message": {
      "name": "send_threshold_violation_message",
      "select": {
        "graph": { "wovyn": { "threshold_violation": { "expr_0": true } } },
        "state_machine": {
          "start": [[
              "expr_0",
              "end"
            ]]
        }
      },
      "body": async function (ctx, runAction, toPairs) {
        var fired = true;
        if (fired) {
          await runAction(ctx, "twilio", "send_sms", [
            ctx.scope.get("text_to"),
            ctx.scope.get("text_from"),
            ctx.scope.get("text_message")
          ], []);
        }
        if (fired)
          ctx.emit("debug", "fired");
        else
          ctx.emit("debug", "not fired");
      }
    }
  }
};
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IiIsInNvdXJjZXNDb250ZW50IjpbXX0=
