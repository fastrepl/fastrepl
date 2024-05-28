<script lang="ts">
  import { onMount } from "svelte";

  import { clsx } from "clsx";
  import tippy, { type Instance as TippyInstance } from "tippy.js";

  import type { File, Comment } from "$lib/interfaces";
  import type { Selection } from "$lib/types";

  import Minimap from "$components/Minimap.svelte";
  import HighlightedCode from "$components/HighlightedCode.svelte";
  import CodeActionList from "$components/CodeActionList.svelte";

  export let file: File;
  export let currentSelection: Selection | null = null;
  export let handleChangeSelection: (s: Selection) => void;
  export let handleAddComment: (c: Comment) => void;

  let codeSnippetContainer: HTMLElement;
  let contextMenuInstance: TippyInstance | null = null;

  $: {
    const createCodeActionList = (target: Element) => {
      return new CodeActionList({
        target,
        props: { handleSubmitComment, handleSubmitReference },
      });
    };

    if (codeSnippetContainer && !contextMenuInstance) {
      contextMenuInstance = tippy(codeSnippetContainer, {
        placement: "auto",
        onCreate: (instance) => {
          const target = instance.popper.querySelector(".tippy-content");
          createCodeActionList(target);
        },
        onHidden: (instance) => {
          const target = instance.popper.querySelector(".tippy-content");
          target.firstChild.remove();
          createCodeActionList(target);
        },
        trigger: "manual",
        allowHTML: true,
        interactive: true,
        appendTo: () => document.body,
      });
    }
  }

  const handleSubmitReference = () => {
    contextMenuInstance.hide();
    alert("TODO");
  };

  const handleSubmitComment = (content: string) => {
    contextMenuInstance.hide();

    const newComment: Comment = {
      file_path: file.path,
      line_start: currentSelection.start,
      line_end: currentSelection.end,
      content: content,
    };

    handleAddComment(newComment);
  };

  const handleContextMenu = (e: MouseEvent) => {
    e.preventDefault();

    contextMenuInstance.setProps({
      getReferenceClientRect: () =>
        ({
          width: 0,
          height: 0,
          top: e.clientY,
          bottom: e.clientY,
          left: e.clientX,
          right: e.clientX,
        }) as DOMRect,
    });

    contextMenuInstance.show();
  };

  const handleMouseUp = (_: Event) => {
    try {
      const selection = document.getSelection();

      const getLineNumber = (n: Node) => {
        return Number.parseInt(
          n.parentElement.closest("td").previousElementSibling?.textContent ??
            "0",
        );
      };

      const [from, to] = [
        getLineNumber(selection.anchorNode),
        getLineNumber(selection.focusNode),
      ];

      if (from && to) {
        const nextSelection =
          from > to ? { start: to, end: from } : { start: from, end: to };
        handleChangeSelection(nextSelection);
      }
    } catch (_) {}
  };

  onMount(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        contextMenuInstance.hide();
      }

      if (e.target["contentEditable"] && e.target["tagName"] === "DIV") {
        return;
      }

      if (e.target["contentEditable"] && e.target["tagName"] === "TEXTAREA") {
        return;
      }

      if (e.target["tagName"] === "INPUT") {
        return;
      }

      if (e.key === "a" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();

        document.getSelection().removeAllRanges();
        const range = document.createRange();
        range.selectNode(codeSnippetContainer);
        document.getSelection().addRange(range);

        const trs = codeSnippetContainer.querySelectorAll("tr");

        const nextSelection = {
          start: Number.parseInt(trs[0].firstElementChild.textContent),
          end: Number.parseInt(
            trs[trs.length - 1].firstElementChild.textContent,
          ),
        };

        handleChangeSelection(nextSelection);
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  });
</script>

<div class="flex flex-col">
  <span class="text-xs rounded-t-lg bg-gray-200 py-1 px-2 font-semibold">
    {file.path}
  </span>

  <!-- svelte-ignore a11y-no-static-element-interactions -->
  <div
    bind:this={codeSnippetContainer}
    on:mouseup={handleMouseUp}
    on:contextmenu={handleContextMenu}
    class={clsx([
      "h-[calc(100vh-115px)] overflow-y-auto scrollbar-hide",
      "text-sm selection:bg-[#fef16033]",
      "border-b border-x border-gray-200 rounded-b-lg",
    ])}
  >
    <HighlightedCode
      code={file.content}
      selections={[currentSelection].filter(Boolean)}
    />
  </div>
</div>

{#if codeSnippetContainer}
  <div class="absolute right-0 top-7">
    <Minimap
      root={codeSnippetContainer}
      config={{
        "line-background": { alpha: 0.8, fillStyle: "rgb(253 224 71)" },
      }}
    />
  </div>
{/if}
