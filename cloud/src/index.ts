import { CardSession } from "./session";
import { joinPageHtml, staticAsset } from "./webAssets";

export { CardSession };

interface Env {
  CARD_SESSION: DurableObjectNamespace;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return cors(new Response(null, { status: 204 }));
    }

    if (url.pathname === "/api/sessions" && request.method === "POST") {
      return createSession(request, env, url);
    }

    const voteMatch = url.pathname.match(/^\/api\/session\/([^/]+)\/vote\/?$/);
    if (voteMatch && request.method === "POST") {
      const token = voteMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));
      const response = await stub.fetch(
        new Request("https://do/vote", { method: "POST", body: request.body })
      );
      return cors(response);
    }

    const sessionMatch = url.pathname.match(/^\/api\/session\/([^/]+)\/?$/);
    if (sessionMatch) {
      const token = sessionMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));

      if (request.method === "GET") {
        const response = await stub.fetch("https://do/snapshot");
        return cors(response);
      }

      if (request.method === "POST") {
        const response = await stub.fetch(
          new Request("https://do/claim", { method: "POST", body: request.body })
        );
        return cors(response);
      }
    }

    const votingMatch = url.pathname.match(/^\/api\/sessions\/([^/]+)\/voting\/?$/);
    if (votingMatch && request.method === "POST") {
      const token = votingMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));
      const response = await stub.fetch(
        new Request("https://do/voting", { method: "POST", body: request.body })
      );
      return cors(response);
    }

    const deleteMatch = url.pathname.match(/^\/api\/sessions\/([^/]+)\/delete$/);
    if (deleteMatch && request.method === "POST") {
      const token = deleteMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));
      const response = await stub.fetch("https://do/delete", { method: "POST" });
      return cors(response);
    }

    const joinMatch = url.pathname.match(/^\/join\/([^/]+)\/?$/);
    if (joinMatch && request.method === "GET") {
      const token = joinMatch[1];
      return new Response(joinPageHtml(token), {
        headers: {
          "Content-Type": "text/html; charset=utf-8",
          "Cache-Control": "no-store",
        },
      });
    }

    if (request.method === "GET") {
      const asset = staticAsset(url.pathname);
      if (asset) return asset;
    }

    return new Response("Not found", { status: 404 });
  },
};

async function createSession(request: Request, env: Env, url: URL): Promise<Response> {
  const token = crypto.randomUUID().replace(/-/g, "");
  const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));
  const initResponse = await stub.fetch(
    new Request("https://do/init", { method: "POST", body: request.body })
  );

  if (!initResponse.ok) {
    return cors(initResponse);
  }

  const initData = (await initResponse.json()) as { hostKey?: string };
  const joinURL = `${url.origin}/join/${token}`;
  return cors(
    new Response(JSON.stringify({ sessionToken: token, joinURL, hostKey: initData.hostKey }), {
      status: 200,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Cache-Control": "no-store",
        "Access-Control-Allow-Origin": "*",
      },
    })
  );
}

function cors(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  headers.set("Access-Control-Allow-Headers", "Content-Type");
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}
