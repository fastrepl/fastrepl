<script lang="ts">
  import { clsx } from "clsx";

  import TreeView from "$components/TreeView.svelte";
  import CodeSnippet from "$components/CodeSnippet.svelte";
  import Minimap from "$components/Minimap.svelte";
  import SearchEditor from "$components//SearchEditor.svelte";

  import { addRoot, buildTree } from "$lib/utils/tree";

  type Chunk = {
    file_path: string;
    content: string;
    spans: number[][];
  };

  export let root = "repo";
  export let chunks: Chunk[] = [];
  export let paths: string[] = [];

  export let phx_submit = "submit";
  export let input_name = "text";

  let selectedLineStart = null;
  let selectedLineEnd = null;

  let scrollableElement: HTMLElement;

  $: tree = addRoot(root, buildTree(chunks.map((chunk) => chunk.file_path)));
  $: current_file_path = chunks.length > 0 ? chunks[0].file_path : null;
  $: current_chunk = chunks.length > 0 ? chunks[0] : null;

  const handleClickFile = (path: string) => {
    document.getSelection().empty();
    const next_chunk = chunks.find((chunk) => chunk.file_path === path);

    if (next_chunk) {
      current_file_path = path;
      current_chunk = next_chunk;
    }
  };

  const handleSelection = (_: Event) => {
    try {
      const selection = document.getSelection();
      const { startContainer, endContainer } = selection.getRangeAt(0);

      const getLineNumber = (n: Node) => {
        return Number.parseInt(
          n.parentElement.parentElement.parentElement.previousElementSibling
            ?.textContent ?? "0",
        );
      };

      const startLine = getLineNumber(startContainer);
      const endLine = getLineNumber(endContainer);

      if (startLine) {
        selectedLineStart = startLine;
      }
      if (endLine) {
        selectedLineEnd = endLine;
      }
    } catch (_) {}
  };

  const handleMouseLeave = (e: Event) => {
    document.removeEventListener("selectionchange", handleSelection);
  };

  const handleSelectionStart = (e: Event) => {
    document.addEventListener("selectionchange", handleSelection);
  };

  $: if (selectedLineStart && selectedLineEnd) {
  }
</script>

{#if chunks.length === 0}
  <div
    class="h-[calc(100vh-300px)] bg-gray-100 flex items-center justify-center text-gray-800 text-sm"
  >
    No code snippets found.
  </div>
{:else}
  <div class="flex flex-col relative w-[750px]">
    <div
      class={clsx([
        "absolute -left-[300px] -top-30",
        "flex flex-col gap-2",
        "max-h-[calc(100vh-300px)] overflow-y-hidden hover:overflow-y-auto",
      ])}
    >
      <TreeView items={tree} {handleClickFile} {current_file_path} />
      <SearchEditor {paths} {phx_submit} {input_name} />
    </div>
    <span class="text-xs rounded-t-md bg-slate-200 p-0.5 w-full">
      {current_file_path}
    </span>
    <!-- svelte-ignore a11y-no-static-element-interactions -->
    <div
      on:selectstart={handleSelectionStart}
      on:mouseleave={handleMouseLeave}
      bind:this={scrollableElement}
      class="text-sm h-[calc(100vh-300px)] rounded-b-md overflow-y-auto scrollbar-hide selection:bg-blue-800"
    >
      <CodeSnippet chunk={current_chunk} />
    </div>

    {#if scrollableElement}
      <div class="absolute right-0 top-7">
        <Minimap root={scrollableElement} />
      </div>
    {/if}
  </div>
{/if}
