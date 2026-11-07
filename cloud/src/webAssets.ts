import indexHtmlTemplate from "../public/index.html";
import privacyHtml from "../public/privacy.html";
import cardCss from "../public/card.css";
import cardJs from "../public/card.js";
import artAppIcon from "../public/art-app-icon.jpg";
import artInsider from "../public/art-insider.jpg";
import artMismatch from "../public/art-mismatch.jpg";
import artGhost from "../public/art-ghost.jpg";

export function joinPageHtml(token: string): string {
  return indexHtmlTemplate.replace("{{TOKEN}}", token);
}

export function resetPasswordHtml(): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <meta name="theme-color" content="#0f1224">
  <title>Sus Out — New password</title>
  <link rel="icon" href="/art/app-icon.jpg">
  <style>
    body { margin: 0; min-height: 100vh; background: #0f1224; color: #fff; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
    .screen { max-width: 420px; margin: 0 auto; padding: 48px 24px; text-align: center; }
    h1 { font-size: 28px; margin: 0 0 12px; }
    p, label { color: #c7c9d9; line-height: 1.4; }
    form { display: grid; gap: 12px; margin-top: 24px; text-align: left; }
    input { font: inherit; padding: 12px 14px; border-radius: 12px; border: 0; background: #1c2140; color: #fff; }
    button { font: inherit; padding: 12px 14px; border: 0; border-radius: 12px; background: #7c6bff; color: #fff; }
    .hidden { display: none; }
  </style>
</head>
<body>
  <main class="screen">
    <h1>Choose a new password</h1>
    <p id="status">Use at least 6 characters, then open Sus Out and sign in.</p>
    <form id="reset-form">
      <label for="password">New password</label>
      <input id="password" type="password" autocomplete="new-password" required>
      <button type="submit">Save password</button>
    </form>
  </main>
  <script>
    const hash = new URLSearchParams(window.location.hash.replace(/^#/, ""));
    const query = new URLSearchParams(window.location.search);
    const accessToken = hash.get("access_token") || "";
    const tokenHash = query.get("token_hash") || "";
    const linkError = query.get("error_description") || hash.get("error_description") || "";
    const status = document.getElementById("status");
    const form = document.getElementById("reset-form");
    history.replaceState(null, "", window.location.pathname);

    function show(message, hideForm) {
      status.textContent = message;
      form.classList.toggle("hidden", hideForm);
    }

    if (linkError) {
      show("This reset link is invalid or has expired. Request a new one in Sus Out.", true);
    } else if (!accessToken && !tokenHash) {
      show("Open the reset link from your email on this page.", true);
    }

    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      const password = document.getElementById("password").value;
      const length = new TextEncoder().encode(password).length;
      if (length < 6) {
        show("Use at least 6 characters.", false);
        return;
      }
      if (length > 72) {
        show("Use at most 72 characters.", false);
        return;
      }
      const response = await fetch("/api/account/password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ accessToken, tokenHash, password })
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) {
        show(payload.message || "This reset link is invalid or has expired.", false);
        return;
      }
      show("Password saved. Open Sus Out and sign in.", true);
    });
  </script>
</body>
</html>`;
}

export function accountConfirmedHtml(): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <meta name="theme-color" content="#0f1224">
  <title>Sus Out — Email confirmed</title>
  <link rel="icon" href="/art/app-icon.jpg">
  <style>
    body { margin: 0; min-height: 100vh; background: #0f1224; color: #fff; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
    .screen { max-width: 420px; margin: 0 auto; padding: 48px 24px; text-align: center; }
    h1 { font-size: 28px; margin: 0 0 12px; }
    p { color: #c7c9d9; line-height: 1.4; }
  </style>
</head>
<body>
  <main class="screen">
    <h1>Email confirmed</h1>
    <p>This address is confirmed for your Sus Out custom-pack account. Open Sus Out and sign in.</p>
  </main>
</body>
</html>`;
}

export function gameOverHtml(): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <meta name="theme-color" content="#0f1224">
  <title>Sus Out — Game over</title>
  <link rel="icon" href="/art/app-icon.jpg">
  <style>
    body { margin: 0; min-height: 100vh; background: #0f1224; color: #fff; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
    .screen { max-width: 420px; margin: 0 auto; padding: 48px 24px; text-align: center; }
    h1 { font-size: 28px; margin: 0 0 12px; }
    p { color: #c7c9d9; line-height: 1.4; }
  </style>
</head>
<body>
  <main class="screen">
    <h1>This game is over</h1>
    <p>The host ended it. This page is closed.</p>
  </main>
</body>
</html>`;
}

export function staticAsset(pathname: string): Response | null {
  switch (pathname) {
    case "/privacy":
    case "/privacy/":
      return cachedTextResponse(privacyHtml, "text/html; charset=utf-8");
    case "/card.css":
      return cachedTextResponse(cardCss, "text/css; charset=utf-8");
    case "/card.js":
      return cachedTextResponse(cardJs, "application/javascript; charset=utf-8");
    case "/art/app-icon.jpg":
      return imageResponse(artAppIcon);
    case "/art/insider.jpg":
      return imageResponse(artInsider);
    case "/art/mismatch.jpg":
      return imageResponse(artMismatch);
    case "/art/ghost.jpg":
      return imageResponse(artGhost);
    default:
      return null;
  }
}

function cachedTextResponse(body: string, contentType: string): Response {
  return new Response(body, {
    headers: {
      "Content-Type": contentType,
      "Cache-Control": "public, max-age=3600",
    },
  });
}

function imageResponse(body: ArrayBuffer): Response {
  return new Response(body, {
    headers: {
      "Content-Type": "image/jpeg",
      "Cache-Control": "public, max-age=86400",
    },
  });
}
