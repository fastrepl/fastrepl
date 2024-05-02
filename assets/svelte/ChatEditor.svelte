<script lang="ts">
  import { onDestroy, onMount } from "svelte";
  import type { Readable } from "svelte/store";

  import { createEditor, Editor, EditorContent } from "svelte-tiptap";

  import { Shared } from "$lib/extensions/shared";
  import { Placeholder } from "@tiptap/extension-placeholder";

  import { turndownService } from "$lib/turndown";

  export let live: any;
  export let input_name: string;
  export let phx_submit = "submit";
  export let placeholder = "Type something...";

  let editor: Readable<Editor>;
  let mdContent = "";

  const FORM_ID = "chat-editor-form";

  const keydownListener = (e: KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      const form = document.getElementById(FORM_ID);
      form.dispatchEvent(
        new Event("submit", { bubbles: true, cancelable: true }),
      );
    }
  };

  onMount(() => {
    const form = document.getElementById(FORM_ID);
    form.setAttribute("phx-submit", phx_submit);

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
      onUpdate: (e) => {
        const html = e.editor.getHTML();
        mdContent = turndownService.turndown(html);
      },
      editorProps: {
        attributes: {
          class:
            "w-full border border-gray-300 bg-gray-50 focus:outline-none focus:ring-0 rounded-2xl min-h-[100px] p-4 mb-2 max-h-[420px] overflow-hidden hover:overflow-auto",
        },
      },
    });
    $editor.commands.focus();

    live.handleEvent("tiptap:submit", () => {
      $editor.commands.clearContent();
      $editor.commands.focus();
    });
    live.handleEvent("tiptap:append", ({ content }) => {
      const { size } = $editor.view.state.doc.content;
      $editor.commands.insertContentAt(size, content);
    });
  });

  window.addEventListener("keydown", keydownListener);
  onDestroy(() => {
    window.removeEventListener("keydown", keydownListener);
  });
</script>

<form id={FORM_ID} class="w-[750px]">
  <input type="hidden" name={input_name} value={mdContent} />
  <EditorContent editor={$editor} />
  <button
    type="submit"
    class="w-7 h-7 rounded-xl bg-blue-500 hover:bg-blue-600 bottom-[72px] right-2.5 absolute ml-2 text-white text-md"
  >
    ↑
  </button>
</form>
