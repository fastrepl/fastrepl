<script lang="ts">
  import { clsx } from "clsx";
  import { onMount } from "svelte";
  import tippy, { type Instance as TippyInstance } from "tippy.js";

  import TreeView from "$components/TreeView.svelte";
  import CodeSnippet from "$components/CodeSnippet.svelte";
  import Minimap from "$components/Minimap.svelte";
  import SelectableList from "$components/SelectableList.svelte";

  import { addRoot, buildTree } from "$lib/utils/tree";

  type Chunk = {
    file_path: string;
    content: string;
    spans: number[][];
  };

  export let live: any;
  export let root = "repo";
  export let chunks: Chunk[] = [];

  let selectedLineStart = null;
  let selectedLineEnd = null;

  let scrollableElement: HTMLElement;
  let contextMenuInstance: TippyInstance | null = null;

  $: tree = addRoot(root, buildTree(chunks.map((chunk) => chunk.file_path)));
  $: current_file_path = chunks.length > 0 ? chunks[0].file_path : null;
  $: current_chunk = chunks.length > 0 ? chunks[0] : null;
  $: {
    if (scrollableElement && !contextMenuInstance) {
      contextMenuInstance = tippy(scrollableElement, {
        placement: "auto",
        onCreate: (instance) => {
          const target = instance.popper.querySelector(".tippy-content");
          new SelectableList({
            target,
            props: {
              items: Object.keys(contextMenuCommands),
              command: handleSelectCommand,
            },
          });
        },
        trigger: "manual",
        interactive: true,
        appendTo: () => document.body,
      });
    }
  }

  const contextMenuCommands = {
    Comment: () => {
      live.pushEvent("comment", {
        file_path: current_file_path,
        line_start: selectedLineStart,
        line_end: selectedLineEnd,
      });
    },
  };

  const handleSelectCommand = ({ id }: any) => {
    const command = contextMenuCommands[id];
    if (command) {
      command();
    }
    contextMenuInstance.hide();
  };

  const handleClickFile = (path: string) => {
    document.getSelection().empty();
    const next_chunk = chunks.find((chunk) => chunk.file_path === path);

    if (next_chunk) {
      current_file_path = path;
      current_chunk = next_chunk;
    }
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

  const handleSelection = (_: Event) => {
    try {
      const selection = document.getSelection();
      const { startContainer, endContainer } = selection.getRangeAt(0);

      const getLineNumber = (n: Node) => {
        return Number.parseInt(
          n.parentElement.parentElement.parentElement.previousElementSibling
            ?.textContent ?? "0",
        );
      };

      const startLine = getLineNumber(startContainer);
      const endLine = getLineNumber(endContainer);

      if (startLine) {
        selectedLineStart = startLine;
      }
      if (endLine) {
        selectedLineEnd = endLine;
      }
    } catch (_) {}
  };

  const handleMouseLeave = (e: Event) => {
    document.removeEventListener("selectionchange", handleSelection);
  };

  const handleSelectionStart = (e: Event) => {
    document.addEventListener("selectionchange", handleSelection);
  };

  let items = [
    {
      file: "a/b/c.py",
      comments: ["comment 1", "comment 2", "comment 3"],
    },
    {
      file: "b/c/d.py",
      comments: ["comment 4", "comment 5"],
    },
  ];

  const handleRemoveFile = (index: number) => {
    items.splice(index, 1);
    items = items;
  };
  const handleRemoveComment = (index: number) => {
    items[index].comments.splice(index, 1);
    items = items;
  };
</script>

<div
  class="flex flex-row h-[calc(100vh-140px)] border border-gray-200 rounded-xl p-4"
>
  <div class="basis-2/5">
    <div
      class="flex flex-col h-[calc(100vh-170px)] bg-gray-50 rounded-lg gap-4 border border-gray-200 px-4 py-2 text-sm"
    >
      {#each items as item, index}
        <div class="flex flex-col gap-1">
          <div class="flex flex-row gap-2 items-center group">
            <div>📁 {item.file}</div>
            <button
              class="hidden group-hover:block text-gray-400 hover:text-gray-700"
              on:click={() => handleRemoveFile(index)}
            >
              (X)
            </button>
          </div>
          <div class="pl-8 flex flex-col gap-0.5">
            {#each item.comments as comment}
              <div class="flex flex-row gap-2 items-center group">
                <div>{comment}</div>
                <button
                  class="hidden group-hover:block text-gray-400 hover:text-gray-700"
                  on:click={() => handleRemoveComment(index)}
                >
                  (X)
                </button>
              </div>
            {/each}
          </div>
        </div>
      {/each}
    </div>
  </div>

  <div class="h-full w-0.5 bg-gray-100 mx-2"></div>

  <div class="basis-3/5">
    {#if chunks.length === 0}
      <div
        class="bg-gray-100 flex items-center justify-center h-[calc(100vh-170px)]"
      >
        <span class="text-sm text-gray-500 font-semibold">
          No code snippets found.
        </span>
      </div>
    {:else}
      <div class="flex flex-row gap-2">
        <div class="flex flex-col relative">
          <span class="text-xs rounded-t-md bg-slate-200 py-0.5 px-2">
            {current_file_path}
          </span>
          <!-- svelte-ignore a11y-no-static-element-interactions -->
          <div
            bind:this={scrollableElement}
            on:contextmenu={handleContextMenu}
            on:selectstart={handleSelectionStart}
            on:mouseleave={handleMouseLeave}
            class="text-sm rounded-b-md h-[calc(100vh-190px)] overflow-y-auto scrollbar-hide selection:bg-blue-800 max-w-[700px]"
          >
            <CodeSnippet chunk={current_chunk} />
          </div>

          {#if scrollableElement}
            <div class="absolute right-0 top-7">
              <Minimap root={scrollableElement} />
            </div>
          {/if}
        </div>

        <div
          class={clsx([
            "h-[calc(100vh-170px)] overflow-y-hidden hover:overflow-y-auto",
            "bg-gray-50 rounded-lg",
            "border border-gray-200 px-2 py-1",
          ])}
        >
          <TreeView {root} items={tree} {handleClickFile} {current_file_path} />
        </div>
      </div>
    {/if}
  </div>
</div>
