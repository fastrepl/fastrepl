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

  const handleMouseUp = (_e: MouseEvent) => {
    const selection = document.getSelection();

    const getLineNumber = (n: Node) => {
      try {
        const tr = n.parentElement.closest("tr");
        const [td, _] = tr.querySelectorAll("td");
        const left = td.querySelector("div.line-num1").textContent;
        const right = td.querySelector("div.line-num2").textContent;
        return [left, right];
      } catch (_) {
        return null;
      }
    };

    const _ = [
      getLineNumber(selection.anchorNode),
      getLineNumber(selection.focusNode),
    ];
  };
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

<!-- svelte-ignore a11y-no-static-element-interactions -->
<div bind:this={element} on:mouseup={handleMouseUp} />
