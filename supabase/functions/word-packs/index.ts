// Custom pack storage. https://github.com/kotinarupali/mismatch-ios/issues/30
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const MAX_COUNT = 40;
const SAMPLE_COUNT = 3;
const MAX_TITLE = 40;
const MAX_PROMPT = 80;
const MAX_WORD = 48;
const MODELS = ["gemini-3.5-flash-lite", "gemini-3.1-flash-lite"];
const RESERVED_TITLES = [
  "general",
  "hollywood movies & series",
  "indian pop culture",
  "pop culture",
];

type Pair = {
  id?: string;
  insiderWord: string;
  mismatchWord: string;
  insiderCanonical: string;
  mismatchCanonical: string;
  category: string;
  playedAt?: string | null;
  isRemoved?: boolean;
};

type Host = {
  id: string;
  token_hash: string;
  user_id: string | null;
  is_premium: boolean;
};

const serviceKey = () => Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const supabaseUrl = () => Deno.env.get("SUPABASE_URL") ?? "";
const requirePremium = () => (Deno.env.get("REQUIRE_PREMIUM") ?? "false") === "true";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return cors(new Response(null, { status: 204 }));
  }

  try {
    const url = new URL(request.url);
    const path = url.pathname.replace(/^\/functions\/v1/, "").replace(/\/$/, "");
    const body = request.method === "GET" ? {} : await readJson(request);
    const hostToken = header(request, "x-host-token") || stringField(body, "hostToken");
    if (!hostToken) return json({ error: "missingHost" }, 400);

    const userId = await signedInUserId(request);
    const host = await resolveHost(hostToken, userId);
    if ("error" in host) return json(host, host.status);

    if (path.endsWith("/word-packs") && request.method === "GET") {
      return json({ packs: await listPacks(host.host) });
    }

    if (path.endsWith("/word-packs") && request.method === "POST") {
      return json(await generate(host.host, body));
    }

    if (path.endsWith("/word-packs/save") && request.method === "POST") {
      return json(await savePending(host.host, body));
    }

    if (path.endsWith("/word-packs/link") && request.method === "POST") {
      const linked = await linkAccount(host.host, userId);
      return json(linked, linked.status ?? 200);
    }

    if (path.endsWith("/word-packs/played") && request.method === "POST") {
      return json(await markPlayed(host.host, body));
    }

    const packMatch = path.match(/\/word-packs\/([^/]+)(?:\/(.*))?$/);
    if (!packMatch) return json({ error: "notFound" }, 404);
    const packId = packMatch[1];
    const rest = packMatch[2] ?? "";

    if (rest === "archive" && request.method === "POST") {
      return json(await archivePack(host.host, packId));
    }
    if (rest === "" && request.method === "PATCH") {
      return json(await renamePack(host.host, packId, stringField(body, "title")));
    }

    const pairMatch = rest.match(/^pairs\/([^/]+)(?:\/(.*))?$/);
    if (!pairMatch) return json({ error: "notFound" }, 404);
    const pairId = pairMatch[1];
    const pairAction = pairMatch[2] ?? "";

    if (pairAction === "" && request.method === "PATCH") {
      return json(await editPair(host.host, packId, pairId, body));
    }
    if (pairAction === "remove" && request.method === "POST") {
      return json(await removePair(host.host, packId, pairId));
    }
    if (pairAction === "replace" && request.method === "POST") {
      return json(await replacePair(host.host, packId, pairId));
    }

    return json({ error: "notFound" }, 404);
  } catch (error) {
    const message = error instanceof Error ? error.message : "failed";
    return json({ error: "failed", message }, 500);
  }
});

async function resolveHost(
  hostToken: string,
  userId: string | null,
): Promise<{ host: Host } | { error: string; message: string; status: number }> {
  const tokenHash = await sha256(hostToken);
  const existing = await rest<Host[]>(
    `hosts?token_hash=eq.${encodeURIComponent(tokenHash)}&select=id,token_hash,user_id,is_premium`,
  );
  let host = existing[0];
  if (!host) {
    const created = await rest<Host[]>("hosts", {
      method: "POST",
      body: JSON.stringify({ token_hash: tokenHash }),
    });
    host = created[0];
  }
  if (!host) return { error: "failed", message: "Could not save this phone.", status: 500 };

  if (host.user_id && host.user_id !== userId) {
    return { error: "signInRequired", message: "Sign in to use these packs.", status: 401 };
  }
  if (requirePremium() && (!userId || !host.is_premium)) {
    return { error: "premiumRequired", message: "Custom packs are part of premium.", status: 403 };
  }
  return { host };
}

// Exact pair count via Gemini. https://github.com/kotinarupali/mismatch-ios/issues/31
async function generate(host: Host, body: Record<string, unknown>) {
  const requestId = stringField(body, "requestId");
  const prompt = normalizePrompt(stringField(body, "prompt"));
  const count = numberField(body, "count");
  if (!requestId) return { error: "missingRequest", message: "Missing request." };
  if (!prompt) return { error: "missingPrompt", message: "Enter a theme." };
  if (!count || count < 1 || count > MAX_COUNT) {
    return { error: "badCount", message: `Ask for 1 to ${MAX_COUNT} pairs.` };
  }

  const existing = await packByRequest(host, requestId);
  if (existing) return { pack: existing };

  const pending = await pendingByRequest(host, requestId);
  if (pending) return pending;

  const blockedPairs = await exactPairKeys(host);
  const draft = await fillPairs(prompt, count + SAMPLE_COUNT, blockedPairs, []);

  const savedPairs = draft.pairs.slice(0, count);
  const samples = draft.pairs.slice(count, count + SAMPLE_COUNT).map(samplePair);
  if (savedPairs.length !== count) {
    return { error: "incomplete", message: "Couldn't finish that pack. Nothing was saved. Try again." };
  }

  const title = cleanTitle(draft.title, prompt);
  const titles = await activeTitles(host);
  if (titles.has(titleKey(title)) || RESERVED_TITLES.includes(titleKey(title))) {
    await rest("pending_generations?on_conflict=host_id,request_id", {
      method: "POST",
      body: JSON.stringify({
        host_id: host.id,
        request_id: requestId,
        payload: { prompt, title, pairs: savedPairs, titleTaken: true, requestId },
      }),
      headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
    });
    return { titleTaken: true, title, pairs: savedPairs, samples, requestId };
  }

  return { pack: await insertPack(host, prompt, title, requestId, savedPairs), samples };
}

async function savePending(host: Host, body: Record<string, unknown>) {
  const requestId = stringField(body, "requestId");
  const title = cleanTitle(stringField(body, "title"), "");
  if (!requestId || !title) return { error: "missingTitle", message: "Enter a title." };

  const existing = await packByRequest(host, requestId);
  if (existing) return { pack: existing };

  const titles = await activeTitles(host);
  if (titles.has(titleKey(title)) || RESERVED_TITLES.includes(titleKey(title))) {
    return { error: "titleTaken", message: "You already have a pack with that name." };
  }

  const pending = await rest<Array<{ payload: { prompt: string; pairs: Pair[] } }>>(
    `pending_generations?host_id=eq.${host.id}&request_id=eq.${encodeURIComponent(requestId)}&select=payload`,
  );
  const payload = pending[0]?.payload;
  if (!payload?.pairs?.length) {
    return { error: "missingDraft", message: "Generate the pack again." };
  }

  const pack = await insertPack(host, payload.prompt, title, requestId, payload.pairs);
  await rest(
    `pending_generations?host_id=eq.${host.id}&request_id=eq.${encodeURIComponent(requestId)}`,
    { method: "DELETE", headers: { Prefer: "return=minimal" } },
  );
  return { pack };
}

// Email account linking. https://github.com/kotinarupali/mismatch-ios/issues/36
async function linkAccount(host: Host, userId: string | null) {
  if (!userId) return { error: "signInRequired", message: "Sign in to keep these packs.", status: 401 as number | undefined };
  await rest(`hosts?id=eq.${host.id}`, {
    method: "PATCH",
    body: JSON.stringify({ user_id: userId }),
    headers: { Prefer: "return=minimal" },
  });
  const titles = await rest<Array<{ title: string; host_id: string }>>(
    `word_packs?is_archived=eq.false&select=title,host_id&host_id=in.(${(await hostIds(userId, host)).join(",")})`,
  );
  const seen = new Map<string, string>();
  const titleConflicts: string[] = [];
  for (const row of titles) {
    const key = titleKey(row.title);
    const previous = seen.get(key);
    if (previous && previous !== row.host_id) titleConflicts.push(row.title);
    seen.set(key, row.host_id);
  }
  return { linked: true, titleConflicts, status: undefined as number | undefined };
}

async function markPlayed(host: Host, body: Record<string, unknown>) {
  const pairIds = Array.isArray(body.pairIds) ? body.pairIds.filter((id) => typeof id === "string") : [];
  if (pairIds.length === 0) return { updated: 0 };
  const ids = pairIds.join(",");
  const hostIds = await scopedHostIds(host);
  await rest(
    `word_pairs?id=in.(${ids})&host_id=in.(${hostIds.join(",")})&is_removed=eq.false`,
    {
      method: "PATCH",
      body: JSON.stringify({ played_at: new Date().toISOString() }),
      headers: { Prefer: "return=minimal" },
    },
  );
  return { updated: pairIds.length };
}

// Rename, edit, replace, remove, and archive. https://github.com/kotinarupali/mismatch-ios/issues/34
async function archivePack(host: Host, packId: string) {
  const pack = await ownedPack(host, packId);
  if (!pack) return { error: "notFound", message: "That pack is not on this account." };
  await rest(`word_packs?id=eq.${packId}`, {
    method: "PATCH",
    body: JSON.stringify({ is_archived: true }),
    headers: { Prefer: "return=minimal" },
  });
  return { archived: true, id: packId };
}

async function renamePack(host: Host, packId: string, rawTitle: string) {
  const pack = await ownedPack(host, packId);
  if (!pack) return { error: "notFound", message: "That pack is not on this account." };
  const title = cleanTitle(rawTitle, "");
  if (!title) return { error: "missingTitle", message: "Enter a title.", title: pack.title };
  const titles = await activeTitles(host, packId);
  if (titles.has(titleKey(title)) || RESERVED_TITLES.includes(titleKey(title))) {
    return { error: "titleTaken", message: "You already have a pack with that name.", title: pack.title };
  }
  await rest(`word_packs?id=eq.${packId}`, {
    method: "PATCH",
    body: JSON.stringify({ title }),
    headers: { Prefer: "return=minimal" },
  });
  return { pack: await packDetail(host, packId) };
}

async function editPair(host: Host, packId: string, pairId: string, body: Record<string, unknown>) {
  const current = await ownedPair(host, packId, pairId);
  if (!current) return { error: "notFound", message: "That pair is not in this pack." };
  if (current.played_at) return { error: "played", message: "A dealt pair stays as it was played." };

  const candidate: Pair = {
    insiderWord: stringField(body, "insiderWord"),
    mismatchWord: stringField(body, "mismatchWord"),
    insiderCanonical: stringField(body, "insiderCanonical") || stringField(body, "insiderWord"),
    mismatchCanonical: stringField(body, "mismatchCanonical") || stringField(body, "mismatchWord"),
    category: stringField(body, "category"),
  };
  const others = (await pairsForPack(packId)).filter((pair) => pair.id !== pairId && !isRemovedFlag(pair.is_removed));
  if (!acceptable(candidate, others, await exactPairKeys(host, pairId))) {
    return { error: "rejected", message: "Those words are too close to another pair in this pack." };
  }
  await rest(`word_pairs?id=eq.${pairId}`, {
    method: "PATCH",
    body: JSON.stringify({
      insider_word: candidate.insiderWord.trim(),
      mismatch_word: candidate.mismatchWord.trim(),
      insider_canonical: canonicalOf(candidate.insiderCanonical, candidate.insiderWord),
      mismatch_canonical: canonicalOf(candidate.mismatchCanonical, candidate.mismatchWord),
      category: candidate.category.trim(),
    }),
    headers: { Prefer: "return=minimal" },
  });
  return { pack: await packDetail(host, packId) };
}

async function removePair(host: Host, packId: string, pairId: string) {
  const current = await ownedPair(host, packId, pairId);
  if (!current) return { error: "notFound", message: "That pair is not in this pack." };
  if (current.played_at) return { error: "played", message: "A dealt pair stays as it was played." };
  await rest(`word_pairs?id=eq.${pairId}`, {
    method: "PATCH",
    body: JSON.stringify({ is_removed: true }),
    headers: { Prefer: "return=minimal" },
  });
  return { pack: await packDetail(host, packId) };
}

async function replacePair(host: Host, packId: string, pairId: string) {
  const pack = await ownedPack(host, packId);
  const current = await ownedPair(host, packId, pairId);
  if (!pack || !current) return { error: "notFound", message: "That pair is not in this pack." };
  if (current.played_at) return { error: "played", message: "A dealt pair stays as it was played." };

  const others = (await pairsForPack(packId)).filter((pair) => pair.id !== pairId && !isRemovedFlag(pair.is_removed));
  const draft = await fillPairs(pack.prompt, 1, await exactPairKeys(host, pairId), others.map(toPair));
  const replacement = draft.pairs[0];
  if (!replacement) return { error: "incomplete", message: "Couldn't replace that pair. It was left as it was." };

  await rest(`word_pairs?id=eq.${pairId}`, {
    method: "PATCH",
    body: JSON.stringify({
      insider_word: replacement.insiderWord,
      mismatch_word: replacement.mismatchWord,
      insider_canonical: replacement.insiderCanonical,
      mismatch_canonical: replacement.mismatchCanonical,
      category: replacement.category,
    }),
    headers: { Prefer: "return=minimal" },
  });
  return { pack: await packDetail(host, packId) };
}

async function fillPairs(
  prompt: string,
  count: number,
  blockedPairs: Set<string>,
  existing: Pair[],
): Promise<{ title: string; pairs: Pair[] }> {
  const kept: Pair[] = [...existing];
  let title = "";
  const dropped: string[] = [];

  for (let attempt = 0; attempt < 2 && kept.length < count; attempt++) {
    const needed = count - kept.length;
    const raw = await askModel(prompt, needed, blockedPairs, kept, dropped);
    if (!title && raw.title) title = raw.title;
    for (const pair of raw.pairs) {
      if (kept.length >= count) break;
      const cleaned = sanitize(pair);
      if (!cleaned) {
        dropped.push(pair.insiderWord || pair.mismatchWord || "a word");
        continue;
      }
      if (!acceptable(cleaned, kept, blockedPairs)) {
        dropped.push(cleaned.insiderWord);
        continue;
      }
      kept.push(cleaned);
      blockedPairs.add(pairKey(cleaned));
    }
  }

  return { title, pairs: kept.slice(0, count) };
}

async function askModel(
  prompt: string,
  count: number,
  blockedPairs: Set<string>,
  kept: Pair[],
  dropped: string[],
): Promise<{ title: string; pairs: Pair[] }> {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) throw new Error("GEMINI_API_KEY is not set");

  const avoid = [...blockedPairs].slice(0, 12).join("\n");
  const already = kept.map((pair) => pair.insiderWord).concat(kept.map((pair) => pair.mismatchWord)).join(", ");
  const text = [
    `The theme is: ${prompt}`,
    "Every pair must be that theme and nothing else.",
    "If the theme asks for words, return everyday words. Do not return movie titles, actor names, songs, or shows unless the theme asks for those.",
    `Return a short title and exactly ${count} pairs.`,
    "Each pair is two different things from one narrow group that a party could mix up.",
    "Use a movie example only when the theme is movies: Baahubali with Magadheera, not Baahubali with Bommarillu.",
    "For everyday words, pair two words from the same small group, such as puli and simham. A film title is not a word.",
    "Use the full phrase people say. More than one word is allowed. Do not shorten a name to its first word.",
    "The two must not be spellings of each other. Macaron and Macaroon is not allowed.",
    "Family-friendly. No repeats.",
    avoid ? `Skip these pairs:\n${avoid}` : "",
    already ? `Skip these words: ${already}` : "",
    dropped.length ? `Rejected: ${dropped.slice(-8).join(", ")}` : "",
  ].filter(Boolean).join("\n");

  let sawBusy = false;
  let omitThinking = false;
  for (const model of MODELS) {
    for (let attempt = 0; attempt < 2; attempt++) {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": key,
          },
          body: JSON.stringify({
            contents: [{ role: "user", parts: [{ text }] }],
            generationConfig: generationConfig(count, omitThinking),
          }),
        },
      );
      if (response.ok) {
        let payload: ModelPayload;
        try {
          payload = await response.json();
        } catch {
          continue;
        }
        const parsed = parseModelPayload(payload);
        if (parsed.pairs.length > 0) return parsed;
        continue;
      }
      if (response.status === 400 && !omitThinking) {
        omitThinking = true;
        attempt -= 1;
        continue;
      }
      if (response.status === 404) break;
      if (response.status !== 429 && response.status !== 503 && response.status < 500) {
        throw new Error(`Gemini ${response.status}`);
      }
      sawBusy = true;
      if (attempt < 1) await sleep(400 + Math.floor(Math.random() * 200));
    }
  }
  if (sawBusy) throw new Error("The word generator is busy. Try again in a moment.");
  throw new Error("Gemini failed");
}

function generationConfig(count: number, omitThinking: boolean): Record<string, unknown> {
  const config: Record<string, unknown> = {
    maxOutputTokens: Math.min(8192, 512 + count * 96),
    responseMimeType: "application/json",
    responseSchema: {
      type: "object",
      properties: {
        title: { type: "string" },
        pairs: {
          type: "array",
          items: {
            type: "object",
            properties: {
              insiderWord: { type: "string", description: "One entry that matches the user's theme. Everyday word when the theme asks for words." },
              mismatchWord: { type: "string", description: "A different entry from the same narrow group, also matching the theme" },
              insiderCanonical: { type: "string", description: "insiderWord in lowercase" },
              mismatchCanonical: { type: "string", description: "mismatchWord in lowercase" },
              category: { type: "string", description: "The narrow group these two share, taken from the theme" },
            },
            required: ["insiderWord", "mismatchWord", "insiderCanonical", "mismatchCanonical", "category"],
          },
        },
      },
      required: ["title", "pairs"],
    },
  };
  if (!omitThinking) {
    config.thinkingConfig = { thinkingBudget: 0 };
  }
  return config;
}

function samplePair(pair: Pair) {
  return {
    insiderWord: pair.insiderWord,
    mismatchWord: pair.mismatchWord,
    insiderCanonical: pair.insiderCanonical,
    mismatchCanonical: pair.mismatchCanonical,
    category: pair.category,
  };
}

type ModelPayload = {
  candidates?: Array<{
    content?: { parts?: Array<{ text?: string; thought?: boolean }> };
  }>;
};

function parseModelPayload(payload: ModelPayload): { title: string; pairs: Pair[] } {
  const parts = payload.candidates?.[0]?.content?.parts ?? [];
  const visible = parts.filter((part) => !part.thought).map((part) => part.text ?? "").join("");
  const rawText = (visible || parts.map((part) => part.text ?? "").join("")).trim();
  return parseModelText(rawText);
}

function parseModelText(rawText: string): { title: string; pairs: Pair[] } {
  const text = rawText.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "").trim();
  if (!text) return { title: "", pairs: [] };
  for (const candidate of [text, closeTruncatedJson(text)]) {
    try {
      return normalizeParsed(JSON.parse(candidate));
    } catch {
      // A short reply can end inside a word. Try the next shape.
    }
  }
  return { title: "", pairs: [] };
}

function normalizeParsed(parsed: { title?: unknown; pairs?: unknown }): { title: string; pairs: Pair[] } {
  return {
    title: typeof parsed.title === "string" ? parsed.title : "",
    pairs: Array.isArray(parsed.pairs) ? parsed.pairs : [],
  };
}

function closeTruncatedJson(text: string): string {
  let inString = false;
  let escape = false;
  let lastSafe = -1;
  for (let index = 0; index < text.length; index++) {
    const char = text[index];
    if (inString) {
      if (escape) escape = false;
      else if (char === "\\") escape = true;
      else if (char === "\"") inString = false;
      continue;
    }
    if (char === "\"") {
      inString = true;
      continue;
    }
    if (char === "}" || char === "]") lastSafe = index;
  }
  if (lastSafe < 0) return text;

  let slice = text.slice(0, lastSafe + 1).replace(/,\s*$/, "");
  inString = false;
  escape = false;
  const open: string[] = [];
  for (const char of slice) {
    if (inString) {
      if (escape) escape = false;
      else if (char === "\\") escape = true;
      else if (char === "\"") inString = false;
      continue;
    }
    if (char === "\"") inString = true;
    else if (char === "{") open.push("}");
    else if (char === "[") open.push("]");
    else if ((char === "}" || char === "]") && open.length > 0) open.pop();
  }
  while (open.length > 0) slice += open.pop();
  return slice;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function sanitize(pair: Pair): Pair | null {
  const insiderWord = (pair.insiderWord ?? "").trim();
  const mismatchWord = (pair.mismatchWord ?? "").trim();
  const category = (pair.category ?? "").trim();
  if (!insiderWord || !mismatchWord || !category) return null;
  if (insiderWord.length > MAX_WORD || mismatchWord.length > MAX_WORD || category.length > MAX_WORD) return null;
  const insiderCanonical = canonicalOf(pair.insiderCanonical, insiderWord);
  const mismatchCanonical = canonicalOf(pair.mismatchCanonical, mismatchWord);
  if (!insiderCanonical || !mismatchCanonical || insiderCanonical === mismatchCanonical) return null;
  return { insiderWord, mismatchWord, insiderCanonical, mismatchCanonical, category };
}

function acceptable(pair: Pair, existing: Pair[], blockedPairs: Set<string>): boolean {
  if (blockedPairs.has(pairKey(pair))) return false;
  for (const other of existing) {
    if (wordsCollide(pair, other)) return false;
  }
  if (isShortForm(pair.insiderWord, pair.mismatchWord) || isShortForm(pair.mismatchWord, pair.insiderWord)) {
    return false;
  }
  if (isLookalike(pair.insiderWord, pair.mismatchWord) || isLookalike(pair.insiderCanonical, pair.mismatchCanonical)) {
    return false;
  }
  return true;
}

function wordsCollide(pair: Pair, other: Pair): boolean {
  const left = [pair.insiderWord, pair.mismatchWord, pair.insiderCanonical, pair.mismatchCanonical];
  const right = [other.insiderWord, other.mismatchWord, other.insiderCanonical, other.mismatchCanonical];
  for (const a of left) {
    for (const b of right) {
      if (normalizeWord(a) && normalizeWord(a) === normalizeWord(b)) return true;
      if (isShortForm(a, b) || isShortForm(b, a)) return true;
      if (isLookalike(a, b)) return true;
    }
  }
  return false;
}

function isLookalike(left: string, right: string): boolean {
  if (isNumberedSequel(left, right)) return false;
  const a = lettersOnly(left);
  const b = lettersOnly(right);
  if (!a || !b || a === b) return false;
  const shorter = Math.min(a.length, b.length);
  if (shorter < 5) return false;
  const distance = editDistance(a, b);
  if (distance === 1) return true;
  if (distance === 2 && shorter >= 8 && sharedCount(a, b, true) >= 3) return true;
  return false;
}

function lettersOnly(value: string): string {
  return normalizeWord(value).replace(/[^\p{L}]/gu, "");
}

function hasSequelMark(value: string): boolean {
  return /\b(\d+|ii|iii|iv|vi|vii|viii|ix|xi|xii)\b/i.test(value);
}

function isNumberedSequel(left: string, right: string): boolean {
  const leftMarked = hasSequelMark(left);
  const rightMarked = hasSequelMark(right);
  if (!leftMarked && !rightMarked) return false;
  const a = leftMarked ? sequelStem(left) : lettersOnly(left);
  const b = rightMarked ? sequelStem(right) : lettersOnly(right);
  return a.length > 0 && a === b;
}

function sequelStem(value: string): string {
  let letters = lettersOnly(value);
  for (const suffix of ["xii", "viii", "vii", "iii", "ii", "iv", "vi", "ix", "xi"]) {
    if (letters.endsWith(suffix) && letters.length > suffix.length + 2) {
      letters = letters.slice(0, -suffix.length);
      break;
    }
  }
  return letters;
}

function sharedCount(left: string, right: string, fromStart: boolean): number {
  const a = fromStart ? left : [...left].reverse().join("");
  const b = fromStart ? right : [...right].reverse().join("");
  let count = 0;
  const limit = Math.min(a.length, b.length);
  while (count < limit && a[count] === b[count]) count += 1;
  return count;
}

function editDistance(left: string, right: string): number {
  const a = [...left];
  const b = [...right];
  if (!a.length) return b.length;
  if (!b.length) return a.length;
  let previous = Array.from({ length: b.length + 1 }, (_, index) => index);
  let current = new Array<number>(b.length + 1).fill(0);
  for (let i = 1; i <= a.length; i++) {
    current[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      current[j] = Math.min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost);
    }
    previous = current;
    current = new Array<number>(b.length + 1).fill(0);
  }
  return previous[b.length];
}

function isShortForm(short: string, full: string): boolean {
  const compact = normalizeWord(short).replace(/\s/g, "");
  if (compact.length < 2 || compact.length > 5) return false;
  const words = significantWords(full);
  if (words.length < 2) return false;
  return compact === words.map((word) => word[0]).join("");
}

function significantWords(value: string): string[] {
  return normalizeWord(value)
    .split(" ")
    .filter((word) => word && !["a", "an", "the", "of", "and"].includes(word));
}

function normalizeWord(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, "")
    .replace(/\s+/g, " ")
    .trim();
}

function canonicalOf(canonical: string, display: string): string {
  return normalizeWord(canonical || display);
}

function pairKey(pair: Pair): string {
  return [canonicalOf(pair.insiderCanonical, pair.insiderWord), canonicalOf(pair.mismatchCanonical, pair.mismatchWord)]
    .sort()
    .join("|");
}

function normalizePrompt(value: string): string {
  return value.trim().replace(/\s+/g, " ").slice(0, MAX_PROMPT);
}

function cleanTitle(title: string, prompt: string): string {
  const trimmed = title.trim().replace(/\s+/g, " ");
  const fallback = prompt.trim().replace(/\s+/g, " ").slice(0, MAX_TITLE);
  if (!trimmed || trimmed.length > MAX_TITLE) return fallback;
  return trimmed;
}

function titleKey(title: string): string {
  return title.trim().replace(/\s+/g, " ").toLowerCase();
}

async function insertPack(host: Host, prompt: string, title: string, requestId: string, pairs: Pair[]) {
  const packs = await rest<Array<{ id: string }>>("word_packs", {
    method: "POST",
    body: JSON.stringify({
      host_id: host.id,
      prompt,
      title,
      request_id: requestId,
      is_archived: false,
    }),
  });
  const packId = packs[0]?.id;
  if (!packId) throw new Error("Could not save the pack");
  await rest("word_pairs", {
    method: "POST",
    body: JSON.stringify(pairs.map((pair) => ({
      pack_id: packId,
      host_id: host.id,
      insider_word: pair.insiderWord,
      mismatch_word: pair.mismatchWord,
      insider_canonical: pair.insiderCanonical,
      mismatch_canonical: pair.mismatchCanonical,
      category: pair.category,
      is_removed: false,
    }))),
    headers: { Prefer: "return=minimal" },
  });
  return await packDetail(host, packId);
}

async function listPacks(host: Host) {
  const ids = await scopedHostIds(host);
  const packs = await rest<Array<Record<string, unknown>>>(
    `word_packs?host_id=in.(${ids.join(",")})&is_archived=eq.false&select=id,prompt,title,created_at&order=created_at.desc`,
  );
  const result = [];
  for (const pack of packs) {
    result.push(await shapePack(String(pack.id), pack));
  }
  return result;
}

async function packDetail(host: Host, packId: string) {
  const pack = await ownedPack(host, packId);
  if (!pack) return null;
  return shapePack(packId, pack);
}

async function shapePack(packId: string, pack: Record<string, unknown>) {
  const pairs = await rest<Array<Record<string, unknown>>>(
    `word_pairs?pack_id=eq.${packId}&is_removed=eq.false&select=id,insider_word,mismatch_word,insider_canonical,mismatch_canonical,category,played_at`,
  );
  const shaped = pairs.map((pair) => ({
    id: pair.id,
    insiderWord: pair.insider_word,
    mismatchWord: pair.mismatch_word,
    insiderCanonical: pair.insider_canonical,
    mismatchCanonical: pair.mismatch_canonical,
    category: pair.category,
    playedAt: pair.played_at,
    isRemoved: false,
  }));
  const used = shaped.filter((pair) => pair.playedAt).length;
  return {
    id: pack.id ?? packId,
    prompt: pack.prompt,
    title: pack.title,
    createdAt: pack.created_at,
    pairs: shaped,
    used,
    remaining: shaped.length - used,
    total: shaped.length,
  };
}

async function packByRequest(host: Host, requestId: string) {
  const ids = await scopedHostIds(host);
  const rows = await rest<Array<{ id: string }>>(
    `word_packs?host_id=in.(${ids.join(",")})&request_id=eq.${encodeURIComponent(requestId)}&select=id`,
  );
  if (!rows[0]) return null;
  return packDetail(host, rows[0].id);
}

async function pendingByRequest(host: Host, requestId: string) {
  const rows = await rest<Array<{ payload: Record<string, unknown> }>>(
    `pending_generations?host_id=eq.${host.id}&request_id=eq.${encodeURIComponent(requestId)}&select=payload`,
  );
  return rows[0]?.payload ?? null;
}

async function activeTitles(host: Host, exceptPackId?: string): Promise<Set<string>> {
  const ids = await scopedHostIds(host);
  const rows = await rest<Array<{ id: string; title: string }>>(
    `word_packs?host_id=in.(${ids.join(",")})&is_archived=eq.false&select=id,title`,
  );
  return new Set(rows.filter((row) => row.id !== exceptPackId).map((row) => titleKey(row.title)));
}

async function exactPairKeys(host: Host, exceptPairId?: string): Promise<Set<string>> {
  const ids = await scopedHostIds(host);
  const rows = await rest<Array<Record<string, string>>>(
    `word_pairs?host_id=in.(${ids.join(",")})&is_removed=eq.false&select=id,insider_canonical,mismatch_canonical,pack_id`,
  );
  const packRows = await rest<Array<{ id: string }>>(
    `word_packs?host_id=in.(${ids.join(",")})&is_archived=eq.false&select=id`,
  );
  const active = new Set(packRows.map((row) => row.id));
  const keys = new Set<string>();
  for (const row of rows) {
    if (row.id === exceptPairId) continue;
    if (!active.has(row.pack_id)) continue;
    keys.add([normalizeWord(row.insider_canonical), normalizeWord(row.mismatch_canonical)].sort().join("|"));
  }
  return keys;
}

async function ownedPack(host: Host, packId: string) {
  const ids = await scopedHostIds(host);
  const rows = await rest<Array<Record<string, string>>>(
    `word_packs?id=eq.${packId}&host_id=in.(${ids.join(",")})&is_archived=eq.false&select=id,prompt,title,created_at,host_id`,
  );
  return rows[0] ?? null;
}

async function ownedPair(host: Host, packId: string, pairId: string) {
  const pack = await ownedPack(host, packId);
  if (!pack) return null;
  const rows = await rest<Array<Record<string, string>>>(
    `word_pairs?id=eq.${pairId}&pack_id=eq.${packId}&select=id,played_at,is_removed`,
  );
  const row = rows[0];
  if (!row || isRemovedFlag(row.is_removed)) return null;
  return row;
}

function isRemovedFlag(value: unknown): boolean {
  return value === true || value === "true";
}

async function pairsForPack(packId: string) {
  return rest<Array<Record<string, string>>>(
    `word_pairs?pack_id=eq.${packId}&select=id,insider_word,mismatch_word,insider_canonical,mismatch_canonical,category,played_at,is_removed`,
  );
}

function toPair(row: Record<string, string>): Pair {
  return {
    insiderWord: row.insider_word,
    mismatchWord: row.mismatch_word,
    insiderCanonical: row.insider_canonical,
    mismatchCanonical: row.mismatch_canonical,
    category: row.category,
  };
}

async function scopedHostIds(host: Host): Promise<string[]> {
  if (!host.user_id) return [host.id];
  return hostIds(host.user_id, host);
}

async function hostIds(userId: string, host: Host): Promise<string[]> {
  const rows = await rest<Array<{ id: string }>>(
    `hosts?user_id=eq.${userId}&select=id`,
  );
  const ids = new Set(rows.map((row) => row.id));
  ids.add(host.id);
  return [...ids];
}

async function signedInUserId(request: Request): Promise<string | null> {
  const token = (request.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const anon = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  if (!token || token === anon) return null;
  const response = await fetch(`${supabaseUrl()}/auth/v1/user`, {
    headers: { apikey: anon || serviceKey(), Authorization: `Bearer ${token}` },
  });
  if (!response.ok) return null;
  const user = await response.json();
  return typeof user?.id === "string" ? user.id : null;
}

async function rest<T>(path: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(`${supabaseUrl()}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: serviceKey(),
      Authorization: `Bearer ${serviceKey()}`,
      "Content-Type": "application/json",
      Prefer: "return=representation",
      ...(init.headers ?? {}),
    },
  });
  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`${response.status} ${detail}`);
  }
  if (response.status === 204) return [] as T;
  const text = await response.text();
  if (!text) return [] as T;
  return JSON.parse(text) as T;
}

async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function readJson(request: Request): Promise<Record<string, unknown>> {
  const text = await request.text();
  if (!text) return {};
  const parsed = JSON.parse(text);
  return parsed && typeof parsed === "object" ? parsed : {};
}

function stringField(body: Record<string, unknown>, key: string): string {
  const value = body[key];
  return typeof value === "string" ? value : "";
}

function numberField(body: Record<string, unknown>, key: string): number {
  const value = body[key];
  return typeof value === "number" ? value : Number(value);
}

function header(request: Request, name: string): string {
  return request.headers.get(name) ?? "";
}

function json(payload: unknown, status = 200): Response {
  return cors(new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  }));
}

function cors(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Headers", "authorization, apikey, content-type, x-host-token");
  headers.set("Access-Control-Allow-Methods", "GET, POST, PATCH, OPTIONS");
  return new Response(response.body, { status: response.status, headers });
}
