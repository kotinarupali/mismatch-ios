const confirmPage = "https://mismatch-cards.kotinarupali.workers.dev/account-confirmed";
const resetPage = "https://mismatch-cards.kotinarupali.workers.dev/reset-password";

const font = "ui-rounded,'Avenir Next','Nunito','Segoe UI',sans-serif";

export function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

// Same Gmail account Supabase Auth uses. SMTP_PASS is that account's app password.
export async function sendSmtpEmail(message: {
  to: string;
  subject: string;
  html: string;
}): Promise<boolean> {
  const pass = Deno.env.get("SMTP_PASS") ?? "";
  const user = Deno.env.get("SMTP_USER") ?? "susoutapp@gmail.com";
  const from = Deno.env.get("SMTP_FROM") ?? `Sus Out App <${user}>`;
  const host = Deno.env.get("SMTP_HOST") ?? "smtp.gmail.com";
  const port = Number(Deno.env.get("SMTP_PORT") ?? "465");
  if (!pass || !isEmail(message.to) || !isEmail(user)) return false;
  if (/[\r\n]/.test(message.subject) || /[\r\n]/.test(from)) return false;

  let conn: Deno.Conn | null = null;
  try {
    conn = await Deno.connectTls({ hostname: host, port });
    await readSmtp(conn);
    await smtpCommand(conn, "EHLO susout", "250");
    await smtpCommand(conn, "AUTH LOGIN", "334");
    await smtpCommand(conn, btoa(user), "334");
    await smtpCommand(conn, btoa(pass), "235");
    await smtpCommand(conn, `MAIL FROM:<${user}>`, "250");
    await smtpCommand(conn, `RCPT TO:<${message.to}>`, "250");
    await smtpCommand(conn, "DATA", "354");
    const payload = new TextEncoder().encode(mime(from, message.to, message.subject, message.html));
    let sent = 0;
    while (sent < payload.length) sent += await conn.write(payload.subarray(sent));
    const accepted = await readSmtp(conn);
    if (!lastLine(accepted).startsWith("250")) return false;
    await smtpCommand(conn, "QUIT", "221");
    return true;
  } catch {
    return false;
  } finally {
    try {
      conn?.close();
    } catch {
      // The message was already accepted or the connection is gone.
    }
  }
}

export function accountDeletedMessage(email: string): { subject: string; html: string } {
  const safeEmail = escapeHtml(email);
  return {
    subject: "Your Sus Out account was deleted",
    html: susOutEmail({
      preheader: "Your Sus Out custom-pack account was deleted.",
      title: "Your account was deleted",
      paragraphs: [
        `Sus Out deleted the custom-pack account for <span style="color:#ffffff;">${safeEmail}</span>, including the packs saved with it.`,
      ],
      footnote: "If you did this, you can ignore this email. If you did not, create a new account in Game Settings.",
    }),
  };
}

export function authEmailMessage(input: {
  action: string;
  email: string;
  tokenHash: string;
  redirectTo: string;
  supabaseUrl: string;
}): { subject: string; html: string } {
  const redirect = safeRedirect(input.action, input.redirectTo);
  const link = `${input.supabaseUrl}/auth/v1/verify?token=${encodeURIComponent(input.tokenHash)}&type=${encodeURIComponent(input.action)}&redirect_to=${encodeURIComponent(redirect)}`;
  const safeEmail = escapeHtml(input.email);
  if (input.action === "recovery") {
    return {
      subject: "Reset your Sus Out password",
      html: susOutEmail({
        preheader: "Choose a new password for your Sus Out account.",
        title: "Reset your password",
        paragraphs: [
          `Sus Out sent this email because someone asked to reset the password for <span style="color:#ffffff;">${safeEmail}</span>.`,
        ],
        actionHref: link,
        actionLabel: "Choose a new password",
        footnote: "If you did not ask for this, you can ignore this email. Your password will stay the same.",
      }),
    };
  }
  return {
    subject: "Confirm your Sus Out account",
    html: susOutEmail({
      preheader: "Confirm the email for your Sus Out custom-pack account.",
      title: "Confirm your account",
      paragraphs: [
        `Sus Out sent this email because a custom-pack account was created for <span style="color:#ffffff;">${safeEmail}</span>.`,
        "Confirm this address so you can sign in and keep those packs with the account.",
      ],
      actionHref: link,
      actionLabel: "Confirm email",
      footnote: "If you did not create a Sus Out account, you can ignore this email.",
    }),
  };
}

function susOutEmail(input: {
  preheader: string;
  title: string;
  paragraphs: string[];
  actionHref?: string;
  actionLabel?: string;
  footnote: string;
}): string {
  const copy = input.paragraphs
    .map((paragraph, index) => {
      const margin = index === input.paragraphs.length - 1 ? "0" : "0 0 12px";
      return `<p style="margin:${margin};">${paragraph}</p>`;
    })
    .join("");
  const action = input.actionHref && input.actionLabel
    ? `<tr><td style="padding:22px 28px 8px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
          <tr>
            <td align="center" bgcolor="#7347f2" style="border-radius:20px;background-color:#7347f2;background-image:linear-gradient(135deg,#7347f2,#d95294);">
              <a href="${escapeHtml(input.actionHref)}" style="display:block;padding:14px 18px;font-family:${font};font-size:17px;line-height:1.2;font-weight:700;color:#ffffff;text-decoration:none;">${escapeHtml(input.actionLabel)}</a>
            </td>
          </tr>
        </table>
      </td></tr>`
    : "";
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="dark">
  <meta name="supported-color-schemes" content="dark">
  <title>${escapeHtml(input.title)}</title>
</head>
<body style="margin:0;padding:0;background-color:#1f1433;color:#ffffff;">
  <div style="display:none;max-height:0;overflow:hidden;mso-hide:all;">${escapeHtml(input.preheader)}</div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#1f1433" style="background-color:#1f1433;background-image:radial-gradient(ellipse at 8% 100%, rgba(250,115,140,0.38), rgba(250,115,140,0) 52%),radial-gradient(ellipse at 100% 100%, rgba(140,92,255,0.42), rgba(140,92,255,0) 50%),linear-gradient(#381f57,#1f1433);">
    <tr>
      <td align="center" style="padding:36px 16px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#242642" style="max-width:440px;background-color:#242642;border:1px solid #3a3c55;border-radius:24px;">
          <tr>
            <td height="8" bgcolor="#7347f2" style="height:8px;line-height:8px;font-size:0;background-color:#7347f2;background-image:linear-gradient(90deg,#7347f2,#d95294);border-radius:24px 24px 0 0;">&nbsp;</td>
          </tr>
          <tr>
            <td style="padding:28px 28px 4px;font-family:${font};">
              <div style="font-size:13px;line-height:1;font-weight:700;letter-spacing:0.16em;color:#8c5cff;">SUS OUT</div>
              <h1 style="margin:16px 0 0;font-size:28px;line-height:1.15;font-weight:700;color:#ffffff;">${escapeHtml(input.title)}</h1>
            </td>
          </tr>
          <tr>
            <td style="padding:12px 28px 0;font-family:${font};font-size:16px;line-height:1.45;color:#c9c9d6;">${copy}</td>
          </tr>
          ${action}
          <tr>
            <td style="padding:18px 28px 28px;font-family:${font};font-size:13px;line-height:1.45;color:#a7a7b8;">${escapeHtml(input.footnote)}</td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

function safeRedirect(action: string, redirectTo: string): string {
  if (redirectTo.startsWith("https://") && !redirectTo.includes("localhost") && !redirectTo.includes("127.0.0.1")) {
    return redirectTo;
  }
  return action === "recovery" ? resetPage : confirmPage;
}

function isEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function lastLine(response: string): string {
  const lines = response.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  return lines[lines.length - 1] ?? "";
}

async function readSmtp(conn: Deno.Conn): Promise<string> {
  const buffer = new Uint8Array(4096);
  const decoder = new TextDecoder();
  let text = "";
  while (true) {
    const read = await conn.read(buffer);
    if (read === null) break;
    text += decoder.decode(buffer.subarray(0, read), { stream: true });
    if (/^\d{3} /.test(lastLine(text))) break;
  }
  return text;
}

async function smtpCommand(conn: Deno.Conn, command: string, expected: string): Promise<void> {
  const payload = new TextEncoder().encode(`${command}\r\n`);
  let sent = 0;
  while (sent < payload.length) {
    sent += await conn.write(payload.subarray(sent));
  }
  const response = await readSmtp(conn);
  if (!lastLine(response).startsWith(expected)) throw new Error("smtp");
}

function mime(from: string, to: string, subject: string, html: string): string {
  const stuffed = html.replace(/^\./gm, "..").replace(/\n/g, "\r\n");
  return [
    `From: ${from}`,
    `To: ${to}`,
    `Subject: ${subject}`,
    `Date: ${new Date().toUTCString()}`,
    "MIME-Version: 1.0",
    "Content-Type: text/html; charset=UTF-8",
    "Content-Transfer-Encoding: 8bit",
    "",
    stuffed,
    ".",
    "",
  ].join("\r\n");
}
