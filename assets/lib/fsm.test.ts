import { describe, test, expect } from "vitest";
import { createActor } from "xstate";

import type { Live } from "$lib/interfaces";

import { createMachine } from "./fsm";

const getActorFromLive = (live: Live) => {
  const machine = createMachine({ live });
  return createActor(machine).start();
};

test("click 'show changes' button after 'make changes' is done", async () => {
  const actor = getActorFromLive({
    pushEvent: (event, _, cb) => {},
  });

  expect(actor.getSnapshot().value).toBe("VIEW_COMMENTS");
  expect(actor.getSnapshot().context.tab).toBe("comments");

  actor.send({ type: "show_changes" });

  expect(actor.getSnapshot().value).toBe("VIEW_CHANGES");
  expect(actor.getSnapshot().context.tab).toBe("changes");
});

test("click a comment", async () => {
  const actor = getActorFromLive({
    pushEvent: (event, params, cb) => {
      if (event === "open_file" && params.path === "a.py") {
        cb({ file: { path: "a.py", content: "MOCK_CONTENT" } });
      }
    },
  });

  const comment = {
    id: -1,
    content: "mock",
    file_path: "a.py",
    line_start: 1,
    line_end: 2,
  };

  expect(actor.getSnapshot().value).toBe("VIEW_COMMENTS");
  expect(actor.getSnapshot().context.tab).toBe("comments");
  expect(actor.getSnapshot().context.currentFile).toBeNull();

  actor.send({ type: "click_comment", comment });

  expect(actor.getSnapshot().value).toBe("VIEW_COMMENTS");
  expect(actor.getSnapshot().context.tab).toBe("comments");
  expect(actor.getSnapshot().context.currentFile).toEqual({
    path: "a.py",
    content: "MOCK_CONTENT",
  });
});

describe("select a file from navigator", () => {
  test("when viewing comments", async () => {
    const FILE_A = { path: "a.py", content: "MOCK_CONTENT_A" };
    const FILE_B = { path: "b.py", content: "MOCK_CONTENT_B" };

    const actor = getActorFromLive({
      pushEvent: (event, params, cb) => {
        if (event === "open_file" && params.path === "a.py") {
          cb({ file: FILE_A });
        } else if (event === "open_file" && params.path === "b.py") {
          cb({ file: FILE_B });
        } else if (event === "diffs_fetch") {
          cb({ diffs: [] });
        } else {
          throw new Error(
            `NOT_IMPLEMENTED: event=${event}, params=${JSON.stringify(params)}`,
          );
        }
      },
    });

    expect(actor.getSnapshot().value).toBe("VIEW_COMMENTS");
    expect(actor.getSnapshot().context.tab).toBe("comments");
    expect(actor.getSnapshot().context.currentFile).toBeNull();
    expect(actor.getSnapshot().context.workingFilePaths).toEqual(new Set());

    actor.send({ type: "select_file_from_navigator", path: "a.py" });

    expect(actor.getSnapshot().value).toBe("VIEW_COMMENTS");
    expect(actor.getSnapshot().context.tab).toBe("comments");
    expect(actor.getSnapshot().context.currentFile).toEqual(FILE_A);
    expect(actor.getSnapshot().context.workingFilePaths).toEqual(
      new Set(["a.py"]),
    );

    actor.send({ type: "select_file_from_navigator", path: "a.py" });
    expect(actor.getSnapshot().context.currentFile).toEqual(FILE_A);
    expect(actor.getSnapshot().context.workingFilePaths).toEqual(
      new Set(["a.py"]),
    );

    actor.send({ type: "select_file_from_navigator", path: "b.py" });
    expect(actor.getSnapshot().context.currentFile).toEqual(FILE_B);
    expect(actor.getSnapshot().context.workingFilePaths).toEqual(
      new Set(["a.py", "b.py"]),
    );
  });

  test("when not viewing comments", async () => {
    const FILE_A = { path: "a.py", content: "MOCK_CONTENT_A" };

    const actor = getActorFromLive({
      pushEvent: (event, params, cb) => {
        if (event === "open_file" && params.path === "a.py") {
          cb({ file: FILE_A });
        } else if (event === "diffs_fetch") {
          cb({ diffs: [] });
        } else {
          throw new Error(
            `NOT_IMPLEMENTED: event=${event}, params=${JSON.stringify(params)}`,
          );
        }
      },
    });

    actor.send({ type: "toggle_tab" });
    expect(actor.getSnapshot().value).toBe("VIEW_CHANGES");
    expect(actor.getSnapshot().context.tab).toBe("changes");

    actor.send({ type: "select_file_from_navigator", path: "a.py" });
    expect(actor.getSnapshot().value).toBe("VIEW_COMMENTS");
    expect(actor.getSnapshot().context.tab).toBe("comments");
    expect(actor.getSnapshot().context.currentFile).toEqual(FILE_A);
    expect(actor.getSnapshot().context.workingFilePaths).toEqual(
      new Set(["a.py"]),
    );
  });
});
