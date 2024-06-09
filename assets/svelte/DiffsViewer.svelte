<script lang="ts">
  import { clsx } from "clsx";
  import { Diff2HtmlUI } from "diff2html/lib/ui/js/diff2html-ui";

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
  <link
    rel="stylesheet"
    href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/atom-one-light.min.css"
  />
  <link
    rel="stylesheet"
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
    .d2h-file-diff {
      overflow-x: hidden;
    }
    .d2h-file-diff:hover {
      overflow-x: auto;
    }
  </style>
</svelte:head>

<div class="flex flex-col">
  <span class="text-xs rounded-t-lg bg-gray-200 py-1 px-2 font-semibold">
    summary
  </span>

  <div
    class={clsx([
      "h-[calc(100vh-115px)] overflow-y-auto scrollbar-hide bg-gray-50 relative",
      "border-b border-x border-gray-200 rounded-b-lg",
    ])}
  >
    <div bind:this={element} />
  </div>
</div>
