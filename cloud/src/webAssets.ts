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
