import { expect, mock, test } from "bun:test";

type Listener = () => void;

const requests: string[] = [];

mock.module("node:net", () => ({
  default: {
    createConnection() {
      const listeners = new Map<string, Listener>();
      queueMicrotask(() => listeners.get("connect")?.());
      return {
        destroy() {},
        once(event: string, listener: Listener) {
          listeners.set(event, listener);
        },
        write(request: string) {
          requests.push(request);
          queueMicrotask(() => listeners.get("data")?.());
        },
      };
    },
  },
}));

process.env.HERDR_ENV = "1";
process.env.HERDR_SOCKET_PATH = "/tmp/herdr-test.sock";
process.env.HERDR_PANE_ID = "w1:p1";

// The extension captures Herdr's environment at module load.
const extension = await import("./herdr-omp-conversation-title.ts");

async function flush() {
  await Promise.resolve();
  await Promise.resolve();
}

test("reports the initial and renamed OMP session titles", async () => {
  let title = "Initial title";
  let poll: () => void;
  const handlers = new Map<string, (event: unknown, context: unknown) => void>();

  extension.default({
    getSessionName: () => title,
    on(event: string, handler: (event: unknown, context: unknown) => void) {
      handlers.set(event, handler);
    },
  });

  handlers.get("session_start")?.({}, {
    hasUI: true,
    clearTimer() {},
    setTimeout(callback: () => void) {
      callback();
    },
    setInterval(callback: () => void) {
      poll = callback;
      return undefined;
    },
  });
  await flush();

  title = "Renamed title";
  poll!();
  await flush();

  const titles = requests.map((request) => JSON.parse(request).params.title);
  expect(titles).toEqual(["Initial title", "Initial title", "Renamed title"]);
  for (const request of requests) {
    const params = JSON.parse(request).params;
    expect(params).toMatchObject({
      pane_id: "w1:p1",
      source: "user:omp-conversation-title",
      agent: "omp",
      applies_to_source: "herdr:omp",
    });
  }
});
