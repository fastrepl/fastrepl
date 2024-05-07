<script lang="ts">
  import { Highlight, LineNumbers } from "svelte-highlight";
  import language from "svelte-highlight/languages/diff";
  import theme from "svelte-highlight/styles/one-light";

  export let content: string;

  let code = "";

  $: {
    code = content;
    const lines = code.split("\n");

    if (lines.length < 99) {
      code += "\n".repeat(99 - lines.length);
    }
  }
</script>

<svelte:head>
  {@html theme}
</svelte:head>

<Highlight {language} {code} let:highlighted>
  <LineNumbers
    {highlighted}
    hideBorder
    startingLineNumber={1}
    class="rounded-b-md"
    --padding-left="0.2em"
    --padding-right="1em"
  />
</Highlight>
