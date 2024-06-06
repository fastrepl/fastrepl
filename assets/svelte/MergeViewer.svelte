<script lang="ts">
  import { onMount } from "svelte";
  import { clsx } from "clsx";

  import type { File } from "$lib/interfaces";

  import { EditorView, keymap, lineNumbers } from "@codemirror/view";
  import { EditorState } from "@codemirror/state";

  import { unifiedMergeView } from "@codemirror/merge";
  import { history, historyKeymap, defaultKeymap } from "@codemirror/commands";
  import { githubLight as theme } from "$lib/codemirror/theme";
  import { getLanguage } from "$lib/codemirror/language";

  let element: HTMLDivElement;
  let view: EditorView;

  export let currentFile: File;
  export let originalFile: File;
  export let handleChange: (newFile: File) => void;

  const createEditorState = () => {
    return EditorState.create({
      doc: currentFile.content,
      extensions: [
        EditorView.updateListener.of((update) => {
          if (update.docChanged) {
            const edited = {
              ...currentFile,
              content: update.state.doc.toString(),
            };
            handleChange(edited);
          }
        }),
        unifiedMergeView({
          original: originalFile.content,
          gutter: true,
          highlightChanges: true,
          syntaxHighlightDeletions: false,
          mergeControls: false,
        }),
        history(),
        keymap.of([...defaultKeymap, ...historyKeymap]),
        theme,
        getLanguage(currentFile.path),
        lineNumbers(),
      ],
    });
  };

  onMount(() => {
    view = new EditorView({ parent: element });
    return () => view.destroy();
  });

  $: view && view.setState(createEditorState());
</script>

<div class="flex flex-col">
  <span class="text-xs rounded-t-lg bg-gray-200 py-1 px-2 font-semibold">
    {currentFile.path}
  </span>

  <div
    bind:this={element}
    class={clsx([
      "h-[calc(100vh-115px)] overflow-y-auto scrollbar-hide bg-gray-50 relative",
      "border-b border-x border-gray-200 rounded-b-lg",
    ])}
  />
</div>
