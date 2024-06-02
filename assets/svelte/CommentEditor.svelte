<script lang="ts">
  import { onMount } from "svelte";
  import type { Readable } from "svelte/store";

  import { Extension } from "@tiptap/core";
  import StarterKit from "@tiptap/starter-kit";
  import { createEditor, Editor, EditorContent } from "svelte-tiptap";

  let editor: Readable<Editor>;

  export let content = "";
  export let handleChangeContent: (content: string) => void;

  onMount(() => {
    editor = createEditor({
      extensions: [
        StarterKit,
        Extension.create({
          addKeyboardShortcuts() {
            return {
              Enter: () => {
                $editor.commands.blur();
                $editor.setEditable(false);
                return true;
              },
            };
          },
        }),
      ],
      content: content,
      onFocus: ({ editor }) => {
        editor.setEditable(true);
      },
      onBlur: ({ editor }) => {
        handleChangeContent(editor.getText());
        editor.setEditable(false);
      },
      editorProps: {
        attributes: {
          class:
            "focus:outline-none focus:ring-1 ring-gray-300 rounded-md px-1 py-0.5",
        },
      },
    });
  });
</script>

<div class="tiptap w-full">
  <EditorContent editor={$editor} />
</div>
