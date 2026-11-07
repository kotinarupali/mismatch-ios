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
  ghostPickAgainEnabled?: boolean;
}

interface SessionState extends SessionInit {
  revision: number;
  claimedIndices: Record<number, string>;
  openedPlayerIds: string[];
  /** First phone to tap a name. The word is returned only to this token. */
  deviceTokens: Record<string, string>;
  hostKey: string;
  votingEnabled: boolean;
  ghostPickAgainEnabled: boolean;
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
      return this.snapshot(request);
    }
    if (url.pathname === "/lock" && request.method === "POST") {
      return this.lockName(request);
    }
    if (url.pathname === "/claim" && request.method === "POST") {
      return this.claim(request);
    }
    if (url.pathname === "/release" && request.method === "POST") {
      return this.releasePlayer(request);
    }
    if (url.pathname === "/swap-ghost" && request.method === "POST") {
      return this.swapGhostRole(request);
    }
    if (url.pathname === "/vote" && request.method === "POST") {
      return this.submitVote(request);
    }
    if (url.pathname === "/voting" && request.method === "POST") {
      return this.controlVoting(request);
    }
    if (url.pathname === "/delete" && request.method === "POST") {
      return this.deleteSession(request);
    }

    return new Response("Not found", { status: 404 });
  }

  private async initSession(request: Request): Promise<Response> {
    const body = (await request.json()) as SessionInit;
    const hostKey = crypto.randomUUID();
    this.session = {
      ...body,
      votingEnabled: body.votingEnabled === true,
      ghostPickAgainEnabled: body.ghostPickAgainEnabled !== false,
      hostKey,
      revision: 0,
      claimedIndices: {},
      openedPlayerIds: [],
      deviceTokens: {},
      votingOpen: false,
      votingRound: 0,
      eliminatedPlayerIds: [],
      revoteExcludedPlayerIds: [],
      votes: {},
    };
    return json({ ok: true, revision: 0, hostKey });
  }

    private snapshot(request: Request): Response {
    if (!this.session) {
      return json({ error: "not_found" }, 404);
    }

    const url = new URL(request.url);
    const hostKey = url.searchParams.get("hostKey");

    const guestPlayers = this.session.players
      .filter((player) => !player.isHost)
      .map((player) => ({
        id: player.id,
        displayName: player.displayName,
        hasOpenedCard: this.session!.openedPlayerIds.includes(player.id),
        nameHeld: Boolean(this.session!.deviceTokens[player.id]),
      }));

    const deviceToken = url.searchParams.get("deviceToken");
    const holdsPlayerId = deviceToken ? playerIdForDevice(this.session, deviceToken) : undefined;
    const heldPlayer = holdsPlayerId
      ? this.session.players.find((player) => player.id === holdsPlayerId)
      : undefined;
    const myCard =
      heldPlayer && this.session.openedPlayerIds.includes(heldPlayer.id)
        ? cardPayload(this.session, heldPlayer)
        : undefined;

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
      displayName: player.displayName,
      isHost: player.isHost,
      isEliminated: this.session!.eliminatedPlayerIds.includes(player.id),
    }));

    const voteTallies: Record<string, number> = {};
    for (const targetId of Object.values(this.session.votes)) {
      voteTallies[targetId] = (voteTallies[targetId] ?? 0) + 1;
    }

    const voteCasts = Object.entries(this.session.votes).map(([voterId, targetId]) => {
      const voter = this.session!.players.find((p) => p.id === voterId);
      const target = this.session!.players.find((p) => p.id === targetId);
      return {
        voterId,
        voterName: voter?.displayName ?? "Player",
        targetId,
        targetName: target?.displayName ?? "Player",
      };
    });

    return json({
      players: guestPlayers,
      claimedCards,
      faceDownCardCount: this.session.faceDownCardCount,
      showRoleOnCard: this.session.showRoleOnCard,
      revision: this.session.revision,
      holdsPlayerId,
      myCard,
      assignments:
        hostKey && hostKey === this.session.hostKey
          ? this.session.players.map((player) => ({
              id: player.id,
              role: player.role,
              word: player.word ?? null,
              categoryHint: player.categoryHint ?? null,
            }))
          : undefined,
      votingEnabled: this.session.votingEnabled,
      votingOpen: this.session.votingOpen,
      votingRound: this.session.votingRound,
      revoteExcludedPlayerIds: this.session.revoteExcludedPlayerIds,
      voteTargets,
      voteTallies,
      voteCasts,
    });
  }

  private async claim(request: Request): Promise<Response> {
    if (!this.session) {
      return json({ error: "not_found" }, 404);
    }

    const body = (await request.json()) as { playerId?: string; cardIndex?: number; deviceToken?: string };
    const playerId = body.playerId;
    const cardIndex = body.cardIndex;
    const deviceToken = body.deviceToken;

    if (!playerId || cardIndex === undefined || !isDeviceToken(deviceToken)) {
      return json({ error: "invalid_request" }, 400);
    }

    const player = this.session.players.find((p) => p.id === playerId);
    if (!player) {
      return json({ error: "unknown_player" }, 404);
    }
    if (player.isHost) {
      return json({ error: "host_must_use_app" }, 403);
    }
    if (this.session.deviceTokens[playerId] !== deviceToken) {
      return json({ error: "name_taken", revision: this.session.revision }, 409);
    }
    if (this.session.openedPlayerIds.includes(playerId)) {
      return json(cardPayload(this.session, player));
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

    return json(cardPayload(this.session, player));
  }

  private async lockName(request: Request): Promise<Response> {
    if (!this.session) {
      return json({ error: "not_found" }, 404);
    }

    const body = (await request.json()) as { playerId?: string; deviceToken?: string };
    const playerId = body.playerId;
    const deviceToken = body.deviceToken;
    if (!playerId || !isDeviceToken(deviceToken)) {
      return json({ error: "invalid_request" }, 400);
    }

    const player = this.session.players.find((p) => p.id === playerId);
    if (!player) {
      return json({ error: "unknown_player" }, 404);
    }
    if (player.isHost) {
      return json({ error: "host_must_use_app" }, 403);
    }

    const current = this.session.deviceTokens[playerId];
    if (current && current !== deviceToken) {
      return json({ error: "name_taken", revision: this.session.revision }, 409);
    }
    if (!current) {
      this.session.deviceTokens[playerId] = deviceToken;
      this.session.revision += 1;
    }
    return json({ ok: true, revision: this.session.revision });
  }

  private async releasePlayer(request: Request): Promise<Response> {
    if (!this.session) {
      return json({ error: "not_found" }, 404);
    }

    const body = (await request.json()) as { hostKey?: string; playerId?: string };
    if (!body.hostKey || body.hostKey !== this.session.hostKey) {
      return json({ error: "forbidden" }, 403);
    }
    const playerId = body.playerId;
    if (!playerId || !this.session.players.some((player) => player.id === playerId && !player.isHost)) {
      return json({ error: "unknown_player" }, 404);
    }

    delete this.session.deviceTokens[playerId];
    this.session.openedPlayerIds = this.session.openedPlayerIds.filter((id) => id !== playerId);
    for (const [index, ownerId] of Object.entries(this.session.claimedIndices)) {
      if (ownerId === playerId) {
        delete this.session.claimedIndices[Number(index)];
      }
    }
    delete this.session.votes[playerId];
    this.session.revision += 1;
    return json({ ok: true, revision: this.session.revision });
  }

  private async swapGhostRole(request: Request): Promise<Response> {
    if (!this.session) {
      return json({ error: "not_found" }, 404);
    }

    const body = (await request.json()) as { playerId?: string; deviceToken?: string; hostKey?: string };
    const playerId = body.playerId;
    const deviceToken = body.deviceToken;
    if (!playerId) {
      return json({ error: "invalid_request" }, 400);
    }

    const phoneOwns = isDeviceToken(deviceToken) && this.session.deviceTokens[playerId] === deviceToken;
    const hostOwns = body.hostKey === this.session.hostKey
      && this.session.players.some((player) => player.id === playerId && player.isHost);
    if (!phoneOwns && !hostOwns) {
      return json({ error: "name_taken", revision: this.session.revision }, 409);
    }

    const ghostIndex = this.session.players.findIndex((p) => p.id === playerId);
    if (ghostIndex < 0) {
      return json({ error: "unknown_player" }, 404);
    }
    if (this.session.players[ghostIndex].role !== "ghost") {
      const current = this.session.players[ghostIndex];
      const payload: Record<string, unknown> = {
        showRoleOnCard: this.session.showRoleOnCard,
        faceDownCardCount: this.session.faceDownCardCount,
        revision: this.session.revision,
      };
      const visibleRole = roleShownOnCard(current.role, this.session.showRoleOnCard);
      if (visibleRole) payload.role = visibleRole;
      if (current.word) payload.word = current.word;
      if (current.categoryHint) payload.categoryHint = current.categoryHint;
      return json(payload);
    }
    if (!this.session.ghostPickAgainEnabled) {
      return json({ error: "swap_unavailable" }, 409);
    }

    const partnerCandidates = this.session.players.filter(
      (player) =>
        player.id !== playerId &&
        !this.session!.openedPlayerIds.includes(player.id) &&
        player.role !== "ghost"
    );
    if (partnerCandidates.length < 1) {
      return json({ error: "swap_unavailable" }, 409);
    }

    const partner =
      partnerCandidates[Math.floor(Math.random() * partnerCandidates.length)];
    const partnerIndex = this.session.players.findIndex((p) => p.id === partner.id);
    if (partnerIndex < 0) {
      return json({ error: "swap_unavailable" }, 409);
    }

    const ghostPlayer = this.session.players[ghostIndex];
    const partnerPlayer = this.session.players[partnerIndex];
    this.session.players[ghostIndex] = {
      ...ghostPlayer,
      role: partnerPlayer.role,
      word: partnerPlayer.word ?? null,
      categoryHint: partnerPlayer.categoryHint ?? null,
    };
    this.session.players[partnerIndex] = {
      ...partnerPlayer,
      role: "ghost",
      word: null,
      categoryHint: ghostPlayer.categoryHint ?? null,
    };

    this.session.openedPlayerIds = this.session.openedPlayerIds.filter((id) => id !== playerId);
    for (const [index, ownerId] of Object.entries(this.session.claimedIndices)) {
      if (ownerId === playerId) {
        delete this.session.claimedIndices[Number(index)];
      }
    }
    this.session.revision += 1;

    const updated = this.session.players[ghostIndex];
    const payload: Record<string, unknown> = {
      showRoleOnCard: this.session.showRoleOnCard,
      faceDownCardCount: this.session.faceDownCardCount,
      revision: this.session.revision,
    };
    const visibleRole = roleShownOnCard(updated.role, this.session.showRoleOnCard);
    if (visibleRole) payload.role = visibleRole;
    if (updated.word) payload.word = updated.word;
    if (updated.categoryHint) payload.categoryHint = updated.categoryHint;

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

    const body = (await request.json()) as { voterId?: string; targetPlayerId?: string; deviceToken?: string };
    const voterId = body.voterId;
    const targetPlayerId = body.targetPlayerId;
    const deviceToken = body.deviceToken;

    if (!voterId || !targetPlayerId || !isDeviceToken(deviceToken)) {
      return json({ error: "invalid_request" }, 400);
    }
    if (this.session.deviceTokens[voterId] !== deviceToken) {
      return json({ error: "name_taken", revision: this.session.revision }, 409);
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

  private async deleteSession(request: Request): Promise<Response> {
    if (!this.session) {
      return json({ error: "not_found" }, 404);
    }

    let hostKey: string | undefined;
    try {
      const body = (await request.json()) as { hostKey?: string };
      hostKey = body.hostKey;
    } catch {
      hostKey = undefined;
    }

    if (!hostKey || hostKey !== this.session.hostKey) {
      return json({ error: "forbidden" }, 403);
    }

    this.session = null;
    return json({ ok: true });
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

function isDeviceToken(value: string | undefined): value is string {
  return !!value && value.length >= 16 && value.length <= 80;
}

function playerIdForDevice(session: SessionState, deviceToken: string): string | undefined {
  return Object.entries(session.deviceTokens).find(([, token]) => token === deviceToken)?.[0];
}

function cardPayload(session: SessionState, player: PlayerAssignment): Record<string, unknown> {
  const payload: Record<string, unknown> = {
    showRoleOnCard: session.showRoleOnCard,
    faceDownCardCount: session.faceDownCardCount,
    revision: session.revision,
  };
  const visibleRole = roleShownOnCard(player.role, session.showRoleOnCard);
  if (visibleRole) payload.role = visibleRole;
  if (player.word) payload.word = player.word;
  if (player.categoryHint) payload.categoryHint = player.categoryHint;
  if (player.role === "ghost" && session.insiderWord) {
    payload.insiderWord = session.insiderWord;
  }
  if (player.role === "ghost") {
    const unpickedOthers = session.players.filter(
      (candidate) =>
        candidate.id !== player.id &&
        !session.openedPlayerIds.includes(candidate.id) &&
        candidate.role !== "ghost"
    );
    payload.canSwapGhostRole = session.ghostPickAgainEnabled && unpickedOthers.length >= 1;
  }
  return payload;
}

function roleShownOnCard(role: string, showRoleOnCard: boolean): string | undefined {
  if (role === "ghost" || showRoleOnCard) return role;
  return undefined;
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
