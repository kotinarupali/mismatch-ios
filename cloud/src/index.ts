import { CardSession } from "./session";
import { accountConfirmedHtml, gameOverHtml, joinPageHtml, resetPasswordHtml, staticAsset } from "./webAssets";

export { CardSession };

interface Env {
  CARD_SESSION: DurableObjectNamespace;
  SUPABASE_URL?: string;
  SUPABASE_ANON_KEY?: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return cors(new Response(null, { status: 204 }));
    }

    if (url.pathname === "/api/account/password" && request.method === "POST") {
      return resetPassword(request, env);
    }

    if (url.pathname === "/api/sessions" && request.method === "POST") {
      return createSession(request, env, url);
    }

    const lockMatch = url.pathname.match(/^\/api\/session\/([^/]+)\/lock\/?$/);
    if (lockMatch && request.method === "POST") {
      const token = lockMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));
      const response = await stub.fetch(
        new Request("https://do/lock", { method: "POST", body: request.body })
      );
      return cors(response);
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

    const swapMatch = url.pathname.match(/^\/api\/session\/([^/]+)\/swap-ghost\/?$/);
    if (swapMatch && request.method === "POST") {
      const token = swapMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));
      const response = await stub.fetch(
        new Request("https://do/swap-ghost", { method: "POST", body: request.body })
      );
      return cors(response);
    }

    const sessionMatch = url.pathname.match(/^\/api\/session\/([^/]+)\/?$/);
    if (sessionMatch) {
      const token = sessionMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));

      if (request.method === "GET") {
        const response = await stub.fetch(new Request(`https://do/snapshot${url.search}`));
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

    const hostCardMatch = url.pathname.match(/^\/api\/sessions\/([^/]+)\/host-card\/?$/);
    if (hostCardMatch && request.method === "POST") {
      const token = hostCardMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));
      const response = await stub.fetch(
        new Request("https://do/host-card", { method: "POST", body: request.body })
      );
      return cors(response);
    }

    const releaseMatch = url.pathname.match(/^\/api\/sessions\/([^/]+)\/release\/?$/);
    if (releaseMatch && request.method === "POST") {
      const token = releaseMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));
      const response = await stub.fetch(
        new Request("https://do/release", { method: "POST", body: request.body })
      );
      return cors(response);
    }

    const deleteMatch = url.pathname.match(/^\/api\/sessions\/([^/]+)\/delete$/);
    if (deleteMatch && request.method === "POST") {
      const token = deleteMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));
      const response = await stub.fetch(
        new Request("https://do/delete", {
          method: "POST",
          body: request.body,
          headers: request.headers,
        })
      );
      return cors(response);
    }

    const joinMatch = url.pathname.match(/^\/join\/([^/]+)\/?$/);
    if (joinMatch && request.method === "GET") {
      const token = joinMatch[1];
      const stub = env.CARD_SESSION.get(env.CARD_SESSION.idFromName(token));
      const snapshot = await stub.fetch(new Request("https://do/snapshot"));
      const payload = snapshot.ok
        ? ((await snapshot.json()) as { ended?: boolean })
        : { ended: true };
      if (!snapshot.ok || payload.ended) {
        return new Response(gameOverHtml(), {
          status: 410,
          headers: {
            "Content-Type": "text/html; charset=utf-8",
            "Cache-Control": "no-store",
          },
        });
      }
      return new Response(joinPageHtml(token), {
        headers: {
          "Content-Type": "text/html; charset=utf-8",
          "Cache-Control": "no-store",
        },
      });
    }

    if (
      (url.pathname === "/reset-password" || url.pathname === "/reset-password/") &&
      request.method === "GET"
    ) {
      return new Response(resetPasswordHtml(), {
        headers: {
          "Content-Type": "text/html; charset=utf-8",
          "Cache-Control": "no-store",
        },
      });
    }

    if (
      (url.pathname === "/account-confirmed" || url.pathname === "/account-confirmed/") &&
      request.method === "GET"
    ) {
      return new Response(accountConfirmedHtml(), {
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

async function resetPassword(request: Request, env: Env): Promise<Response> {
  const supabaseURL = env.SUPABASE_URL ?? "";
  const anonKey = env.SUPABASE_ANON_KEY ?? "";
  if (!supabaseURL || !anonKey) {
    return accountJson({ message: "Password reset is unavailable." }, 500);
  }
  const body = (await request.json().catch(() => ({}))) as {
    accessToken?: string;
    tokenHash?: string;
    password?: string;
  };
  const password = body.password ?? "";
  const length = new TextEncoder().encode(password).length;
  if (length < 6) return accountJson({ message: "Use at least 6 characters." }, 400);
  if (length > 72) return accountJson({ message: "Use at most 72 characters." }, 400);

  let accessToken = body.accessToken ?? "";
  if (!accessToken && body.tokenHash) {
    const verified = await fetch(`${supabaseURL}/auth/v1/verify`, {
      method: "POST",
      headers: {
        apikey: anonKey,
        Authorization: `Bearer ${anonKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ type: "recovery", token_hash: body.tokenHash }),
    });
    const payload = (await verified.json().catch(() => ({}))) as { access_token?: string };
    if (!verified.ok || !payload.access_token) {
      return accountJson({ message: "This reset link is invalid or has expired." }, 400);
    }
    accessToken = payload.access_token;
  }
  if (!accessToken) {
    return accountJson({ message: "This reset link is invalid or has expired." }, 400);
  }

  const updated = await fetch(`${supabaseURL}/auth/v1/user`, {
    method: "PUT",
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ password }),
  });
  if (!updated.ok) {
    return accountJson({ message: "This reset link is invalid or has expired." }, 400);
  }
  return accountJson({ updated: true }, 200);
}

function accountJson(payload: unknown, status: number): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
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
