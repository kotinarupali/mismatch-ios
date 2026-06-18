import indexHtmlTemplate from "../public/index.html";
import cardCss from "../public/card.css";
import cardJs from "../public/card.js";

export function joinPageHtml(token: string): string {
  return indexHtmlTemplate.replace("{{TOKEN}}", token);
}

export function staticAsset(pathname: string): Response | null {
  switch (pathname) {
    case "/card.css":
      return cachedTextResponse(cardCss, "text/css; charset=utf-8");
    case "/card.js":
      return cachedTextResponse(cardJs, "application/javascript; charset=utf-8");
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
