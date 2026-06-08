import "npm:firebase-admin@11.11.1";
import { createClient } from "npm:@supabase/supabase-js@2.39.3";
import admin from "npm:firebase-admin@11.11.1";

const serviceAccountString = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');

if (serviceAccountString && !admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(serviceAccountString))
  });
}

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    console.log("Webhook payload:", payload);

    if (!['INSERT', 'UPDATE'].includes(payload.type)) {
      return new Response("OK", { status: 200 });
    }

    const record = payload.record;
    const table = payload.table;

    // Keduanya punya report_id dan user_id
    if (!record.report_id || !record.user_id) {
      return new Response("Missing fields", { status: 200 });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Dapatkan pemilik postingan
    const { data: report } = await supabase
      .from('flood_reports')
      .select('user_id')
      .eq('id', record.report_id)
      .single();
      
    // Jangan kirim notif jika kita komen/vote postingan sendiri
    if (!report || report.user_id === record.user_id) {
      return new Response("OK - Author self-action", { status: 200 });
    }
    
    // Dapatkan token pemilik dan nama pembuat aksi
    const [ownerRes, actorRes] = await Promise.all([
      supabase.from('users').select('fcm_token').eq('id', report.user_id).single(),
      supabase.from('users').select('full_name').eq('id', record.user_id).single()
    ]);

    const token = ownerRes.data?.fcm_token;
    const actorName = actorRes.data?.full_name || 'Seseorang';

    if (!token) {
      return new Response("OK - Owner has no FCM token", { status: 200 });
    }

    let title = "";
    let body = "";

    if (table === 'report_comments' && payload.type === 'INSERT') {
      title = "Komentar Baru 💬";
      body = `${actorName} mengomentari laporan banjir Anda.`;
    } else if (table === 'report_validations' && record.vote_type === 'upvote') {
      title = "Laporan Divalidasi ✅";
      body = `${actorName} mengonfirmasi kebenaran laporan Anda.`;
    } else if (table === 'report_validations' && record.vote_type === 'downvote') {
      title = "Laporan Diragukan ❌";
      body = `${actorName} menekan tombol downvote pada laporan Anda.`;
    } else {
      return new Response("OK - Action ignored", { status: 200 });
    }

    if (admin.apps.length > 0) {
      await admin.messaging().send({
        notification: { title, body },
        token: token,
      });
      console.log("FCM Notification sent!");
    } else {
      console.error("Firebase not initialized! Missing FIREBASE_SERVICE_ACCOUNT.");
    }

    return new Response("OK", { status: 200 });
  } catch (err) {
    console.error("Error processing webhook:", err);
    return new Response(String(err), { status: 500 });
  }
});
