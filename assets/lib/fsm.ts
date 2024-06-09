import { setup, assign } from "xstate";

import type { Live, File, Comment, Diff } from "$lib/interfaces";

type Tab = "comments" | "changes";

export type Context = {
  live: Live;
  tab: Tab;
  originalFile: File | null;
  currentFile: File | null;
  diffs: Diff[];
  workingFilePaths: Set<string>;
};

const schema = setup({
  types: {
    context: {} as Context,
    events: {} as
      | { type: "toggle_tab" }
      | { type: "view_changes" }
      | { type: "show_changes" }
      | { type: "select_file_from_navigator"; path: string }
      | { type: "click_comment"; comment: Comment }
      | { type: "file_updated"; file: File }
      | { type: "file_opened"; file: File }
      | { type: "open_file_for_edit"; path: string }
      | { type: "file_opened_for_edit"; originalFile: File; currentFile: File }
      | { type: "diffs_fetched"; diffs: Diff[] },
  },
  actions: {
    action_update_file: ({ context }, params: { file: File }) => {
      context.live.pushEvent("update_file", params);
    },
    action_open_file: ({ self, context }, params: { path: string }) => {
      context.live.pushEvent("open_file", params, ({ file }) => {
        self.send({ type: "file_opened", file });
      });
    },
    action_open_file_for_edit: (
      { self, context },
      params: { path: string },
    ) => {
      context.live.pushEvent(
        "open_file_for_edit",
        params,
        ({ original_file, current_file }) => {
          self.send({
            type: "file_opened_for_edit",
            originalFile: original_file,
            currentFile: current_file,
          });
        },
      );
    },
    action_fetch_diffs: ({ self, context }, params: { path: string }) => {
      context.live.pushEvent("diffs_fetch", params, ({ diffs }) => {
        self.send({ type: "diffs_fetched", diffs });
      });
    },
  },
});

export const createMachine = (
  init: Required<Pick<Context, "live">> & Partial<Context>,
) => {
  const machine = schema.createMachine({
    context: {
      tab: "comments",
      originalFile: null,
      currentFile: null,
      diffs: [],
      workingFilePaths: new Set(),
      ...init,
    },
    initial: "VIEW_COMMENTS",
    on: {
      diffs_fetched: {
        actions: assign({ diffs: ({ event }) => event.diffs }),
      },
      file_opened: {
        target: ".VIEW_COMMENTS",
        actions: assign({
          currentFile: ({ event }) => event.file,
          workingFilePaths: ({ context, event }) => {
            return context.workingFilePaths.add(event.file.path);
          },
        }),
      },
      file_opened_for_edit: {
        actions: assign({
          originalFile: ({ event }) => event.originalFile,
          currentFile: ({ event }) => event.currentFile,
        }),
      },
    },
    states: {
      VIEW_COMMENTS: {
        entry: [{ type: "action_fetch_diffs" }],
        on: {
          toggle_tab: {
            target: "VIEW_CHANGES",
            actions: assign({ tab: () => "changes" }),
          },
          show_changes: {
            target: "VIEW_CHANGES",
            actions: assign({ tab: () => "changes" }),
          },
          click_comment: {
            actions: {
              type: "action_open_file",
              params: ({ event }) => ({ path: event.comment.file_path }),
            },
          },
          select_file_from_navigator: {
            actions: [
              {
                type: "action_open_file",
                params: ({ event }) => ({ path: event.path }),
              },
            ],
          },
        },
      },
      VIEW_CHANGES: {
        entry: [{ type: "action_fetch_diffs" }],
        on: {
          toggle_tab: {
            target: "VIEW_COMMENTS",
            actions: assign({ tab: () => "comments" }),
          },
          select_file_from_navigator: {
            target: "VIEW_COMMENTS",
            actions: [
              {
                type: "action_open_file",
                params: ({ event }) => ({ path: event.path }),
              },
              assign({ tab: () => "comments" }),
            ],
          },
          open_file_for_edit: {
            target: "EDIT_CHANGE",
            actions: [
              {
                type: "action_open_file_for_edit",
                params: ({ event }) => ({ path: event.path }),
              },
            ],
          },
        },
      },
      EDIT_CHANGE: {
        on: {
          toggle_tab: {
            target: "VIEW_COMMENTS",
            actions: assign({ tab: () => "comments" }),
          },
          view_changes: {
            target: "VIEW_CHANGES",
          },
          file_updated: {
            actions: [
              {
                type: "action_update_file",
                params: ({ event }) => ({ file: event.file }),
              },
            ],
          },
          select_file_from_navigator: {
            target: "VIEW_COMMENTS",
            actions: [
              {
                type: "action_open_file",
                params: ({ event }) => ({ path: event.path }),
              },
              assign({ tab: () => "comments" }),
            ],
          },
          open_file_for_edit: {
            actions: [
              {
                type: "action_open_file_for_edit",
                params: ({ event }) => ({ path: event.path }),
              },
            ],
          },
        },
      },
    },
    output: ({ self }) => {
      const {
        value: mode,
        context: { live, ...rest },
      } = self.getSnapshot();

      return { ...rest, mode };
    },
  });

  return machine;
};

import { useMachine } from "@xstate/svelte";

export type Machine = ReturnType<typeof createMachine>;
export type Snapshot = ReturnType<typeof useMachine<Machine>>["snapshot"];
export type Sender = ReturnType<typeof useMachine<Machine>>["send"];
