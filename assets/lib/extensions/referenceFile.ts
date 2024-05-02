import { SvelteRenderer } from "svelte-tiptap";
import Mention from "@tiptap/extension-mention";
import { type SuggestionOptions } from "@tiptap/suggestion";

import tippy from "tippy.js";
import Fuse from "fuse.js";

import MentionList from "$components/MentionList.svelte";

export const ReferenceFile = ({
  trigger,
  names,
}: {
  trigger: string;
  names: string[];
}) => {
  return Mention.configure({
    suggestion: suggestion(trigger, names),
    HTMLAttributes: {
      class: "border border-gray-300 rounded-md px-2 py-1 text-sm",
    },
    renderHTML(props) {
      const { node } = props;
      return [
        "a",
        {
          class: "py-1 px-2 text-sm border border-gray-300 rounded-md",
          // href: `https://github.com/${props.node.attrs.id}`,
        },
        node.attrs.id,
      ];
    },
  });
};

const suggestion = (
  trigger: string,
  names: string[],
): Omit<SuggestionOptions, "editor"> => {
  const fuse = new Fuse(names);

  return {
    char: trigger,
    items: ({ query }) => {
      if (!query) {
        return names.slice(0, 20);
      }

      const results = fuse.search(query);
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
                new MentionList({ target, props: { command: props.command } }),
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

          return (renderer.component as MentionList).onKeyDown(props.event);
        },
        onExit() {
          popup[0].destroy();
          renderer.destroy();
        },
      };
    },
  };
};
