<script lang="ts">
  import { clsx } from "clsx";
  import { onMount } from "svelte";
  import type { Readable } from "svelte/store";

  import { createEditor, Editor, EditorContent } from "svelte-tiptap";

  import { Shared } from "$lib/extensions/shared";
  import { Mention, setCandidates } from "$lib/extensions/mention";
  import { Placeholder } from "@tiptap/extension-placeholder";

  import type { Reference } from "$lib/types";
  import type { Message } from "$lib/interfaces";
  import { turndownService } from "$lib/turndown";
  import { tippy } from "$lib/actions";
  import References from "$components/References.svelte";

  export let placeholder = "Type something...";
  export let paths: string[] = [];

  export let handleSubmit: (message: Message, references: Reference[]) => void;
  export let references: Reference[] = [];
  export let handleResetReferences: () => void;
  export let handleDeleteReference: (index: number) => void;

  $: setCandidates(
    "#",
    Array.from({ length: references.length }, (_, i) => `#${i + 1}`),
  );

  let editor: Readable<Editor>;

  const handleSubmitWrapper = () => {
    const html = $editor.getHTML();
    const md = turndownService.turndown(html);

    if (md === "") {
      return;
    }

    handleSubmit({ role: "user", content: md }, references);
    handleResetReferences();
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
        Mention({ trigger: "/", names: paths, filter: true }),
        Mention({ trigger: "#", names: [], filter: false }),
        Placeholder.configure({
          placeholder,
          emptyEditorClass:
            "text-xs text-gray-500 first:float-left first:h-0 first:pointer-events-none first:before:content-[attr(data-placeholder)]",
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
</script>

<References handleDelete={handleDeleteReference} {references} />
<div
  tabindex="0"
  role="textbox"
  on:keydown={keydownListener}
  class="w-full relative"
>
  <EditorContent editor={$editor} />
  <button
    type="submit"
    use:tippy={{
      content: `<div class="text-xs text-gray-700">Submit</div>`,
    }}
    on:click={handleSubmitWrapper}
    class={clsx([
      "absolute top-2 right-2",
      "w-7 h-7 rounded-xl ml-2",
      "bg-gray-200 hover:bg-gray-300",
      "text-gray-400 hover:text-gray-500 text-md",
    ])}
  >
    ↑
  </button>
</div>
