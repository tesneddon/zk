// zk-autologin.js
//
// Answers the first VMS "Username:" prompt in a DCLinabox session, so
// players go straight into The Halls of ZK without knowing the account.
//
// DCLinabox loads this inside the terminal <iframe> (it is named by
// DCLinaboxConfig in index.html), before dclinabox.js opens its WebSocket.
// It wraps the browser's WebSocket so it can see the session output; it
// relies on nothing inside DCLinabox itself, only the standard WebSocket API.
//
// It answers once.  If the login fails (or the account later needs a
// password) the player sees the usual prompts and can carry on by hand.

(function () {
  var Native = window.WebSocket;
  if (!Native) return;

  // The username comes from the page holding the terminal (index.html)
  var user = '';
  try { user = (parent && parent.ZKAutoLoginUser) || ''; } catch (err) {}
  if (!user) return;

  function AutoLoginWebSocket(url, protocols) {
    var ws = (protocols === undefined) ? new Native(url) : new Native(url, protocols);
    var tail = '';
    var answered = false;

    ws.addEventListener('message', function (evt) {
      if (answered || typeof evt.data !== 'string') return;
      // keep only the end of the output: the prompt may arrive split
      tail = (tail + evt.data).slice(-80);
      if (/Username:\s*$/.test(tail)) {
        answered = true;
        // let the terminal draw the prompt before the reply echoes
        setTimeout(function () {
          if (ws.readyState === Native.OPEN) ws.send(user + '\r');
        }, 150);
      }
    });

    return ws;   // returned from a constructor, so `new` gives the real socket
  }

  AutoLoginWebSocket.prototype = Native.prototype;
  AutoLoginWebSocket.CONNECTING = Native.CONNECTING;
  AutoLoginWebSocket.OPEN = Native.OPEN;
  AutoLoginWebSocket.CLOSING = Native.CLOSING;
  AutoLoginWebSocket.CLOSED = Native.CLOSED;

  window.WebSocket = AutoLoginWebSocket;
})();
