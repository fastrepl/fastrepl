<script lang="ts">
  import { onDestroy, onMount } from "svelte";
  import type { Readable } from "svelte/store";

  import { createEditor, Editor, EditorContent } from "svelte-tiptap";

  import { Shared } from "$lib/extensions/shared";
  import { Placeholder } from "@tiptap/extension-placeholder";

  import { turndownService } from "$lib/turndown";

  export let live: any;
  export let input_name: string;
  export let placeholder = "Type something...";

  let editor: Readable<Editor>;

  const keydownListener = (e: KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      const [form] = document.getElementsByTagName("form");
      form.dispatchEvent(
        new Event("submit", { bubbles: true, cancelable: true }),
      );
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
      onUpdate: (e) => {
        const html = e.editor.getHTML();
        const md = turndownService.turndown(html);

        const inputs = document.querySelectorAll("input[type=hidden]");
        if (inputs.length > 0) {
          const input = inputs[0] as HTMLInputElement;
          input.value = md;
        } else {
          const input = document.createElement("input");
          input.type = "hidden";
          input.name = input_name;
          const [form] = document.getElementsByTagName("form");
          form.appendChild(input);
          input.value = md;
        }
      },
      editorProps: {
        attributes: {
          class:
            "w-full border border-gray-300 bg-gray-50 focus:outline-none focus:ring-0 rounded-2xl min-h-[100px] p-4 mb-2 max-h-[420px] overflow-hidden hover:overflow-auto",
        },
      },
    });

    $editor.commands.focus();

    window.addEventListener("keydown", keydownListener);

    live.handleEvent("tiptap:submit", () => {
      $editor.commands.clearContent();
      $editor.commands.focus();
    });

    live.handleEvent("tiptap:append", ({ content }) => {
      const { size } = $editor.view.state.doc.content;
      $editor.commands.insertContentAt(size, content);
    });
  });

  onDestroy(() => {
    window.removeEventListener("keydown", keydownListener);
  });
</script>

<div class="w-[750px]">
  <EditorContent editor={$editor} />
</div>
