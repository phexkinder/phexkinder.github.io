// Submenus of the /new main menu: buttons open and close them (aria-expanded), Esc and clicks outside close
// them. On small screens the CSS keeps every submenu open, so the buttons just report "expanded".
(function () {
  var nav = document.getElementById('access');
  if (!nav) return;
  var toggles = nav.querySelectorAll('.submenu-toggle');
  var small = window.matchMedia('(max-width: 800px)');

  function setOpen(toggle, open) {
    toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    toggle.parentNode.classList.toggle('is-open', open);
  }
  function closeAll(except) {
    toggles.forEach(function (t) { if (t !== except) setOpen(t, false); });
  }
  function syncSmall() {
    toggles.forEach(function (t) {
      if (small.matches) { t.setAttribute('aria-expanded', 'true'); t.parentNode.classList.remove('is-open'); }
      else setOpen(t, false);
    });
  }

  toggles.forEach(function (t) {
    t.addEventListener('click', function () {
      if (small.matches) return;
      var open = t.getAttribute('aria-expanded') !== 'true';
      closeAll(t);
      setOpen(t, open);
    });
  });
  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape' || small.matches) return;
    var open = nav.querySelector('.submenu-toggle[aria-expanded="true"]');
    if (open) { setOpen(open, false); open.focus(); }
  });
  document.addEventListener('click', function (e) {
    if (!nav.contains(e.target)) closeAll(null);
  });
  if (small.addEventListener) small.addEventListener('change', syncSmall); else small.addListener(syncSmall);
  syncSmall();
})();
