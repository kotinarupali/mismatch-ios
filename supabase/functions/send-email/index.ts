// Unused while the Gmail SMTP server in the Supabase dashboard sends confirm and reset mail.
// https://supabase.com/docs/guides/auth/auth-hooks/send-email-hook
import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";
import { authEmailMessage, sendSmtpEmail } from "../_shared/mail.ts";

const hookSecret = () => (Deno.env.get("SEND_EMAIL_HOOK_SECRET") ?? "").replace("v1,whsec_", "");

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return Response.json({ error: "method" }, { status: 405 });
  }

  const payload = await request.text();
  const headers = Object.fromEntries(request.headers);
  let verified: {
    user: { email?: string };
    email_data: {
      token_hash: string;
      redirect_to: string;
      email_action_type: string;
    };
  };
  try {
    verified = new Webhook(hookSecret()).verify(payload, headers) as typeof verified;
  } catch {
    return Response.json({ error: { message: "Invalid signature." } }, { status: 401 });
  }

  const email = verified.user.email ?? "";
  const action = verified.email_data.email_action_type;
  const message = authEmailMessage({
    action,
    email,
    tokenHash: verified.email_data.token_hash,
    redirectTo: verified.email_data.redirect_to,
    supabaseUrl: Deno.env.get("SUPABASE_URL") ?? "",
  });
  const sent = await sendSmtpEmail({ to: email, subject: message.subject, html: message.html });
  if (!sent) {
    return Response.json({ error: { message: "Couldn't send the email." } }, { status: 500 });
  }
  return Response.json({});
});
