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
