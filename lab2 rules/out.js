module.exports = {
  "rid": "io.picolabs.twilio_v2",
  "meta": {
    "configure": async function (ctx) {
      ctx.scope.set("account_sid", "");
      ctx.scope.set("auth_token", "");
    },
    "provides": [
      "send_sms",
      "get_messages"
    ]
  },
  "global": async function (ctx) {
    ctx.scope.set("send_sms", ctx.mkAction([
      "to",
      "from",
      "message"
    ], async function (ctx, args, runAction) {
      ctx.scope.set("to", args["to"]);
      ctx.scope.set("from", args["from"]);
      ctx.scope.set("message", args["message"]);
      ctx.scope.set("base_url", "https://" + await ctx.applyFn(ctx.scope.get("as"), ctx, [
        ctx.scope.get("account_sid"),
        "String"
      ]) + ":" + await ctx.applyFn(ctx.scope.get("as"), ctx, [
        ctx.scope.get("auth_token"),
        "String"
      ]) + "@api.twilio.com/2010-04-01/Accounts/" + await ctx.applyFn(ctx.scope.get("as"), ctx, [
        ctx.scope.get("account_sid"),
        "String"
      ]) + "/");
      var fired = true;
      if (fired) {
        await runAction(ctx, "http", "post", {
          "0": await ctx.applyFn(ctx.scope.get("+"), ctx, [
            ctx.scope.get("base_url"),
            "Messages.json"
          ]),
          "form": {
            "From": ctx.scope.get("from"),
            "To": ctx.scope.get("to"),
            "Body": ctx.scope.get("message")
          }
        }, []);
      }
      return [];
    }));
    ctx.scope.set("get_messages", ctx.mkFunction([
      "to",
      "from",
      "page_size",
      "page"
    ], async function (ctx, args) {
      ctx.scope.set("to", args["to"]);
      ctx.scope.set("from", args["from"]);
      ctx.scope.set("page_size", args["page_size"]);
      ctx.scope.set("page", args["page"]);
      ctx.scope.set("query_map", {});
      ctx.scope.set("query_map", await ctx.applyFn(ctx.scope.get("=="), ctx, [
        await ctx.applyFn(ctx.scope.get("isnull"), ctx, [ctx.scope.get("to")]),
        false
      ]) ? await ctx.applyFn(ctx.scope.get("put"), ctx, [
        ctx.scope.get("query_map"),
        "To",
        ctx.scope.get("to")
      ]) : ctx.scope.get("query_map"));
      ctx.scope.set("query_map", await ctx.applyFn(ctx.scope.get("=="), ctx, [
        await ctx.applyFn(ctx.scope.get("isnull"), ctx, [ctx.scope.get("from")]),
        false
      ]) ? await ctx.applyFn(ctx.scope.get("put"), ctx, [
        ctx.scope.get("query_map"),
        "From",
        ctx.scope.get("to")
      ]) : ctx.scope.get("query_map"));
      ctx.scope.set("query_map", await ctx.applyFn(ctx.scope.get("=="), ctx, [
        await ctx.applyFn(ctx.scope.get("isnull"), ctx, [ctx.scope.get("page_size")]),
        false
      ]) ? await ctx.applyFn(ctx.scope.get("put"), ctx, [
        ctx.scope.get("query_map"),
        "PageSize",
        ctx.scope.get("to")
      ]) : ctx.scope.get("query_map"));
      ctx.scope.set("query_map", await ctx.applyFn(ctx.scope.get("=="), ctx, [
        await ctx.applyFn(ctx.scope.get("isnull"), ctx, [ctx.scope.get("page")]),
        false
      ]) ? await ctx.applyFn(ctx.scope.get("put"), ctx, [
        ctx.scope.get("query_map"),
        "Page",
        ctx.scope.get("to")
      ]) : ctx.scope.get("query_map"));
      ctx.scope.set("base_url", "https://" + await ctx.applyFn(ctx.scope.get("as"), ctx, [
        ctx.scope.get("account_sid"),
        "String"
      ]) + ":" + await ctx.applyFn(ctx.scope.get("as"), ctx, [
        ctx.scope.get("auth_token"),
        "String"
      ]) + "@api.twilio.com/2010-04-01/Accounts/" + await ctx.applyFn(ctx.scope.get("as"), ctx, [
        ctx.scope.get("account_sid"),
        "String"
      ]) + "/Messages.json");
      return await ctx.applyFn(ctx.scope.get("decode"), ctx, [await ctx.applyFn(ctx.scope.get("get"), ctx, [
          await ctx.applyFn(await ctx.modules.get(ctx, "http", "get"), ctx, {
            "0": ctx.scope.get("base_url"),
            "qs": ctx.scope.get("query_map")
          }),
          "content"
        ])]);
    }));
  },
  "rules": {}
};
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IiIsInNvdXJjZXNDb250ZW50IjpbXX0=
