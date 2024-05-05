<script lang="ts">
  import { HighlightAuto, LineNumbers } from "svelte-highlight";
  import theme from "svelte-highlight/styles/github-dark";

  type Chunk = {
    file_path: string;
    content: string;
    spans: number[][];
  };

  export let chunk: Chunk;
  export let selection: number[] | null = null;

  let code = "";

  $: {
    code = chunk.content;
    const lines = code.split("\n");

    if (lines.length < 99) {
      code += "\n".repeat(99 - lines.length);
    }
  }

  $: highlightedLines = [
    ...chunk.spans,
    ...(selection ? [selection] : []),
  ].flatMap(([from, to]) =>
    Array.from({ length: to - from + 1 }, (_, i) => from + i - 1),
  );
</script>

<svelte:head>
  {@html theme}
</svelte:head>

<HighlightAuto {code} let:highlighted>
  <LineNumbers
    {highlighted}
    hideBorder
    {highlightedLines}
    startingLineNumber={1}
    class="rounded-b-md"
    --padding-left="0.2em"
    --padding-right="1em"
  />
</HighlightAuto>
