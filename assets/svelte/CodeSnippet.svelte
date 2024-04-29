<script lang="ts">
  import { HighlightAuto, LineNumbers } from "svelte-highlight";
  import theme from "svelte-highlight/styles/github-dark";

  type Chunk = {
    file_path: string;
    content: string;
    spans: number[][];
  };

  export let chunk: Chunk;
  const highlightedLines = chunk.spans.flatMap(([from, to]) =>
    Array.from({ length: to - from + 1 }, (_, i) => from + i - 1),
  );
</script>

<svelte:head>
  {@html theme}
</svelte:head>

<HighlightAuto code={chunk.content} let:highlighted>
  <LineNumbers
    {highlighted}
    hideBorder
    {highlightedLines}
    startingLineNumber={1}
    class="rounded-lg"
    --padding-left="0.2em"
    --padding-right="1em"
  />
</HighlightAuto>
