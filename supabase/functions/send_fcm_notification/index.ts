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

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // ==========================================
    // 1. BROADCAST NEW FLOOD REPORT (GEOFENCING)
    // ==========================================
    if (table === 'flood_reports' && payload.type === 'INSERT') {
      // Ambil latitude dan longitude menggunakan RPC yang sudah ada
      const { data: reports } = await supabase.rpc('get_active_flood_reports');
      const report = (reports || []).find((r: any) => r.id === record.id);
      
      if (!report) {
        return new Response("OK - Report not found in active list", { status: 200 });
      }

      // Ambil SEMUA fcm_token pengguna, KECUALI si pembuat laporan
      const { data: users } = await supabase
        .from('users')
        .select('fcm_token')
        .neq('id', record.user_id)
        .not('fcm_token', 'is', null);

      if (!users || users.length === 0) {
        return new Response("OK - No users to notify", { status: 200 });
      }

      const tokens = users.map(u => u.fcm_token).filter(t => t);

      if (tokens.length > 0 && admin.apps.length > 0) {
        // Kirim PESAN SILUMAN (Data Message tanpa body notification) 
        // agar HP penerima menghitung jaraknya secara diam-diam (Background Handler)
        const message = {
          data: {
            type: 'flood_alert',
            report_id: record.id,
            latitude: report.latitude.toString(),
            longitude: report.longitude.toString()
          },
          android: {
            priority: 'high' as const
          },
          apns: {
            headers: {
              'apns-priority': '10'
            }
          },
          tokens: tokens, // Maksimal 500 token per request
        };
        
        await admin.messaging().sendEachForMulticast(message);
        console.log(`FCM Broadcast sent to ${tokens.length} devices!`);
      }
      return new Response("OK - Broadcast sent", { status: 200 });
    }

    // ==========================================
    // 2. NOTIFIKASI KOMENTAR & VOTE (PERSONAL)
    // ==========================================
    if (table === 'report_comments' || table === 'report_validations') {
      if (!record.report_id || !record.user_id) {
        return new Response("Missing fields", { status: 200 });
      }

      const { data: report } = await supabase
        .from('flood_reports')
        .select('user_id')
        .eq('id', record.report_id)
        .single();
        
      if (!report || report.user_id === record.user_id) {
        return new Response("OK - Author self-action", { status: 200 });
      }
      
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
      }
      return new Response("OK - Personal notif sent", { status: 200 });
    }

    return new Response("OK", { status: 200 });
  } catch (err) {
    console.error("Error processing webhook:", err);
    return new Response(String(err), { status: 500 });
  }
});
