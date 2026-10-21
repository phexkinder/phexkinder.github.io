// Search page of the /new preview: Pagefind's default UI (German, detected from <html lang>), result links
// stay inside /new, and a ?q=... in the address (the header search box) starts the search.
(function () {
  if (typeof PagefindUI === 'undefined') return;
  var base = document.querySelector('link[href$="pagefind-ui.css"]').getAttribute('href').replace(/pagefind\/pagefind-ui\.css$/, '');
  var ui = new PagefindUI({
    element: '#search',
    baseUrl: base,
    showImages: false,
    showSubResults: false,
    resetStyles: false,
    autofocus: true
  });
  var q = new URLSearchParams(window.location.search).get('q');
  if (q) ui.triggerSearch(q);
})();
