import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FIREBASE_CLIENT_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL")!;
const FIREBASE_PRIVATE_KEY = Deno.env.get("FIREBASE_PRIVATE_KEY")!.replace(/\\n/g, '\n');
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;

async function getAccessToken(): Promise<string> {
  const pemBody = FIREBASE_PRIVATE_KEY
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: FIREBASE_CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");

  const headerB64 = encode(header);
  const payloadB64 = encode(payload);
  const signingInput = `${headerB64}.${payloadB64}`;

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${signingInput}.${signatureB64}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  console.log("OAuth token response:", JSON.stringify(tokenData));

  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
  }

  return tokenData.access_token;
}

serve(async (req) => {
  try {
    const payload = await req.json();
    console.log("Webhook payload received:", JSON.stringify(payload));

    const alert = payload.record;
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const patientUserId: string = alert.patient_user_id;

    console.log("Patient user ID:", patientUserId);

    const { data: patientUser } = await supabase
      .from("users")
      .select("full_name")
      .eq("id", patientUserId)
      .single();

    const { data: doctorConnections } = await supabase
      .from("doctor_patient_connections")
      .select("doctor_id")
      .eq("patient_id", patientUserId)
      .eq("status", "accepted")
      .eq("is_sharing", true);

    const { data: guardianConnections } = await supabase
      .from("guardian_patient_connections")
      .select("guardian_id")
      .eq("patient_id", patientUserId)
      .eq("status", "accepted")
      .eq("is_sharing", true);

    const doctorIds = (doctorConnections ?? []).map((r: any) => r.doctor_id);
    const guardianIds = (guardianConnections ?? []).map((r: any) => r.guardian_id);
    const allUserIds: string[] = [patientUserId, ...doctorIds, ...guardianIds];

    console.log("All user IDs to notify:", allUserIds);

    const { data: tokenRows } = await supabase
      .from("device_tokens")
      .select("fcm_token")
      .in("user_id", allUserIds);

    console.log("Token rows found:", JSON.stringify(tokenRows));

    if (!tokenRows || tokenRows.length === 0) {
      console.log("No tokens found, exiting");
      return new Response("No tokens found", { status: 200 });
    }

    const isCritical = alert.severity === "critical";
    const patientName = patientUser?.full_name ?? "Patient";
    const title = isCritical
      ? `🚨 ${patientName}: ${alert.title ?? 'Critical Alert'}`
      : `⚠️ ${patientName}: ${alert.title ?? 'Warning'}`;
    const body = alert.message ?? `Glucose: ${alert.glucose_value_at_trigger} mg/dL`;

    console.log("Getting FCM access token...");
    const accessToken = await getAccessToken();
    console.log("Got access token successfully");

    const results = await Promise.all(
      tokenRows.map(async (r: any) => {
        const fcmRes = await fetch(
          `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify({
              message: {
                token: r.fcm_token,
                notification: { title, body },
                data: {
                  severity: alert.severity ?? "warning",
                  patient_user_id: patientUserId,
                  alert_id: String(alert.id),
                  glucose_value: String(alert.glucose_value_at_trigger ?? ""),
                  alert_type: alert.alert_type ?? "",
                },
                android: {
                  priority: "high",
                  notification: {
                    channel_id: isCritical ? "glucose_critical" : "glucose_warning",
                    sound: "default",
                  },
                },
              },
            }),
          }
        );
        const result = await fcmRes.json();
        console.log("FCM send result:", JSON.stringify(result));
        return result;
      })
    );

    return new Response(JSON.stringify({ success: true, results }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });

  } catch (err) {
    console.error("Edge function error:", String(err));
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});