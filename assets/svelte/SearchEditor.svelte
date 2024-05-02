<script lang="ts">
  import { clsx } from "clsx";

  import { onDestroy, onMount } from "svelte";
  import type { Readable } from "svelte/store";

  import { createEditor, Editor, EditorContent } from "svelte-tiptap";

  import { Shared } from "$lib/extensions/shared";
  import { ReferenceFile } from "$lib/extensions/referenceFile";

  export let paths: string[];
  export let input_name: string;
  export let phx_submit = "submit";

  let editor: Readable<Editor>;
  let content = "";

  const FORM_ID = "search-editor-form";

  const keydownListener = (e: KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      const form = document.getElementById(FORM_ID);
      form.dispatchEvent(
        new Event("submit", { bubbles: true, cancelable: true }),
      );
      handleSubmit();
    }
  };

  const handleSubmit = () => {
    $editor.commands.clearContent();
    $editor.commands.focus();
  };

  onMount(() => {
    const form = document.getElementById(FORM_ID);
    form.setAttribute("phx-submit", phx_submit);

    editor = createEditor({
      extensions: [...Shared, ReferenceFile({ trigger: "/", names: paths })],
      content: "",
      onUpdate: (e) => {
        content = e.editor.getText();
      },
      editorProps: {
        attributes: {
          class:
            "border border-gray-300 bg-gray-50 focus:outline-none focus:ring-0 rounded-xl px-2 py-0.5",
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

<form id={FORM_ID} class="w-[270px] relative">
  <input type="hidden" name={input_name} value={content} />
  <EditorContent editor={$editor} />
  <button
    type="submit"
    on:click={handleSubmit}
    class={clsx(["absolute right-2 top-1 mr-2", "text-gray-600 text-md"])}
  >
    ↵
  </button>
</form>
