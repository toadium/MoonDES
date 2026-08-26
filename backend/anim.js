// MoonDES SVG Animation Engine
if (typeof mermaid !== 'undefined') {
  mermaid.initialize({
    startOnLoad: false, theme: 'dark',
    themeVariables: { darkMode: true, background: '#111127', primaryColor: '#0d1b2a', primaryTextColor: '#d0d0e0', primaryBorderColor: '#00d4ff', lineColor: '#666', secondaryColor: '#0f0f1a', tertiaryColor: '#111127' },
    flowchart: { curve: 'basis', padding: 16 }, stateDiagram: { useMaxWidth: true }
  });
}

function detectType(s) {
  s = s.trim();
  if (s.startsWith('stateDiagram')) return 'fsm';
  if (s.startsWith('flowchart')) return 'flow';
  if (s.startsWith('timeline')) return 'timeline';
  return 'flow';
}

function getPathLen(p) { try { return Math.round(p.getTotalLength()); } catch(e) { return 200; } }

function findEdges(svg) {
  var r = [];
  svg.querySelectorAll('path').forEach(function(p) { if ((p.getAttribute('d')||'').length > 10) r.push(p); });
  return r;
}

function findNodes(svg) {
  var r = [];
  svg.querySelectorAll('rect, circle, polygon, ellipse').forEach(function(s) {
    var w = parseFloat(s.getAttribute('width') || s.getAttribute('r') || 0);
    if (w > 5) r.push(s);
  });
  return r;
}

function animateSvg(svg, src) {
  var type = detectType(src);
  svg.setAttribute('data-anim-type', type);

  if (type === 'timeline') {
    var tlEls = svg.querySelectorAll('rect, line, circle, path');
    var idx = 0;
    tlEls.forEach(function(el) {
      var d = el.getAttribute('d') || '';
      var w = parseFloat(el.getAttribute('width') || el.getAttribute('r') || 0);
      if (d.length > 10 || w > 5) {
        el.classList.add('anim-tl-event');
        el.style.setProperty('--flow-delay', (idx * 0.3) + 's');
        idx++;
      }
    });
    return;
  }

  var edges = findEdges(svg);
  var nodes = findNodes(svg);
  var colors = ['anim-active', 'anim-active-orange', 'anim-active-green', 'anim-active-purple'];

  // Dim all nodes
  nodes.forEach(function(n) { n.classList.add('anim-node'); });

  // Animate edges
  var edgeDelay = type === 'fsm' ? 1.2 : 0.3;
  var edgeDur = type === 'fsm' ? '1.5s' : '2s';
  edges.forEach(function(e, i) {
    var len = getPathLen(e);
    e.classList.add('anim-edge', 'anim-edge-glow');
    e.style.setProperty('--flow-len', len);
    e.style.setProperty('--flow-dur', edgeDur);
    e.style.setProperty('--flow-delay', (i * edgeDelay) + 's');
  });

  // Activate nodes in sequence
  var nodeDelay = type === 'fsm' ? 600 : 200;
  nodes.forEach(function(n, i) {
    var c = colors[i % colors.length];
    setTimeout(function() { n.classList.add(c); }, i * nodeDelay);
  });
}

// Mermaid auto-render + animation
var mermaidCounter = 0;
var observer = new MutationObserver(function(mutations) {
  for (var mi = 0; mi < mutations.length; mi++) {
    var added = mutations[mi].addedNodes;
    for (var ni = 0; ni < added.length; ni++) {
      var node = added[ni];
      if (node.nodeType !== 1) continue;

      // Find mermaid divs
      var divs = node.classList && node.classList.contains('mermaid') ? [node] : (node.querySelectorAll ? node.querySelectorAll('.mermaid') : []);
      for (var di = 0; di < divs.length; di++) {
        var div = divs[di];
        if (div.getAttribute('data-processed') !== 'true' && div.textContent.trim()) {
          div.setAttribute('data-processed', 'true');
          var srcText = div.textContent.trim();
          div.setAttribute('data-src', srcText);
          var id = 'm-' + (++mermaidCounter);
          try {
            mermaid.render(id, srcText).then(function(result) {
              div.innerHTML = result.svg;
              var svg = div.querySelector('svg');
              if (svg) animateSvg(svg, srcText);
            }).catch(function() {});
          } catch (e) {}
        }
      }

      // Auto-scroll output
      var output = node.id === 'sim-output' ? node : (node.querySelector ? node.querySelector('#sim-output') : null);
      if (output) output.scrollTop = output.scrollHeight;
    }
  }
});
observer.observe(document.body, { childList: true, subtree: true });

// Output toolbar + replay
document.addEventListener('click', function(e) {
  if (!e.target) return;

  // Copy
  if (e.target.id === 'btn-copy') {
    var out = document.getElementById('sim-output');
    if (out) {
      navigator.clipboard.writeText(out.innerText).then(function() {
        e.target.textContent = '已复制 ✓';
        setTimeout(function() { e.target.textContent = '复制'; }, 1500);
      }).catch(function() {});
    }
  }

  // Download
  if (e.target.id === 'btn-download') {
    var out2 = document.getElementById('sim-output');
    if (out2) {
      var blob = new Blob([out2.innerText], { type: 'text/plain' });
      var a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'moondes-output.txt';
      a.click();
      URL.revokeObjectURL(a.href);
    }
  }

  // Replay animation
  if (e.target.id === 'btn-replay') {
    var mermaidDiv = document.querySelector('.mermaid');
    if (mermaidDiv) {
      var svg = mermaidDiv.querySelector('svg');
      var src = mermaidDiv.getAttribute('data-src') || '';
      if (svg && src) {
        // Remove old animation classes
        svg.querySelectorAll('.anim-node').forEach(function(n) {
          n.classList.remove('anim-node', 'anim-active', 'anim-active-orange', 'anim-active-green', 'anim-active-purple');
        });
        svg.querySelectorAll('.anim-edge').forEach(function(e2) {
          e2.classList.remove('anim-edge', 'anim-edge-glow');
          e2.style.removeProperty('--flow-len');
          e2.style.removeProperty('--flow-dur');
          e2.style.removeProperty('--flow-delay');
        });
        svg.querySelectorAll('.anim-tl-event').forEach(function(n) {
          n.classList.remove('anim-tl-event');
          n.style.removeProperty('--flow-delay');
        });
        // Force reflow then re-animate
        void svg.offsetWidth;
        animateSvg(svg, src);
      }
    }
  }
});
