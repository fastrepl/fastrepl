<script lang="ts">
  import { Diff2HtmlUI } from "diff2html/lib/ui/js/diff2html-ui";
  import codeTheme from "svelte-highlight/styles/one-light";

  export let unifiedDiff: string;
  let diffElement: HTMLElement;

  $: if (diffElement && unifiedDiff) {
    const diff2htmlUi = new Diff2HtmlUI(diffElement, unifiedDiff, {
      fileListStartVisible: false,
      fileContentToggle: false,
      outputFormat: "side-by-side",
      synchronisedScroll: true,
      highlight: true,
      renderNothingWhenEmpty: false,
      drawFileList: false,
    });

    diff2htmlUi.draw();
    diff2htmlUi.highlightCode();
  }
</script>

<svelte:head>
  {@html codeTheme}
  <link
    rel="stylesheet"
    type="text/css"
    href="https://cdn.jsdelivr.net/npm/diff2html/bundles/css/diff2html.min.css"
  />
</svelte:head>

<div bind:this={diffElement} />
