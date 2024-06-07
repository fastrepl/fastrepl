<script lang="ts">
  import { onMount } from "svelte";
  import { clsx } from "clsx";

  import type { File } from "$lib/interfaces";

  import { EditorView, keymap, lineNumbers } from "@codemirror/view";
  import { EditorState } from "@codemirror/state";

  import {
    unifiedMergeView,
    goToPreviousChunk,
    goToNextChunk,
  } from "@codemirror/merge";
  import { history, historyKeymap, defaultKeymap } from "@codemirror/commands";
  import { tomorrow as theme } from "thememirror";
  import { getLanguage } from "$lib/codemirror/language";

  let element: HTMLDivElement;
  let view: EditorView;

  export let currentFile: File;
  export let originalFile: File;
  export let handleChange: (newFile: File) => void;

  const createEditorState = (currentFile: File, originalFile: File) => {
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
          gutter: false,
          highlightChanges: true,
          syntaxHighlightDeletions: true,
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

  $: view && view.setState(createEditorState(currentFile, originalFile));

  const handleClickPreviousChange = () => {
    goToPreviousChunk({ state: view.state, dispatch: view.dispatch });
  };

  const handleClickNextChange = () => {
    goToNextChunk({ state: view.state, dispatch: view.dispatch });
  };
</script>

<div class="flex flex-col">
  <div
    class={clsx([
      "flex flex-row items-center justify-between",
      "rounded-t-lg py-1 px-2 bg-gray-200",
    ])}
  >
    <span class="text-xs font-semibold">
      {`${currentFile.path} (editing)`}
    </span>

    <div class="flex flex-row items-center gap-2">
      <button
        type="button"
        on:click={handleClickPreviousChange}
        class="hero-chevron-left w-4 h-4 font-semibold text-gray-600 hover:text-black"
      />
      <button
        type="button"
        on:click={handleClickNextChange}
        class="hero-chevron-right w-4 h-4 font-semibold text-gray-600 hover:text-black"
      />
    </div>
  </div>

  <div
    bind:this={element}
    class={clsx([
      "h-[calc(100vh-115px)] overflow-y-auto scrollbar-hide bg-gray-50 relative",
      "text-sm selection:bg-[#fef16033]",
      "border-b border-x border-gray-200 rounded-b-lg",
    ])}
  />
</div>
