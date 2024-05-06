<script lang="ts">
  import { HighlightAuto, LineNumbers } from "svelte-highlight";
  import theme from "svelte-highlight/styles/one-light";

  export let content: string;
  export let selections: number[][] = [];

  let code = "";

  $: {
    code = content;
    const lines = code.split("\n");

    if (lines.length < 99) {
      code += "\n".repeat(99 - lines.length);
    }
  }

  $: highlightedLines = selections.flatMap(([from, to]) =>
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
