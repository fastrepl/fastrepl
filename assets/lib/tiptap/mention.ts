import { SvelteRenderer } from "svelte-tiptap";
import { PluginKey } from "@tiptap/pm/state";
import TiptapMention from "@tiptap/extension-mention";
import { type SuggestionOptions } from "@tiptap/suggestion";

import tippy from "tippy.js";
import Fuse from "fuse.js";

import SelectableList from "$components/SelectableList.svelte";

export const setCandidates = (trigger: string, candidates: string[]) => {
  window[`_fastrepl_mention_${trigger}_candidates`] = candidates;
};

const getCandidates = (trigger: string) => {
  return window[`_fastrepl_mention_${trigger}_candidates`];
};

export const Mention = ({
  trigger,
  names,
  filter,
}: {
  trigger: string;
  names: string[];
  filter: boolean;
}) => {
  return TiptapMention.extend({
    name: `mention-${trigger}`,
  }).configure({
    suggestion: suggestion(trigger, names, filter),
    HTMLAttributes: {
      class: "border border-gray-300 rounded-md px-2 py-1 text-sm",
    },
    renderHTML(props) {
      const { node } = props;
      return [
        "span",
        {
          class: "py-1 px-2 text-sm border border-gray-300 rounded-md",
          "data-file-path": node.attrs.id,
        },
        node.attrs.id,
      ];
    },
  });
};

const suggestion = (
  trigger: string,
  names: string[],
  filter: boolean,
): Omit<SuggestionOptions, "editor"> => {
  return {
    char: trigger,
    pluginKey: new PluginKey(`mention-${trigger}`),
    items: ({ query }) => {
      if (!query) {
        return [];
      }

      const candidates = getCandidates(trigger) ?? names;

      if (!filter) {
        return candidates;
      }

      const fuse = new Fuse(candidates, { threshold: 0.4 });

      const results = fuse.search(query, { limit: 20 });
      return results.map(({ item }) => item);
    },
    render: () => {
      let renderer: SvelteRenderer;
      let popup: any;

      return {
        onStart(props) {
          if (!props.clientRect) {
            return;
          }

          popup = tippy("body", {
            placement: "auto",
            onCreate: (instance) => {
              const target = instance.popper.querySelector(".tippy-content");
              renderer = new SvelteRenderer(
                new SelectableList({
                  target,
                  props: { command: props.command },
                }),
                { element: document.createElement("span") },
              );
            },
            getReferenceClientRect: props.clientRect,
            appendTo: () => document.body,
            showOnCreate: true,
            interactive: true,
            trigger: "manual",
          });
        },
        onUpdate(props) {
          renderer.updateProps(props);
          if (!props.clientRect) {
            return;
          }

          popup[0].setProps({
            getReferenceClientRect: props.clientRect,
          });
        },
        onKeyDown(props) {
          if (props.event.key === "Escape") {
            popup[0].hide();
            return true;
          }

          return (renderer.component as SelectableList).onKeyDown(props.event);
        },
        onExit() {
          popup[0].destroy();
          renderer.destroy();
        },
      };
    },
  };
};
