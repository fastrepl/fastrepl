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

  $: merged_chunks = Object.values(
    chunks.reduce((acc, chunk) => {
      if (!acc[chunk.file_path]) {
        acc[chunk.file_path] = chunk;
        return acc;
      }

      acc[chunk.file_path].spans.push(...chunk.spans);
      return acc;
    }, []),
  );
  $: tree = buildTree(merged_chunks.map((chunk) => chunk.file_path));
  $: current_file_path =
    merged_chunks.length > 0 ? merged_chunks[0].file_path : null;
  $: current_chunk = merged_chunks.length > 0 ? merged_chunks[0] : null;

  const handleClickFile = (path: string) => {
    const next_chunk = merged_chunks.find((chunk) => chunk.file_path === path);

    if (next_chunk) {
      current_file_path = path;
      current_chunk = next_chunk;
    }
  };
</script>

{#if merged_chunks.length === 0}
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

    <div
      bind:this={scrollableElement}
      class="text-sm h-[calc(100vh-300px)] overflow-y-auto rounded-lg relative scrollbar-hide"
    >
      <CodeSnippet chunk={current_chunk} />
    </div>

    {#if scrollableElement}
      <div class="absolute right-0 top-0">
        <Minimap root={scrollableElement} />
      </div>
    {/if}
  </div>
{/if}
