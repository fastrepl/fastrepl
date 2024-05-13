<script lang="ts">
  import { clsx } from "clsx";
  import { onMount } from "svelte";
  import { fade } from "svelte/transition";
  import tippy, { type Instance as TippyInstance } from "tippy.js";
  import { Tabs, Dialog } from "bits-ui";
  import { PaneGroup, Pane, PaneResizer } from "paneforge";

  import TreeView from "$components/TreeView.svelte";
  import CodeSnippet from "$components/CodeSnippet.svelte";
  import Minimap from "$components/Minimap.svelte";
  import CodeActionList from "$components/CodeActionList.svelte";
  import Comments from "$components/Comments.svelte";
  import ChatEditor from "$components/ChatEditor.svelte";
  import SearchFile from "$components/SearchFile.svelte";
  import Messages from "$components/Messages.svelte";

  import type { Comment, File, Message } from "$lib/interfaces";
  import type { Reference } from "$lib/types";
  import { buildTree } from "$lib/utils/tree";
  import { tippy as tippyAction } from "$lib/actions";

  export let repoFullName: string;
  export let files: File[] = [];
  export let paths: string[] = [];
  export let comments: Comment[] = [];
  export let messages: Message[] = [];

  export let handleSetComments: (comments: Comment[]) => void;
  export let handleClickExecute: () => void;
  export let handleAddFile: (path: string) => void;
  export let handleSubmitChat: (
    message: Message,
    references: Reference[],
  ) => void;

  let references: Reference[] = [];
  const handleResetReferences = () => {
    references = [];
  };
  const handleDeleteReference = (index: number) => {
    references = [
      ...references.slice(0, index),
      ...references.slice(index + 1),
    ];
  };

  const TABS = ["Comments", "Chat"];
  let currentTab: (typeof TABS)[number] = TABS[0];

  let currentFile: File | null = null;

  let selectedLineStart = null;
  let selectedLineEnd = null;

  let codeSnippetContainer: HTMLElement;

  let contextMenuInstance: TippyInstance | null = null;

  $: if (!currentFile && files.length > 0) {
    currentFile = files[0];
  }

  $: tree = buildTree(files.map((f) => f.path));

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

  let openFileSearch = false;
  const handleOpenFileSearch = () => {
    openFileSearch = true;
  };

  const handleSelectFile = (path: string) => {
    openFileSearch = false;
    removeSelection();
    handleAddFile(path);

    setTimeout(() => {
      const file = files.find((f) => f.path === path);
      if (file) {
        currentFile = file;
      }
    }, 500);
  };

  const handleSubmitComment = (content: string) => {
    contextMenuInstance.hide();
    currentTab = TABS[0];

    const newComment: Comment = {
      file_path: currentFile.path,
      line_start: selectedLineStart,
      line_end: selectedLineEnd,
      content: content,
      read_only: false,
    };
    setTimeout(() => {
      comments = [...comments, newComment];
      handleSetComments(comments);
    }, 300);
  };

  const handleSubmitReference = () => {
    contextMenuInstance.hide();
    currentTab = TABS[1];

    references = [
      ...references,
      {
        filePath: currentFile.path,
        lineStart: selectedLineStart,
        lineEnd: selectedLineEnd,
        handleClick: (ref: Reference) => {
          currentFile = files.find((f) => f.path === ref.filePath);

          setTimeout(() => {
            const startLine =
              codeSnippetContainer.getElementsByTagName("tr")[
                ref.lineStart - 1
              ];
            startLine.scrollIntoView({ behavior: "smooth" });

            removeSelection();
            selectedLineStart = ref.lineStart;
            selectedLineEnd = ref.lineEnd;
          }, 300);
        },
      },
    ];
  };

  const handleClickFile = (path: string) => {
    removeSelection();

    const nextFile = files.find((f) => f.path === path);
    if (nextFile) {
      currentFile = nextFile;

      const startLine = codeSnippetContainer.getElementsByTagName("tr")[0];
      startLine.scrollIntoView({ behavior: "smooth" });
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
      codeSnippetContainer.getElementsByTagName("tr")[comment.line_start - 1];

    startLine.scrollIntoView({ behavior: "smooth" });
  };

  const handleUpdateComments = (newComments: Comment[]) => {
    comments = newComments;
    handleSetComments(comments);
  };

  onMount(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        contextMenuInstance.hide();
      }

      if (e.target["contentEditable"] && e.target["tagName"] === "DIV") {
        return;
      }

      if (e.target["tagName"] === "INPUT") {
        return;
      }

      if (e.key === "p" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        openFileSearch = !openFileSearch;
      }

      if (e.key === "a" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();

        document.getSelection().removeAllRanges();
        const range = document.createRange();
        range.selectNode(codeSnippetContainer);
        document.getSelection().addRange(range);

        const trs = codeSnippetContainer.querySelectorAll("tr");

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

  const removeSelection = () => {
    document.getSelection().removeAllRanges();
    selectedLineEnd = null;
    selectedLineStart = null;
  };
</script>

<Dialog.Root bind:open={openFileSearch}>
  <Dialog.Portal>
    <Dialog.Overlay
      transition={fade}
      transitionConfig={{ duration: 150 }}
      class="fixed inset-0 z-50 bg-black/60"
    />
    <Dialog.Content class="fixed left-[50%] top-[10px] z-50 translate-x-[-50%]">
      <SearchFile
        paths={paths.filter((p) => !files.find((f) => f.path === p))}
        {handleSelectFile}
      />
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>

<PaneGroup direction="horizontal">
  <Pane defaultSize={34} minSize={10} order={1}>
    <div class="h-[calc(100vh-170px)] border border-gray-200 rounded-lg">
      <Tabs.Root
        value={currentTab}
        onValueChange={(value) => (currentTab = value)}
        class="h-full"
      >
        <Tabs.List
          class={clsx([
            "border-t border-x border-gray-200 px-1 rounded-t-lg",
            "flex flex-row gap-0.5",
            "text-xs bg-gray-200",
          ])}
        >
          <Tabs.Trigger
            value={TABS[0]}
            class={clsx([
              "data-[state=active]:font-semibold",
              "data-[state=active]:border-b-2 border-b-gray-500",
              "data-[state=inactive]:opacity-40 mx-1.5 py-0.5",
            ])}
          >
            {TABS[0]}
          </Tabs.Trigger>
          <Tabs.Trigger
            value={TABS[1]}
            class={clsx([
              "data-[state=active]:font-semibold",
              "data-[state=active]:border-b-2 border-b-gray-500",
              "data-[state=inactive]:opacity-40 mx-1.5 py-0.5",
            ])}
          >
            {TABS[1]}
          </Tabs.Trigger>
        </Tabs.List>
        <Tabs.Content
          value={TABS[0]}
          class="bg-gray-50 border-b border-gray-200 rounded-b-lg p-4 h-full"
        >
          <Comments
            items={comments}
            {handleClickComment}
            {handleUpdateComments}
            {handleClickExecute}
          />
        </Tabs.Content>
        <Tabs.Content
          value={TABS[1]}
          class={clsx([
            "bg-gray-50 h-full relative",
            "border-b border-gray-200 rounded-b-lg p-4",
          ])}
        >
          <Messages {messages} />
          <div
            class={clsx([
              "w-full px-3",
              "absolute bottom-1 left-0",
              "flex flex-col gap-2",
            ])}
          >
            <ChatEditor
              {paths}
              {references}
              {handleResetReferences}
              {handleDeleteReference}
              handleSubmit={handleSubmitChat}
              placeholder="Ask anything about making changes to the codebase..."
            />
          </div>
        </Tabs.Content>
      </Tabs.Root>
    </div>
  </Pane>
  <PaneResizer class="w-2" />

  {#if files.length === 0}
    <Pane defaultSize={50} minSize={10} order={2}>
      <div
        class={clsx([
          "h-[calc(100vh-150px)]",
          "flex items-center justify-center",
          "bg-gray-50 border border-gray-200 rounded-lg",
        ])}
      >
        <span class="text-sm text-gray-500 font-semibold">
          No file selected.
        </span>
      </div>
    </Pane>
  {:else}
    <Pane defaultSize={50} order={2} minSize={10} class="relative">
      <div class="flex flex-col">
        <span class="text-xs rounded-t-lg bg-gray-200 py-1 px-2">
          {currentFile.path}
        </span>
        <!-- svelte-ignore a11y-no-static-element-interactions -->
        <div
          bind:this={codeSnippetContainer}
          on:mouseup={handleMouseUp}
          on:contextmenu={handleContextMenu}
          class={clsx([
            "h-[calc(100vh-170px)] overflow-y-auto scrollbar-hide",
            "text-sm rounded-b-lg  selection:bg-[#fef16033]",
            "border-b border-x border-gray-200 rounded-b-lg",
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
    </Pane>
  {/if}

  <PaneResizer class="w-2" />
  <Pane defaultSize={10} minSize={5} order={3}>
    <div
      class={clsx([
        "flex flex-col",
        "overflow-x-hidden hover:overflow-x-auto",
        "h-[calc(100vh-150px)] overflow-y-hidden hover:overflow-y-auto",
        "bg-gray-50 rounded-lg",
        "border border-gray-200 px-2 py-1",
      ])}
    >
      <div class="flex flex-row justify-between items-center">
        <span class="text-xs font-semibold truncate">
          {repoFullName}
        </span>
        <button
          use:tippyAction={{
            content: `<div class="text-xs text-gray-700">cmd + p</div>`,
          }}
          type="button"
          class="text-lg text-gray-400 hover:text-gray-800 pl-2"
          on:click={() => handleOpenFileSearch()}
        >
          +
        </button>
      </div>
      <div class="pl-2">
        <TreeView
          items={tree}
          {handleClickFile}
          currentFilePath={currentFile?.path}
        />
      </div>
    </div>
  </Pane>
</PaneGroup>
