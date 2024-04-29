<script lang="ts">
  import TreeView from "$components/TreeView.svelte";
  import CodeSnippet from "$components/CodeSnippet.svelte";
  import Minimap from "$components/Minimap.svelte";
  import { buildTree } from "$lib/utils/tree";

  type Chunk = {
    file_path: string;
    content: string;
    spans: number[][];
  };

  export let chunks: Chunk[] = [];
  let scrollableElement: HTMLElement;

  $: tree = buildTree(chunks.map((chunk) => chunk.file_path));
  $: current_file_path = chunks.length > 0 ? chunks[0].file_path : null;
  $: current_chunk = chunks.length > 0 ? chunks[0] : null;

  const handleClickFile = (path: string) => {
    const next_chunk = chunks.find((chunk) => chunk.file_path === path);

    if (next_chunk) {
      current_file_path = path;
      current_chunk = next_chunk;
    }
  };
</script>

{#if chunks.length === 0}
  <div
    class="h-[calc(100vh-300px)] bg-gray-500 flex items-center justify-center text-gray-200 text-sm"
  >
    No code snippets found
  </div>
{:else}
  <div class="relative">
    <div class="absolute -left-[240px] -top-30">
      <TreeView items={tree} {handleClickFile} {current_file_path} />
    </div>

    <div class="flex flex-col">
      <span class="text-xs rounded-t-md bg-slate-200 p-0.5 w-full">
        {current_file_path}
      </span>
      <div
        bind:this={scrollableElement}
        class="text-sm h-[calc(100vh-300px)] overflow-y-auto rounded-b-md relative scrollbar-hide"
      >
        <CodeSnippet chunk={current_chunk} />
      </div>
    </div>

    {#if scrollableElement}
      <div class="absolute right-0 top-7">
        <Minimap root={scrollableElement} />
      </div>
    {/if}
  </div>
{/if}
