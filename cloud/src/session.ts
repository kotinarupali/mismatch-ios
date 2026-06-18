export interface PlayerAssignment {
  id: string;
  displayName: string;
  isHost: boolean;
  role: string;
  word?: string | null;
  categoryHint?: string | null;
}

export interface SessionInit {
  players: PlayerAssignment[];
  faceDownCardCount: number;
  showRoleOnCard: boolean;
  insiderWord?: string | null;
}

interface SessionState extends SessionInit {
  revision: number;
  claimedIndices: Record<number, string>;
  openedPlayerIds: string[];
}

export class CardSession implements DurableObject {
  private session: SessionState | null = null;

  constructor(private state: DurableObjectState) {}

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/init" && request.method === "POST") {
      return this.initSession(request);
    }
    if (url.pathname === "/snapshot" && request.method === "GET") {
      return this.snapshot();
    }
    if (url.pathname === "/claim" && request.method === "POST") {
      return this.claim(request);
    }
    if (url.pathname === "/delete" && request.method === "POST") {
      this.session = null;
      return json({ ok: true });
    }

    return new Response("Not found", { status: 404 });
  }

  private async initSession(request: Request): Promise<Response> {
    const body = (await request.json()) as SessionInit;
    this.session = {
      ...body,
      revision: 0,
      claimedIndices: {},
      openedPlayerIds: [],
    };
    return json({ ok: true, revision: 0 });
  }

  private snapshot(): Response {
    if (!this.session) {
      return json({ error: "not_found" }, 404);
    }

    const guestPlayers = this.session.players
      .filter((player) => !player.isHost)
      .map((player) => ({
        id: player.id,
        displayName: player.displayName,
        hasOpenedCard: this.session!.openedPlayerIds.includes(player.id),
      }));

    const claimedCards = Object.entries(this.session.claimedIndices).map(
      ([index, playerId]) => {
        const player = this.session!.players.find((p) => p.id === playerId);
        return {
          cardIndex: Number(index),
          playerId,
          playerName: player?.displayName ?? "Player",
        };
      }
    );

    return json({
      players: guestPlayers,
      claimedCards,
      faceDownCardCount: this.session.faceDownCardCount,
      showRoleOnCard: this.session.showRoleOnCard,
      revision: this.session.revision,
    });
  }

  private async claim(request: Request): Promise<Response> {
    if (!this.session) {
      return json({ error: "not_found" }, 404);
    }

    const body = (await request.json()) as { playerId?: string; cardIndex?: number };
    const playerId = body.playerId;
    const cardIndex = body.cardIndex;

    if (!playerId || cardIndex === undefined) {
      return json({ error: "invalid_request" }, 400);
    }

    const player = this.session.players.find((p) => p.id === playerId);
    if (!player) {
      return json({ error: "unknown_player" }, 404);
    }
    if (player.isHost) {
      return json({ error: "host_must_use_app" }, 403);
    }
    if (this.session.openedPlayerIds.includes(playerId)) {
      return json({ error: "already_claimed", revision: this.session.revision }, 409);
    }
    if (cardIndex < 0 || cardIndex >= this.session.faceDownCardCount) {
      return json({ error: "card_taken", revision: this.session.revision }, 409);
    }
    if (this.session.claimedIndices[cardIndex]) {
      return json({ error: "card_taken", revision: this.session.revision }, 409);
    }

    this.session.claimedIndices[cardIndex] = playerId;
    this.session.openedPlayerIds.push(playerId);
    this.session.revision += 1;

    const payload: Record<string, unknown> = {
      role: player.role,
      showRoleOnCard: this.session.showRoleOnCard,
      faceDownCardCount: this.session.faceDownCardCount,
      revision: this.session.revision,
    };
    if (player.word) payload.word = player.word;
    if (player.categoryHint) payload.categoryHint = player.categoryHint;
    if (player.role === "ghost" && this.session.insiderWord) {
      payload.insiderWord = this.session.insiderWord;
    }

    return json(payload);
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
