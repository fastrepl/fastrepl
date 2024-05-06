<script lang="ts">
  import { onDestroy, onMount } from "svelte";
  import type { Readable } from "svelte/store";

  import { createEditor, Editor, EditorContent } from "svelte-tiptap";

  import { Shared } from "$lib/extensions/shared";
  import { Placeholder } from "@tiptap/extension-placeholder";

  import { turndownService } from "$lib/turndown";

  export let placeholder = "Type something...";
  export let handleSubmit: (value: string) => void;

  let editor: Readable<Editor>;

  const handleSubmitWrapper = () => {
    const html = $editor.getHTML();
    const md = turndownService.turndown(html);
    handleSubmit(md);
    $editor.commands.clearContent();
  };

  const keydownListener = (e: KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      handleSubmitWrapper();
    }
  };

  onMount(() => {
    editor = createEditor({
      extensions: [
        ...Shared,
        Placeholder.configure({
          placeholder,
          emptyEditorClass:
            "text-sm text-gray-500 first:float-left first:h-0 first:pointer-events-none first:before:content-[attr(data-placeholder)]",
        }),
      ],
      content: "",
      editorProps: {
        attributes: {
          class:
            "w-full border border-gray-300 bg-gray-50 focus:outline-none focus:ring-0 rounded-2xl min-h-[100px] p-4 mb-2 max-h-[420px] overflow-hidden hover:overflow-auto",
        },
      },
    });

    $editor.commands.focus();
  });

  window.addEventListener("keydown", keydownListener);
  onDestroy(() => {
    window.removeEventListener("keydown", keydownListener);
  });
</script>

<div class="w-full relative">
  <EditorContent editor={$editor} />
  <button
    type="submit"
    on:click={handleSubmitWrapper}
    class="w-7 h-7 rounded-xl bg-blue-600 hover:bg-blue-500 absolute top-2 right-2 ml-2 text-white text-md"
  >
    ↑
  </button>
</div>
