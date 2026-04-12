// supabase/functions/send_notification/index.ts
// Deploy: supabase functions deploy send_notification

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  try {
    const { token, title, body } = await req.json();

    if (!token || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing token, title, or body" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const serverKey = Deno.env.get("FCM_SERVER_KEY");
    if (!serverKey) {
      return new Response(
        JSON.stringify({ error: "FCM_SERVER_KEY not set" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Authorization": `key=${serverKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        to: token,
        priority: "high",
        notification: {
          title,
          body,
          sound: "default",
          badge: "1",
        },
        data: {
          title,
          body,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      }),
    });

    const result = await response.json();
    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});