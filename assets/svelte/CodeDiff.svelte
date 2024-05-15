<script lang="ts">
  import { Diff2HtmlUI } from "diff2html/lib/ui/js/diff2html-ui";
  import codeTheme from "svelte-highlight/styles/one-light";

  export let content: string;
  let element: HTMLElement;

  $: if (element && content) {
    const diff2htmlUi = new Diff2HtmlUI(element, content, {
      fileListStartVisible: false,
      fileContentToggle: false,
      drawFileList: false,
      highlight: true,
      outputFormat: "line-by-line",
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
  <style>
    .d2h-file-name {
      font-family: "Lucida Console", monospace;
      /* text-xs */
      font-size: 0.75rem;
      line-height: 1rem;
    }
    .d2h-info {
      display: none;
    }
  </style>
</svelte:head>

<div bind:this={element} />
