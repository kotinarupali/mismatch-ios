(function () {
  const sessionToken = window.SESSION_TOKEN;
  const app = document.getElementById('app');

  let selectedPlayerId = localStorage.getItem('mismatch_player_' + sessionToken);
  let pollTimer = null;
  let assignment = null;
  let ghostBluffMode = false;
  let lastRevision = null;
  let claiming = false;

  if (!app) return;

  if (!sessionToken || sessionToken === '{{TOKEN}}') {
    app.innerHTML = '<p class="error">Invalid game link. Scan the host QR code again.</p>';
    return;
  }

  boot();

  function boot() {
    fetchSession()
      .then(function (session) {
        if (!session.players || session.players.length === 0) {
          app.innerHTML = '<h1>Waiting for players</h1><p class="sub">No guest players found yet. Ask the host to add players, then refresh.</p>';
          startPolling(function () { boot(); });
          return;
        }

        if (selectedPlayerId && findPlayer(session, selectedPlayerId)) {
          const player = findPlayer(session, selectedPlayerId);
          if (player.hasOpenedCard) {
            assignment = loadAssignment();
            if (assignment) {
              renderReveal(assignment);
            } else {
              renderPick(session);
            }
          } else {
            renderPick(session);
          }
        } else {
          renderWhoAreYou(session);
        }
      })
      .catch(function () {
        app.innerHTML = '<p class="error">Could not reach the game server. Check your internet connection and try again.</p>';
      });
  }

  function fetchSession() {
    return fetch('/api/session/' + encodeURIComponent(sessionToken), { cache: 'no-store' })
      .then(function (r) {
        if (!r.ok) throw new Error('not_found');
        return r.json();
      })
      .then(function (session) {
        lastRevision = session.revision;
        return session;
      });
  }

  function findPlayer(session, playerId) {
    return (session.players || []).find(function (p) { return p.id === playerId; });
  }

  function renderWhoAreYou(session) {
    stopPolling();
    let html = '<h1>Who are you?</h1><p class="sub">Tap your name to pick a card.</p><div class="player-list">';
    (session.players || []).forEach(function (player) {
      const picked = player.hasOpenedCard ? ' picked' : '';
      html += '<button class="player-btn' + picked + '" data-id="' + player.id + '">' +
        escapeHtml(player.displayName) +
        (player.hasOpenedCard ? ' ✓' : '') +
        '</button>';
    });
    html += '</div>';
    app.innerHTML = html;

    app.querySelectorAll('.player-btn:not(.picked)').forEach(function (btn) {
      btn.onclick = function () {
        selectedPlayerId = btn.getAttribute('data-id');
        localStorage.setItem('mismatch_player_' + sessionToken, selectedPlayerId);
        fetchSession().then(renderPick).catch(showError);
      };
    });
  }

  function renderPick(session, force) {
    if (claiming && !force) return;

    const player = findPlayer(session, selectedPlayerId);
    if (!player) {
      selectedPlayerId = null;
      localStorage.removeItem('mismatch_player_' + sessionToken);
      renderWhoAreYou(session);
      return;
    }

    if (player.hasOpenedCard && assignment) {
      renderReveal(assignment);
      return;
    }

    const count = session.faceDownCardCount || 4;
    const claimed = indexClaims(session.claimedCards || []);

    let html = '<div class="top-bar">' +
      '<button class="link-btn" id="change-player">Not you?</button>' +
      '<span class="player-tag">' + escapeHtml(player.displayName) + '</span></div>';
    html += '<h2>Pick a card</h2>';
    if ((session.claimedCards || []).length > 0) {
      html += '<p class="sub">Taken cards update live for everyone.</p>';
    }
    html += '<div class="grid" id="grid"></div>';
    app.innerHTML = html;

    document.getElementById('change-player').onclick = function () {
      assignment = null;
      ghostBluffMode = false;
      renderWhoAreYou(session);
    };

    const grid = document.getElementById('grid');
    if (count <= 3) {
      grid.style.gridTemplateColumns = 'repeat(' + count + ', 1fr)';
    }

    for (let i = 0; i < count; i++) {
      const claim = claimed[i];
      if (claim) {
        const taken = document.createElement('div');
        taken.className = 'card-taken';
        taken.innerHTML = '<span class="check">✓</span><span class="name">' + escapeHtml(claim.playerName) + '</span>';
        grid.appendChild(taken);
      } else {
        const btn = document.createElement('button');
        btn.className = 'card-back';
        btn.textContent = '?';
        btn.onclick = function () { claimCard(i, btn); };
        grid.appendChild(btn);
      }
    }

    startPolling(function () {
      fetchSession().then(function (next) {
        if (lastRevision !== next.revision) {
          renderPick(next, true);
        }
      }).catch(function () {});
    });
  }

  function claimCard(cardIndex, button) {
    if (claiming) return;
    claiming = true;
    stopPolling();

    if (button) {
      button.disabled = true;
      button.classList.add('claiming');
      button.textContent = '…';
    }

    fetch('/api/session/' + encodeURIComponent(sessionToken), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ playerId: selectedPlayerId, cardIndex: cardIndex })
    })
      .then(function (r) {
        if (r.status === 409) {
          return r.json().then(function (payload) {
            if (payload.revision != null) lastRevision = payload.revision;
            throw new Error('taken');
          });
        }
        if (!r.ok) throw new Error('failed');
        return r.json();
      })
      .then(function (data) {
        assignment = data;
        ghostBluffMode = false;
        if (data.revision != null) lastRevision = data.revision;
        saveAssignment(data);
        claiming = false;
        renderReveal(data);
      })
      .catch(function (err) {
        claiming = false;
        if (err.message === 'taken') {
          fetchSession().then(function (session) { renderPick(session, true); }).catch(showError);
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

  function renderReveal(data) {
    stopPolling();
    let html = '<div class="revealed">';
    if (data.showRoleOnCard) {
      html += '<div class="badge ' + data.role + '">' + capitalize(data.role) + '</div>';
    }

    if (data.role === 'ghost' && !ghostBluffMode) {
      html += '<p>No word — bluff from context</p>';
      if (data.categoryHint) {
        html += '<p class="hint">Hint: ' + escapeHtml(data.categoryHint) + '</p>';
      }
      if (data.insiderWord) {
        html += '<button class="secondary-btn" id="ghost-repick">Pick again</button>';
      }
    } else if (data.role === 'ghost' && ghostBluffMode && data.insiderWord) {
      html += '<p class="hint">Insider word</p>';
      html += '<div class="secret shown">' + escapeHtml(data.insiderWord) + '</div>';
      html += '<p class="hint">Memorize this, then bluff during discussion.</p>';
    } else if (data.word) {
      html += '<p>Press and hold to reveal</p>';
      html += '<div class="secret" id="secret">••••••</div>';
    }

    html += '</div>';
    app.innerHTML = html;

    const repick = document.getElementById('ghost-repick');
    if (repick) {
      repick.onclick = function () {
        ghostBluffMode = true;
        renderReveal(data);
      };
    }

    const secret = document.getElementById('secret');
    if (secret && data.word) {
      secret.addEventListener('touchstart', show);
      secret.addEventListener('touchend', hide);
      secret.addEventListener('mousedown', show);
      secret.addEventListener('mouseup', hide);
      function show() { secret.textContent = data.word; secret.classList.add('shown'); }
      function hide() { secret.textContent = '••••••'; secret.classList.remove('shown'); }
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

  function capitalize(s) {
    return s.charAt(0).toUpperCase() + s.slice(1);
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c];
    });
  }

  function showError() {
    app.innerHTML = '<p class="error">Something went wrong. Refresh and try again.</p>';
  }
})();
