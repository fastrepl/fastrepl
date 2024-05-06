<script lang="ts">
  import { clsx } from "clsx";
  import { onMount } from "svelte";
  import tippy, { type Instance as TippyInstance } from "tippy.js";
  import { Tabs } from "bits-ui";

  import TreeView from "$components/TreeView.svelte";
  import CodeSnippet from "$components/CodeSnippet.svelte";
  import Minimap from "$components/Minimap.svelte";
  import CodeActionList from "$components/CodeActionList.svelte";
  import Comments from "$components/Comments.svelte";

  import type { Comment, File } from "$lib/types";
  import { addRoot, buildTree } from "$lib/utils/tree";

  export let live: any;
  export let root = "repo";

  export let files: File[] = [];
  export let comments: Comment[] = [];

  let currentFile: File | null = null;

  let selectedLineStart = null;
  let selectedLineEnd = null;

  let scrollableElement: HTMLElement;
  let contextMenuInstance: TippyInstance | null = null;

  $: if (!currentFile && files.length > 0) {
    currentFile = files[0];
  }

  $: tree = addRoot(root, buildTree(files.map((f) => f.path)));

  $: {
    const createCodeActionList = (target: Element) => {
      return new CodeActionList({
        target,
        props: { handleSubmit: handleSubmitComment },
      });
    };

    if (scrollableElement && !contextMenuInstance) {
      contextMenuInstance = tippy(scrollableElement, {
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

  const handleSubmitComment = (content: string) => {
    contextMenuInstance.hide();

    setTimeout(() => {
      live.pushEvent("comment:add", {
        file_path: currentFile.path,
        line_start: selectedLineStart,
        line_end: selectedLineEnd,
        content: content,
      });
    }, 300);
  };

  const handleClickFile = (path: string) => {
    document.getSelection().empty();
    selectedLineStart = null;
    selectedLineEnd = null;

    const nextFile = files.find((f) => f.path === path);
    if (nextFile) {
      currentFile = nextFile;
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
        const [nextSelectedLineStart, nextSelectedLineEnd] =
          from > to ? [to, from] : [from, to];

        selectedLineStart = nextSelectedLineStart;
        selectedLineEnd = nextSelectedLineEnd;
      }
    } catch (_) {}
  };

  const handleClickComment = (comment: Comment) => {
    currentFile = files.find((f) => f.path === comment.file_path);

    const startLine =
      scrollableElement.getElementsByTagName("tr")[comment.line_start - 1];

    startLine.scrollIntoView({ behavior: "smooth" });
  };

  const handleUpdateComments = (newComments: Comment[]) => {
    comments = newComments;
    live.pushEvent("comment:replace", { comments });
  };

  const handleClickNext = () => {
    live.pushEvent("move_step", { step: "Execution" });
  };

  onMount(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        contextMenuInstance.hide();
      }

      if (e.target["tagName"] === "INPUT") {
        return;
      }

      if (e.metaKey && e.key === "a") {
        e.preventDefault();

        document.getSelection().removeAllRanges();
        const range = document.createRange();
        range.selectNode(scrollableElement);
        document.getSelection().addRange(range);

        const trs = scrollableElement.querySelectorAll("tr");

        selectedLineStart = Number.parseInt(
          trs[0].firstElementChild.textContent,
        );
        selectedLineEnd = Number.parseInt(
          trs[trs.length - 1].firstElementChild.textContent,
        );
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  });
</script>

<div
  class={clsx([
    "grid grid-cols-8 gap-2",
    "h-[calc(100vh-140px)]",
    "border border-gray-200 rounded-lg p-4",
  ])}
>
  <div
    class="col-span-3 h-[calc(100vh-200px)] border border-gray-200 rounded-lg"
  >
    <Tabs.Root value="Comments" class="h-full">
      <Tabs.List
        class={clsx([
          "border-t border-x border-gray-200 px-1 rounded-t-lg",
          "flex flex-row gap-0.5",
          "text-xs bg-gray-200",
        ])}
      >
        <Tabs.Trigger
          value="Comments"
          class="data-[state=active]:font-semibold data-[state=inactive]:opacity-40 px-1 py-0.5"
        >
          Comments
        </Tabs.Trigger>
        <Tabs.Trigger
          value="Chat"
          class="data-[state=active]:font-semibold data-[state=inactive]:opacity-40 px-1 py-0.5"
        >
          Chat
        </Tabs.Trigger>
      </Tabs.List>
      <Tabs.Content
        value="Comments"
        class="bg-gray-50 border-b border-gray-200 rounded-b-lg px-4 py-2 h-full"
      >
        <Comments
          items={comments}
          {handleClickComment}
          {handleUpdateComments}
          {handleClickNext}
        />
      </Tabs.Content>
      <Tabs.Content
        value="Chat"
        class="bg-gray-50 border-b border-gray-200 rounded-b-lg px-4 py-2 h-full"
      >
        <div>Chat Goes Here</div>
      </Tabs.Content>
    </Tabs.Root>
  </div>

  {#if files.length === 0}
    <div
      class={clsx([
        "col-span-5 h-[calc(100vh-170px)]",
        "flex items-center justify-center",
        "bg-gray-50 border border-gray-200 rounded-lg",
      ])}
    >
      <span class="text-sm text-gray-500 font-semibold"> No files found. </span>
    </div>
  {:else}
    <div class="col-span-4 relative">
      <div class="flex flex-col">
        <span class="text-xs rounded-t-lg bg-gray-200 py-0.5 px-2">
          {currentFile.path}
        </span>
        <!-- svelte-ignore a11y-no-static-element-interactions -->
        <div
          bind:this={scrollableElement}
          on:mouseup={handleMouseUp}
          on:contextmenu={handleContextMenu}
          class={clsx([
            "h-[calc(100vh-190px)] overflow-y-auto scrollbar-hide",
            "text-sm rounded-b-lg  selection:bg-[#fef16033]",
          ])}
        >
          <CodeSnippet
            content={currentFile.content}
            selections={[
              [selectedLineStart, selectedLineEnd],
              ...comments
                .filter(({ file_path }) => file_path === currentFile.path)
                .map((comment) => [comment.line_start, comment.line_end]),
            ]}
          />
        </div>
      </div>

      {#if scrollableElement}
        <div class="absolute right-0 top-7">
          <Minimap root={scrollableElement} />
        </div>
      {/if}
    </div>

    <div
      class={clsx([
        "col-span-1",
        "overflow-x-hidden hover:overflow-x-auto",
        "h-[calc(100vh-170px)] overflow-y-hidden hover:overflow-y-auto",
        "bg-gray-50 rounded-lg",
        "border border-gray-200 px-2 py-1",
      ])}
    >
      <TreeView
        {root}
        items={tree}
        {handleClickFile}
        currentFilePath={currentFile.path}
      />
    </div>
  {/if}
</div>
