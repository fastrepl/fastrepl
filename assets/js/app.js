// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import { getHooks } from "live_svelte";
import * as Components from "../svelte/**/*.svelte";

import tippy from "tippy.js";

import hljs from "highlight.js";
window.hljs = hljs;

import posthog from "posthog-js";
posthog.init("phc_qdLGlOK8YuOSe6dbBNlD3QbSzjASgIuJevfB9Xi4gKz", {
  api_host: "https://us.i.posthog.com",
});
window.posthog = posthog;

const Highlight = {
  mounted() {
    this.el.style.display = "none";
    this._fn();
    setTimeout(() => {
      this.el.style.display = "";
    }, 100);
  },
  updated() {
    this._fn();
  },
  _fn() {
    window.hljs.highlightAll();
    if (window.hljs.initLineNumbersOnLoad) {
      window.hljs.initLineNumbersOnLoad({
        startFrom: 1,
        singleLine: true,
      });
    }
    if (window.hljs.highlightLinesElement) {
      const lines = JSON.parse(this.el.getAttribute("highlight-lines"));

      window.hljs.highlightLinesElement(
        this.el,
        lines.map(([start, end]) => ({
          start,
          end,
          color: "rgba(255, 255, 255, 0.2)",
        })),
        true,
      );
    }
  },
};

const Tooltip = {
  mounted() {
    this._fn();
  },
  updated() {
    this._fn();
  },
  _fn() {
    const content = this.el.getAttribute("phx-tooltip-content");
    const placement = this.el.getAttribute("phx-tooltip-placement");
    tippy(this.el, { content, placement });
  },
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    ...getHooks(Components),
    Highlight,
    Tooltip
  },
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
