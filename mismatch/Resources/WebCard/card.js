(function () {
  const token = window.CARD_TOKEN;
  const app = document.getElementById('app');

  if (!token) {
    app.innerHTML = '<p class="error">Invalid card link.</p>';
    return;
  }

  fetch('/api/card/' + token)
    .then(function (r) {
      if (!r.ok) throw new Error('not_found');
      return r.json();
    })
    .then(function (data) { renderPick(data); })
    .catch(function () {
      app.innerHTML = '<p class="error">This card link is invalid or expired.</p>';
    });

  function renderPick(data) {
    app.innerHTML = '<h2>Pick a card</h2><div class="grid" id="grid"></div>';
    const grid = document.getElementById('grid');
    for (let i = 0; i < 4; i++) {
      const btn = document.createElement('button');
      btn.className = 'card-back';
      btn.textContent = '?';
      btn.onclick = function () { renderReveal(data); };
      grid.appendChild(btn);
    }
  }

  function renderReveal(data) {
    let html = '<div class="revealed">';
    if (data.showRoleOnCard) {
      html += '<div class="badge ' + data.role + '">' + capitalize(data.role) + '</div>';
    }
    if (data.role === 'ghost') {
      html += '<p>No word — bluff from context</p>';
      if (data.categoryHint) {
        html += '<p class="hint">Hint: ' + escapeHtml(data.categoryHint) + '</p>';
      }
    } else if (data.word) {
      html += '<p>Press and hold to reveal</p>';
      html += '<div class="secret" id="secret">••••••</div>';
    }
    html += '</div>';
    app.innerHTML = html;

    const secret = document.getElementById('secret');
    if (secret && data.word) {
      secret.addEventListener('touchstart', show);
      secret.addEventListener('touchend', hide);
      secret.addEventListener('mousedown', show);
      secret.addEventListener('mouseup', hide);
      function show() { secret.textContent = data.word; }
      function hide() { secret.textContent = '••••••'; }
    }
  }

  function capitalize(s) {
    return s.charAt(0).toUpperCase() + s.slice(1);
  }

  function escapeHtml(s) {
    return s.replace(/[&<>"']/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c];
    });
  }
})();
