// Keeps Herdr's display-only pane title aligned with OMP's persisted session name.
// The public extension API has no title-change event, so poll the in-process getter.
// @ts-nocheck
import net from "node:net";

const socketPath = process.env.HERDR_SOCKET_PATH;
const socketEndpoint =
  process.platform === "win32" && socketPath ? `\\\\.\\pipe\\${socketPath}` : socketPath;
const paneID = process.env.HERDR_PANE_ID;
const source = "user:omp-conversation-title";
const appliesToSource = "herdr:omp";

function enabled() {
  return process.env.HERDR_ENV === "1" && socketEndpoint && paneID;
}

let sequence = Date.now() * 1000;

function reportTitle(title: string) {
  if (!enabled()) {
    return;
  }

  sequence += 1;
  const socket = net.createConnection(socketEndpoint!);
  const timeout = setTimeout(() => socket.destroy(), 1500);
  timeout.unref?.();
  socket.once("error", () => clearTimeout(timeout));
  socket.once("connect", () => {
    socket.write(
      `${JSON.stringify({
        id: `${source}:${sequence}`,
        method: "pane.report_metadata",
        params: {
          pane_id: paneID,
          source,
          agent: "omp",
          applies_to_source: appliesToSource,
          title,
          seq: sequence,
        },
      })}\n`,
    );
  });
  socket.once("data", () => {
    clearTimeout(timeout);
    socket.destroy();
  });
}

export default function (pi) {
  if (!enabled()) {
    return;
  }

  let pollTimer;

  let reportedTitle: string | undefined;

  function syncTitle(force = false) {
    const title = pi.getSessionName?.()?.trim();
    if (!title || (!force && title === reportedTitle)) {
      return;
    }

    reportedTitle = title;
    reportTitle(title);
  }

  function start(ctx) {
    if (ctx.hasUI !== true) {
      return;
    }

    ctx.clearTimer(pollTimer);
    syncTitle();
    // The bundled Herdr integration claims lifecycle authority during the same
    // startup window. Retry once so the applies_to_source guard cannot race it.
    ctx.setTimeout(() => syncTitle(true), 250);
    pollTimer = ctx.setInterval(syncTitle, 500);
  }

  pi.on("session_start", (_event, ctx) => start(ctx));
  pi.on("session_switch", (_event, ctx) => start(ctx));
}

