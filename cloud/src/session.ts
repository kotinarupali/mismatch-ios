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
  votingEnabled?: boolean;
}

interface SessionState extends SessionInit {
  revision: number;
  claimedIndices: Record<number, string>;
  openedPlayerIds: string[];
  hostKey: string;
  votingEnabled: boolean;
  votingOpen: boolean;
  votingRound: number;
  eliminatedPlayerIds: string[];
  revoteExcludedPlayerIds: string[];
  votes: Record<string, string>;
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
    if (url.pathname === "/vote" && request.method === "POST") {
      return this.submitVote(request);
    }
    if (url.pathname === "/voting" && request.method === "POST") {
      return this.controlVoting(request);
    }
    if (url.pathname === "/delete" && request.method === "POST") {
      this.session = null;
      return json({ ok: true });
    }

    return new Response("Not found", { status: 404 });
  }

  private async initSession(request: Request): Promise<Response> {
    const body = (await request.json()) as SessionInit;
    const hostKey = crypto.randomUUID();
    this.session = {
      ...body,
      votingEnabled: body.votingEnabled === true,
      hostKey,
      revision: 0,
      claimedIndices: {},
      openedPlayerIds: [],
      votingOpen: false,
      votingRound: 0,
      eliminatedPlayerIds: [],
      revoteExcludedPlayerIds: [],
      votes: {},
    };
    return json({ ok: true, revision: 0, hostKey });
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

    const voteTargets = this.session.players.map((player) => ({
      id: player.id,
      displayName: player.isHost ? "Host" : player.displayName,
      isHost: player.isHost,
      isEliminated: this.session!.eliminatedPlayerIds.includes(player.id),
    }));

    const voteTallies: Record<string, number> = {};
    for (const targetId of Object.values(this.session.votes)) {
      voteTallies[targetId] = (voteTallies[targetId] ?? 0) + 1;
    }

    return json({
      players: guestPlayers,
      claimedCards,
      faceDownCardCount: this.session.faceDownCardCount,
      showRoleOnCard: this.session.showRoleOnCard,
      revision: this.session.revision,
      votingEnabled: this.session.votingEnabled,
      votingOpen: this.session.votingOpen,
      votingRound: this.session.votingRound,
      revoteExcludedPlayerIds: this.session.revoteExcludedPlayerIds,
      voteTargets,
      voteTallies,
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

  private async submitVote(request: Request): Promise<Response> {
    if (!this.session) {
      return json({ error: "not_found" }, 404);
    }
    if (!this.session.votingEnabled) {
      return json({ error: "voting_disabled" }, 403);
    }
    if (!this.session.votingOpen) {
      return json({ error: "voting_closed" }, 409);
    }

    const body = (await request.json()) as { voterId?: string; targetPlayerId?: string };
    const voterId = body.voterId;
    const targetPlayerId = body.targetPlayerId;

    if (!voterId || !targetPlayerId) {
      return json({ error: "invalid_request" }, 400);
    }

    const voter = this.session.players.find((p) => p.id === voterId);
    if (!voter || voter.isHost) {
      return json({ error: "unknown_voter" }, 404);
    }
    if (!this.session.openedPlayerIds.includes(voterId)) {
      return json({ error: "card_required" }, 403);
    }
    if (this.session.eliminatedPlayerIds.includes(voterId)) {
      return json({ error: "voter_eliminated" }, 403);
    }
    if (voterId === targetPlayerId) {
      return json({ error: "cannot_vote_self" }, 400);
    }

    const target = this.session.players.find((p) => p.id === targetPlayerId);
    if (!target) {
      return json({ error: "unknown_target" }, 404);
    }
    if (this.session.eliminatedPlayerIds.includes(targetPlayerId)) {
      return json({ error: "target_eliminated" }, 400);
    }
    if (this.session.revoteExcludedPlayerIds.includes(targetPlayerId)) {
      return json({ error: "target_excluded_from_revote" }, 400);
    }

    this.session.votes[voterId] = targetPlayerId;
    this.session.revision += 1;

    return json({ ok: true, revision: this.session.revision });
  }

  private async controlVoting(request: Request): Promise<Response> {
    if (!this.session) {
      return json({ error: "not_found" }, 404);
    }

    const body = (await request.json()) as {
      hostKey?: string;
      action?: string;
      eliminatedPlayerIds?: string[];
      revoteExcludedPlayerIds?: string[];
    };

    if (!body.hostKey || body.hostKey !== this.session.hostKey) {
      return json({ error: "forbidden" }, 403);
    }

    if (Array.isArray(body.eliminatedPlayerIds)) {
      this.session.eliminatedPlayerIds = body.eliminatedPlayerIds.filter((id) =>
        this.session!.players.some((player) => player.id === id)
      );
    }

    if (body.action === "open") {
      if (!this.session.votingEnabled) {
        return json({ error: "voting_disabled" }, 403);
      }
      this.session.votes = {};
      this.session.revoteExcludedPlayerIds = [];
      this.session.votingRound += 1;
      this.session.votingOpen = true;
      this.session.revision += 1;
      return json({ ok: true, votingRound: this.session.votingRound, revision: this.session.revision });
    }

    if (body.action === "revote") {
      if (!this.session.votingEnabled) {
        return json({ error: "voting_disabled" }, 403);
      }
      const excluded = Array.isArray(body.revoteExcludedPlayerIds)
        ? body.revoteExcludedPlayerIds.filter((id) =>
            this.session!.players.some((player) => player.id === id)
          )
        : [];
      this.session.votes = {};
      this.session.revoteExcludedPlayerIds = excluded;
      this.session.votingRound += 1;
      this.session.votingOpen = true;
      this.session.revision += 1;
      return json({
        ok: true,
        votingRound: this.session.votingRound,
        revision: this.session.revision,
        revoteExcludedPlayerIds: this.session.revoteExcludedPlayerIds,
      });
    }

    if (body.action === "close") {
      this.session.votingOpen = false;
      this.session.revision += 1;
      return json({ ok: true, revision: this.session.revision });
    }

    if (body.action === "sync") {
      this.session.revision += 1;
      return json({ ok: true, revision: this.session.revision });
    }

    return json({ error: "invalid_action" }, 400);
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
