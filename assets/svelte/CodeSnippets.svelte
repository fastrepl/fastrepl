<script lang="ts">
  import TreeView from "$components/TreeView.svelte";
  import CodeSnippet from "$components/CodeSnippet.svelte";
  import { buildTree } from "$lib/utils/tree";

  type Chunk = {
    file_path: string;
    content: string;
    spans: number[][];
  };

  export let chunks: Chunk[] = [];

  const merged_chunks = Object.values(
    chunks.reduce((acc, chunk) => {
      if (!acc[chunk.file_path]) {
        acc[chunk.file_path] = chunk;
        return acc;
      }

      acc[chunk.file_path].spans.push(...chunk.spans);
      return acc;
    }, []),
  );
  const tree = buildTree(merged_chunks.map((chunk) => chunk.file_path));

  let current_file_path = merged_chunks[0].file_path;
  let current_chunk = merged_chunks[0];
  const handleClickFile = (path: string) => {
    current_file_path = path;
    current_chunk = merged_chunks.find((chunk) => chunk.file_path === path);
  };
</script>

<div class="relative">
  <div class="absolute -left-[240px] -top-30">
    <TreeView items={tree} {handleClickFile} {current_file_path} />
  </div>
  <div class="text-sm h-[calc(100vh-300px)] overflow-y-auto rounded-lg">
    <CodeSnippet chunk={current_chunk} />
  </div>
</div>
