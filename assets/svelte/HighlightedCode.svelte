<script lang="ts">
  import { HighlightAuto, LineNumbers } from "svelte-highlight";
  import theme from "svelte-highlight/styles/one-light";

  import type { Selection } from "$lib/types";

  export let content: string;
  export let selections: Selection[] = [];

  let code = "";

  $: {
    code = content;
    const lines = code.split("\n");

    if (lines.length < 99) {
      code += "\n".repeat(99 - lines.length);
    }
  }

  $: highlightedLines = selections.flatMap(({ start, end }) =>
    Array.from({ length: end - start + 1 }, (_, i) => start + i - 1),
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
    --line-number-color="#9ca3af"
  />
</HighlightAuto>
