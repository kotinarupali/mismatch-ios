(function () {
  const sessionToken = window.SESSION_TOKEN;
  const app = document.getElementById('app');

  let selectedPlayerId = localStorage.getItem('mismatch_player_' + sessionToken);
  let pollTimer = null;
  let assignment = null;
  let lastRevision = null;
  let claiming = false;
  let votingRound = 0;
  let myVoteTargetId = null;
  let lastGhostCardIndex = null;

  if (!app) return;

  if (!sessionToken || sessionToken === '{{TOKEN}}') {
    app.innerHTML = screenShell('<p class="error">Invalid game link. Scan the host QR code again.</p>');
    return;
  }

  boot();

  function screenShell(content, subtitle) {
    const sub = subtitle || 'Pick your card';
    return (
      '<div class="screen">' +
        '<header class="brand">' +
          '<img class="brand-mark" src="/art/app-icon.jpg" alt="">' +
          '<h1 class="brand-title">Sus Out</h1>' +
          '<p class="brand-sub">' + escapeHtml(sub) + '</p>' +
        '</header>' +
        '<div class="panel">' + content + '</div>' +
      '</div>'
    );
  }

  function shouldShowVote(session) {
    return session.votingEnabled && session.votingOpen && selectedPlayerId;
  }

  function routeSession(session) {
    if (session.votingRound != null) {
      if (session.votingRound !== votingRound) {
        votingRound = session.votingRound;
        myVoteTargetId = loadVote();
      }
    }

    if (shouldShowVote(session)) {
      const player = findPlayer(session, selectedPlayerId);
      if (player && player.hasOpenedCard) {
        renderVote(session);
        return true;
      }
    }
    return false;
  }

  function boot() {
    fetchSession()
      .then(function (session) {
        noteRevision(session);
        if (routeSession(session)) return;

        if (!session.players || session.players.length === 0) {
          app.innerHTML = screenShell(
            '<h2 class="headline">Waiting for players</h2>' +
            '<p class="sub">No guest players found yet. Ask the host to add players, then refresh.</p>'
          );
          startPolling(function () { boot(); });
          return;
        }

        if (session.holdsPlayerId && findPlayer(session, session.holdsPlayerId)) {
          selectedPlayerId = session.holdsPlayerId;
          localStorage.setItem('mismatch_player_' + sessionToken, selectedPlayerId);
          if (session.myCard) {
            assignment = session.myCard;
            saveAssignment(session.myCard);
            renderReveal(session.myCard);
          } else {
            assignment = null;
            renderPick(session);
          }
        } else {
          clearIdentity();
          renderWhoAreYou(session);
        }
      })
      .catch(function (err) {
        if (sessionEnded(err)) {
          gameOver();
          return;
        }
        app.innerHTML = screenShell(
          '<p class="error">Could not reach the game server. Check your internet connection and try again.</p>'
        );
      });
  }

  function deviceToken() {
    const key = 'mismatch_device_' + sessionToken;
    let token = localStorage.getItem(key);
    if (!token) {
      token = (window.crypto && crypto.randomUUID) ? crypto.randomUUID() : (Date.now().toString(36) + Math.random().toString(36).slice(2));
      localStorage.setItem(key, token);
    }
    return token;
  }

  function fetchSession() {
    const query = '?deviceToken=' + encodeURIComponent(deviceToken());
    return fetch('/api/session/' + encodeURIComponent(sessionToken) + query, { cache: 'no-store' })
      .then(function (r) {
        if (r.status === 404) throw new Error('not_found');
        if (!r.ok) throw new Error('failed');
        return r.json().then(function (session) {
          if (session && session.ended) throw new Error('not_found');
          return session;
        });
      });
  }

  function sessionEnded(err) {
    return err && err.message === 'not_found';
  }

  function onSessionFailure(err) {
    if (sessionEnded(err)) gameOver();
    else showError();
  }

  function onPollFailure(err) {
    if (sessionEnded(err)) gameOver();
  }

  function gameOver() {
    stopPolling();
    assignment = null;
    clearStoredSession();
    app.innerHTML = screenShell(
      '<h2 class="headline">This game is over</h2>' +
      '<p class="sub">The host ended it. This page is closed.</p>',
      'Game over'
    );
  }

  function clearStoredSession() {
    try {
      var keys = [];
      for (var i = 0; i < localStorage.length; i++) {
        var key = localStorage.key(i);
        if (key && key.indexOf(sessionToken) !== -1) keys.push(key);
      }
      keys.forEach(function (key) { localStorage.removeItem(key); });
    } catch (e) {}
  }

  function stillHolds(session) {
    return !!selectedPlayerId && session.holdsPlayerId === selectedPlayerId;
  }

  function clearIdentity() {
    assignment = null;
    if (selectedPlayerId) {
      localStorage.removeItem('mismatch_assignment_' + sessionToken + '_' + selectedPlayerId);
    }
    selectedPlayerId = null;
    localStorage.removeItem('mismatch_player_' + sessionToken);
  }

  function lostCard() {
    stopPolling();
    clearIdentity();
    app.innerHTML = screenShell(
      '<h2 class="headline">The host gave this card back</h2>' +
      '<p class="sub">This phone no longer has it. Tap your name to pick again.</p>' +
      '<button type="button" class="secondary-btn" id="pick-again">Tap your name</button>'
    );
    document.getElementById('pick-again').onclick = function () {
      fetchSession().then(renderWhoAreYou).catch(onSessionFailure);
    };
  }

  function noteRevision(session) {
    if (session && session.revision != null) {
      lastRevision = session.revision;
    }
  }

  function sessionChanged(next) {
    return next.votingRound !== votingRound || next.revision !== lastRevision;
  }

  function handleSessionUpdate(next) {
    noteRevision(next);
    if (routeSession(next)) return true;
    return false;
  }

  function findPlayer(session, playerId) {
    return (session.players || []).find(function (p) { return p.id === playerId; });
  }

  function renderWhoAreYou(session, message) {
    stopPolling();
    let list = '';
    (session.players || []).forEach(function (player) {
      const taken = player.hasOpenedCard || player.nameHeld;
      const picked = taken ? ' picked' : '';
      const mark = player.hasOpenedCard ? ' Picked' : (player.nameHeld ? ' On a phone' : '');
      list += '<button type="button" class="player-btn' + picked + '" data-id="' + player.id + '">' +
        escapeHtml(player.displayName) + mark +
        '</button>';
    });

    app.innerHTML = screenShell(
      '<h2 class="headline">Who are you?</h2>' +
      '<p class="sub">Tap your name. The first phone to tap it keeps that card.</p>' +
      (message ? '<p class="error">' + escapeHtml(message) + '</p>' : '') +
      '<div class="player-list">' + list + '</div>'
    );

    app.querySelectorAll('.player-btn:not(.picked)').forEach(function (btn) {
      btn.onclick = function () {
        const playerId = btn.getAttribute('data-id');
        btn.disabled = true;
        fetch('/api/session/' + encodeURIComponent(sessionToken) + '/lock', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ playerId: playerId, deviceToken: deviceToken() })
        })
          .then(function (r) {
            if (r.status === 409) {
              return fetchSession().then(function (next) {
                renderWhoAreYou(next, 'That name is already on another phone.');
              });
            }
            if (r.status === 404) throw new Error('not_found');
            if (!r.ok) throw new Error('failed');
            selectedPlayerId = playerId;
            localStorage.setItem('mismatch_player_' + sessionToken, selectedPlayerId);
            return fetchSession().then(renderPick);
          })
          .catch(onSessionFailure);
      };
    });
  }

  function renderPick(session, force) {
    if (claiming && !force) return;
    noteRevision(session);

    if (!stillHolds(session)) {
      lostCard();
      return;
    }

    const player = findPlayer(session, selectedPlayerId);
    if (!player) {
      lostCard();
      return;
    }

    if (player.hasOpenedCard && assignment) {
      renderReveal(assignment);
      return;
    }

    const count = session.faceDownCardCount || 4;
    const claimed = indexClaims(session.claimedCards || []);
    const passedGhostCardIndex = loadPassedGhostCardIndex();
    const isRepickAfterGhost = passedGhostCardIndex != null;

    let sub = '';
    if (isRepickAfterGhost) {
      sub = '<p class="sub">You can\'t pick the ghost card again. Someone else will get that role.</p>';
    } else if ((session.claimedCards || []).length > 0) {
      sub = '<p class="sub">Cards already taken are marked with names.</p>';
    }

    app.innerHTML = screenShell(
      '<div class="top-bar">' +
        '<span class="player-tag">' + escapeHtml(player.displayName) + '</span>' +
      '</div>' +
      '<h2 class="headline">' +
        (isRepickAfterGhost
          ? 'Pick a different card — the ghost card stays open for someone else'
          : 'Pick a card to see your role') +
      '</h2>' +
      sub +
      '<p class="sub">Wrong name? Ask the host to give this card back.</p>' +
      '<div class="grid" id="grid"></div>'
    );

    const grid = document.getElementById('grid');
    if (count <= 3) {
      grid.style.gridTemplateColumns = 'repeat(' + count + ', 1fr)';
    }

    for (let i = 0; i < count; i++) {
      const claim = claimed[i];
      if (claim) {
        const taken = document.createElement('div');
        taken.className = 'card-taken';
        taken.innerHTML =
          '<span class="card-taken-icon" aria-hidden="true">✓</span>' +
          '<span class="name">' + escapeHtml(claim.playerName) + '</span>';
        grid.appendChild(taken);
      } else if (isRepickAfterGhost && passedGhostCardIndex === i) {
        const stillOpen = document.createElement('div');
        stillOpen.className = 'card-taken card-still-open';
        stillOpen.innerHTML =
          '<span class="card-taken-icon" aria-hidden="true">☾</span>' +
          '<span class="name">Still open</span>';
        grid.appendChild(stillOpen);
      } else {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'card-back';
        btn.innerHTML = '<span class="card-back-icon">?</span>';
        btn.setAttribute('aria-label', 'Face-down card');
        btn.onclick = function () { claimCard(i, btn); };
        grid.appendChild(btn);
      }
    }

    startPolling(function () {
      fetchSession().then(function (next) {
        if (!stillHolds(next)) {
          lostCard();
          return;
        }
        if (sessionChanged(next)) {
          if (handleSessionUpdate(next)) return;
          renderPick(next, true);
        }
      }).catch(onPollFailure);
    });
  }

  function renderVoteCasts(session) {
    const casts = session.voteCasts || [];
    if (!casts.length) return '';

    let items = '';
    casts.forEach(function (cast) {
      items += '<li class="vote-cast-item">' +
        '<span class="vote-cast-voter">' + escapeHtml(cast.voterName) + '</span>' +
        '<span class="vote-cast-arrow" aria-hidden="true">→</span>' +
        '<span class="vote-cast-target">' + escapeHtml(cast.targetName) + '</span>' +
        '</li>';
    });

    return (
      '<div class="vote-casts">' +
        '<p class="sub vote-casts-title">Votes so far</p>' +
        '<ul class="vote-cast-list">' + items + '</ul>' +
      '</div>'
    );
  }

  function renderVote(session) {
    noteRevision(session);

    const player = findPlayer(session, selectedPlayerId);
    if (!player) {
      renderWhoAreYou(session);
      return;
    }

    const targets = (session.voteTargets || []).filter(function (target) {
      const excluded = session.revoteExcludedPlayerIds || [];
      return !target.isEliminated
        && target.id !== selectedPlayerId
        && excluded.indexOf(target.id) === -1;
    });

    const isRevote = (session.revoteExcludedPlayerIds || []).length > 0;
    let list = '';
    targets.forEach(function (target) {
      const selected = myVoteTargetId === target.id ? ' selected' : '';
      const tally = (session.voteTallies && session.voteTallies[target.id]) || 0;
      list += '<button type="button" class="player-btn vote-btn' + selected + '" data-id="' + target.id + '">' +
        escapeHtml(target.displayName) +
        (tally > 0 ? ' <span class="vote-count">' + tally + '</span>' : '') +
        '</button>';
    });

    let status = myVoteTargetId
      ? '<p class="sub success-copy">Vote submitted. You can change it until the host closes voting.</p>'
      : isRevote
        ? '<p class="sub">There was a tie — vote again. Players who tied can\'t be chosen.</p>'
        : '<p class="sub">Tap who you think should be eliminated.</p>';

    app.innerHTML = screenShell(
      '<div class="top-bar">' +
        '<button type="button" class="link-btn" id="view-card">View my card</button>' +
        '<span class="player-tag">' + escapeHtml(player.displayName) + '</span>' +
      '</div>' +
      '<h2 class="headline">' + (isRevote ? 'Revote' : 'Cast your vote') + '</h2>' +
      status +
      renderVoteCasts(session) +
      '<div class="player-list vote-list">' + list + '</div>',
      'Vote on your phone'
    );

    document.getElementById('view-card').onclick = function () {
      fetchSession().then(function (next) {
        if (!stillHolds(next)) {
          lostCard();
          return;
        }
        if (next.myCard) {
          assignment = next.myCard;
          saveAssignment(next.myCard);
          stopPolling();
          renderReveal(next.myCard);
        }
      }).catch(onSessionFailure);
    };

    app.querySelectorAll('.vote-btn').forEach(function (btn) {
      btn.onclick = function () {
        submitVote(btn.getAttribute('data-id'));
      };
    });

    startPolling(function () {
      fetchSession().then(function (next) {
        if (!stillHolds(next)) {
          lostCard();
          return;
        }
        if (!shouldShowVote(next)) {
          boot();
          return;
        }
        if (sessionChanged(next)) {
          handleSessionUpdate(next);
        }
      }).catch(onPollFailure);
    });
  }

  function submitVote(targetPlayerId) {
    if (!selectedPlayerId || !targetPlayerId) return;

    fetch('/api/session/' + encodeURIComponent(sessionToken) + '/vote', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        voterId: selectedPlayerId,
        targetPlayerId: targetPlayerId,
        deviceToken: deviceToken()
      })
    })
      .then(function (r) {
        if (r.status === 404) throw new Error('not_found');
        if (!r.ok) throw new Error('failed');
        return r.json();
      })
      .then(function (payload) {
        myVoteTargetId = targetPlayerId;
        saveVote(targetPlayerId);
        if (payload.revision != null) lastRevision = payload.revision;
        fetchSession().then(renderVote).catch(onSessionFailure);
      })
      .catch(onSessionFailure);
  }

  function voteStorageKey() {
    return 'mismatch_vote_' + sessionToken + '_' + selectedPlayerId + '_' + votingRound;
  }

  function saveVote(targetPlayerId) {
    localStorage.setItem(voteStorageKey(), targetPlayerId);
  }

  function loadVote() {
    return localStorage.getItem(voteStorageKey());
  }

  function claimCard(cardIndex, button) {
    if (claiming) return;
    claiming = true;
    stopPolling();

    if (button) {
      button.disabled = true;
      button.classList.add('claiming');
      button.querySelector('.card-back-icon').textContent = '…';
    }

    fetch('/api/session/' + encodeURIComponent(sessionToken), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        playerId: selectedPlayerId,
        cardIndex: cardIndex,
        deviceToken: deviceToken()
      })
    })
      .then(function (r) {
        if (r.status === 409) {
          return r.json().then(function (payload) {
            if (payload.revision != null) lastRevision = payload.revision;
            if (payload.error === 'name_taken') throw new Error('name_taken');
            throw new Error('taken');
          });
        }
        if (r.status === 404) throw new Error('not_found');
        if (!r.ok) throw new Error('failed');
        return r.json();
      })
      .then(function (data) {
        assignment = data;
        if (data.revision != null) lastRevision = data.revision;
        if (data.role === 'ghost') {
          lastGhostCardIndex = cardIndex;
        } else {
          lastGhostCardIndex = null;
          savePassedGhostCardIndex(null);
        }
        saveAssignment(data);
        claiming = false;
        renderReveal(data, cardIndex);
      })
      .catch(function (err) {
        claiming = false;
        if (err.message === 'name_taken') {
          fetchSession().then(function (session) {
            if (stillHolds(session)) renderPick(session, true);
            else lostCard();
          }).catch(onSessionFailure);
        } else if (err.message === 'taken') {
          fetchSession().then(function (session) { renderPick(session, true); }).catch(onSessionFailure);
        } else if (sessionEnded(err)) {
          gameOver();
        } else {
          showError();
        }
      });
  }

  function saveAssignment(data) {
    if (!selectedPlayerId) return;
    localStorage.setItem(
      'mismatch_assignment_' + sessionToken + '_' + selectedPlayerId,
      JSON.stringify(data)
    );
  }

  function loadAssignment() {
    if (!selectedPlayerId) return null;
    const raw = localStorage.getItem('mismatch_assignment_' + sessionToken + '_' + selectedPlayerId);
    if (!raw) return null;
    try { return JSON.parse(raw); } catch (e) { return null; }
  }

  function passedGhostStorageKey() {
    return 'mismatch_passed_ghost_' + sessionToken + '_' + selectedPlayerId;
  }

  function savePassedGhostCardIndex(index) {
    if (index == null) {
      localStorage.removeItem(passedGhostStorageKey());
      return;
    }
    localStorage.setItem(passedGhostStorageKey(), String(index));
  }

  function loadPassedGhostCardIndex() {
    const raw = localStorage.getItem(passedGhostStorageKey());
    if (raw == null) return null;
    const parsed = parseInt(raw, 10);
    return isNaN(parsed) ? null : parsed;
  }

  function roleCallout(role, title, detail) {
    return (
      '<div class="role-callout ' + role + '">' +
        '<div class="badge ' + role + '">' + escapeHtml(title) + '</div>' +
        '<p class="reveal-copy">' + escapeHtml(detail) + '</p>' +
      '</div>'
    );
  }

  function renderReveal(data, claimedCardIndex) {
    stopPolling();
    let body = '<div class="revealed">';

    if (data.role === 'ghost') {
      body += roleCallout('ghost', 'Ghost', 'You have no secret word');
      body += '<div class="secret shown word-reveal">You are the Ghost</div>';
      if (data.categoryHint) {
        body += '<p class="hint">Hint: ' + escapeHtml(data.categoryHint) + '</p>';
      }
      if (data.canSwapGhostRole) {
        body += '<button type="button" class="secondary-btn" id="ghost-repick">Pick again for another role</button>';
      }
    } else if (data.role === 'mismatch' && data.showRoleOnCard) {
      savePassedGhostCardIndex(null);
      lastGhostCardIndex = null;
      body += roleCallout('mismatch', 'Mismatch', 'Your word is different from the group');
      if (data.word) {
        body += '<div class="secret shown word-reveal">' + escapeHtml(data.word) + '</div>';
      }
      body += '<p class="reveal-copy emphasis">You are the Mismatch</p>';
    } else if (data.word) {
      savePassedGhostCardIndex(null);
      lastGhostCardIndex = null;
      if (data.showRoleOnCard) {
        body += '<div class="badge insider">Insider</div>';
      }
      body += '<p class="reveal-copy">Your secret word is</p>';
      body += '<div class="secret shown word-reveal">' + escapeHtml(data.word) + '</div>';
    }

    body += '</div>';
    app.innerHTML = screenShell(body, 'Your secret card');

    fetchSession().then(function (session) {
      if (!stillHolds(session)) {
        lostCard();
        return;
      }
      if (session.myCard) {
        assignment = session.myCard;
        saveAssignment(session.myCard);
      }
      if (shouldShowVote(session)) {
        const banner = document.createElement('button');
        banner.type = 'button';
        banner.className = 'vote-banner';
        banner.textContent = 'Voting is open — tap to cast your vote';
        banner.onclick = function () { renderVote(session); };
        app.querySelector('.panel').prepend(banner);
      }
    }).catch(onPollFailure);

    startPolling(function () {
      fetchSession().then(function (session) {
        if (!stillHolds(session)) {
          lostCard();
          return;
        }
        if (shouldShowVote(session)) {
          const existing = app.querySelector('.vote-banner');
          if (!existing) {
            const banner = document.createElement('button');
            banner.type = 'button';
            banner.className = 'vote-banner';
            banner.textContent = 'Voting is open — tap to cast your vote';
            banner.onclick = function () { renderVote(session); };
            app.querySelector('.panel').prepend(banner);
          }
        }
      }).catch(onPollFailure);
    });

    const repick = document.getElementById('ghost-repick');
    if (repick) {
      repick.onclick = function () {
        const passedIndex = claimedCardIndex != null ? claimedCardIndex : lastGhostCardIndex;
        fetch('/api/session/' + encodeURIComponent(sessionToken) + '/swap-ghost', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ playerId: selectedPlayerId, deviceToken: deviceToken() })
        })
          .then(function (r) {
            if (r.status === 404) throw new Error('not_found');
            if (!r.ok) throw new Error('failed');
            return r.json();
          })
          .then(function () {
            savePassedGhostCardIndex(passedIndex);
            assignment = null;
            localStorage.removeItem('mismatch_assignment_' + sessionToken + '_' + selectedPlayerId);
            fetchSession().then(function (session) { renderPick(session, true); }).catch(onSessionFailure);
          })
          .catch(onSessionFailure);
      };
    }
  }

  function startPolling(tick) {
    stopPolling();
    pollTimer = setInterval(tick, 300);
  }

  function stopPolling() {
    if (pollTimer) {
      clearInterval(pollTimer);
      pollTimer = null;
    }
  }

  function indexClaims(claimedCards) {
    const map = {};
    claimedCards.forEach(function (c) { map[c.cardIndex] = c; });
    return map;
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c];
    });
  }

  function showError() {
    app.innerHTML = screenShell(
      '<p class="error">Something went wrong. Refresh and try again.</p>'
    );
  }
})();
