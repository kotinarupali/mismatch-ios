(function () {
  const sessionToken = window.SESSION_TOKEN;
  const app = document.getElementById('app');

  let selectedPlayerId = localStorage.getItem('mismatch_player_' + sessionToken);
  let pollTimer = null;
  let assignment = null;
  let ghostBluffMode = false;
  let lastRevision = null;
  let claiming = false;
  let votingRound = 0;
  let myVoteTargetId = null;

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
          '<div class="brand-mark" aria-hidden="true">' +
            '<span class="brand-tile brand-tile-mismatch"></span>' +
            '<span class="brand-tile brand-tile-insider"></span>' +
            '<span class="brand-tile brand-tile-sad"></span>' +
            '<span class="brand-tile brand-tile-ghost"></span>' +
          '</div>' +
          '<h1 class="brand-title">Mismatch</h1>' +
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
        if (routeSession(session)) return;

        if (!session.players || session.players.length === 0) {
          app.innerHTML = screenShell(
            '<h2 class="headline">Waiting for players</h2>' +
            '<p class="sub">No guest players found yet. Ask the host to add players, then refresh.</p>'
          );
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
        app.innerHTML = screenShell(
          '<p class="error">Could not reach the game server. Check your internet connection and try again.</p>'
        );
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
    let list = '';
    (session.players || []).forEach(function (player) {
      const picked = player.hasOpenedCard ? ' picked' : '';
      list += '<button type="button" class="player-btn' + picked + '" data-id="' + player.id + '">' +
        escapeHtml(player.displayName) +
        (player.hasOpenedCard ? ' ✓' : '') +
        '</button>';
    });

    app.innerHTML = screenShell(
      '<h2 class="headline">Who are you?</h2>' +
      '<p class="sub">Tap your name to pick a card.</p>' +
      '<div class="player-list">' + list + '</div>'
    );

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

    let sub = '';
    if ((session.claimedCards || []).length > 0) {
      sub = '<p class="sub">Cards already taken are marked with names.</p>';
    }

    app.innerHTML = screenShell(
      '<div class="top-bar">' +
        '<button type="button" class="link-btn" id="change-player">Not you?</button>' +
        '<span class="player-tag">' + escapeHtml(player.displayName) + '</span>' +
      '</div>' +
      '<h2 class="headline">Pick a card to see your role</h2>' +
      sub +
      '<div class="grid" id="grid"></div>'
    );

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
        taken.innerHTML =
          '<span class="card-taken-icon" aria-hidden="true">✓</span>' +
          '<span class="name">' + escapeHtml(claim.playerName) + '</span>';
        grid.appendChild(taken);
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
        if (routeSession(next)) return;
        if (lastRevision !== next.revision) {
          renderPick(next, true);
        }
      }).catch(function () {});
    });
  }

  function renderVote(session) {
    const player = findPlayer(session, selectedPlayerId);
    if (!player) {
      renderWhoAreYou(session);
      return;
    }

    const targets = (session.voteTargets || []).filter(function (target) {
      return !target.isEliminated && target.id !== selectedPlayerId;
    });

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
      : '<p class="sub">Tap who you think should be eliminated.</p>';

    app.innerHTML = screenShell(
      '<div class="top-bar">' +
        '<button type="button" class="link-btn" id="view-card">View my card</button>' +
        '<span class="player-tag">' + escapeHtml(player.displayName) + '</span>' +
      '</div>' +
      '<h2 class="headline">Cast your vote</h2>' +
      status +
      '<div class="player-list vote-list">' + list + '</div>',
      'Vote on your phone'
    );

    document.getElementById('view-card').onclick = function () {
      assignment = loadAssignment();
      if (assignment) {
        stopPolling();
        renderReveal(assignment);
      }
    };

    app.querySelectorAll('.vote-btn').forEach(function (btn) {
      btn.onclick = function () {
        submitVote(btn.getAttribute('data-id'));
      };
    });

    startPolling(function () {
      fetchSession().then(function (next) {
        if (!shouldShowVote(next)) {
          boot();
          return;
        }
        if (next.votingRound !== votingRound || next.revision !== lastRevision) {
          routeSession(next);
        }
      }).catch(function () {});
    });
  }

  function submitVote(targetPlayerId) {
    if (!selectedPlayerId || !targetPlayerId) return;

    fetch('/api/session/' + encodeURIComponent(sessionToken) + '/vote', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ voterId: selectedPlayerId, targetPlayerId: targetPlayerId })
    })
      .then(function (r) {
        if (!r.ok) throw new Error('failed');
        return r.json();
      })
      .then(function (payload) {
        myVoteTargetId = targetPlayerId;
        saveVote(targetPlayerId);
        if (payload.revision != null) lastRevision = payload.revision;
        fetchSession().then(renderVote).catch(showError);
      })
      .catch(showError);
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
    let body = '<div class="revealed">';

    if (data.showRoleOnCard) {
      body += '<div class="badge ' + data.role + '">' + capitalize(data.role) + '</div>';
    }

    if (data.role === 'ghost' && !ghostBluffMode) {
      body += '<p class="reveal-copy">No word — bluff from context</p>';
      if (data.categoryHint) {
        body += '<p class="hint">Hint: ' + escapeHtml(data.categoryHint) + '</p>';
      }
      if (data.insiderWord) {
        body += '<button type="button" class="secondary-btn" id="ghost-repick">Pick again</button>';
      }
    } else if (data.role === 'ghost' && ghostBluffMode && data.insiderWord) {
      body += '<p class="hint">Insider word</p>';
      body += '<div class="secret shown">' + escapeHtml(data.insiderWord) + '</div>';
      body += '<p class="hint">Memorize this, then bluff during discussion.</p>';
    } else if (data.word) {
      body += '<p class="reveal-copy">Press and hold to reveal</p>';
      body += '<div class="secret" id="secret">••••••</div>';
    }

    body += '</div>';
    app.innerHTML = screenShell(body, 'Your secret card');

    fetchSession().then(function (session) {
      if (shouldShowVote(session)) {
        const banner = document.createElement('button');
        banner.type = 'button';
        banner.className = 'vote-banner';
        banner.textContent = 'Voting is open — tap to cast your vote';
        banner.onclick = function () { renderVote(session); };
        app.querySelector('.panel').prepend(banner);
      }
    }).catch(function () {});

    startPolling(function () {
      fetchSession().then(function (session) {
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
      }).catch(function () {});
    });

    const repick = document.getElementById('ghost-repick');
    if (repick) {
      repick.onclick = function () {
        ghostBluffMode = true;
        renderReveal(data);
      };
    }

    const secret = document.getElementById('secret');
    if (secret && data.word) {
      secret.addEventListener('touchstart', show, { passive: true });
      secret.addEventListener('touchend', hide);
      secret.addEventListener('mousedown', show);
      secret.addEventListener('mouseup', hide);
      secret.addEventListener('mouseleave', hide);
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
    app.innerHTML = screenShell(
      '<p class="error">Something went wrong. Refresh and try again.</p>'
    );
  }
})();
