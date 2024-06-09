<script lang="ts">
  import { onMount } from "svelte";
  import { fade } from "svelte/transition";

  import { clsx } from "clsx";
  import { Dialog } from "bits-ui";

  import { buildTree } from "$lib/utils/tree";
  import { tippy as tippyAction } from "$lib/actions";

  import TreeView from "$components/TreeView.svelte";
  import SearchFile from "$components/SearchFile.svelte";

  import type { Snapshot, Sender } from "$lib/fsm";

  export let send: Sender;
  export let snapshot: Snapshot;

  export let paths: string[] = [];
  export let repoFullName: string;

  let openFileSearch = false;

  const handleClickFile = (path: string) => {
    openFileSearch = false;
    send({ type: "select_file_from_navigator", path });
  };

  $: tree = buildTree(Array.from($snapshot.context.workingFilePaths));

  onMount(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "p" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        openFileSearch = !openFileSearch;
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  });
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
        paths={paths.filter((p) => !$snapshot.context.workingFilePaths.has(p))}
        {handleClickFile}
      />
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>

<div
  class={clsx([
    "flex flex-col",
    "overflow-x-hidden hover:overflow-x-auto",
    "h-[calc(100vh-90px)] overflow-y-hidden hover:overflow-y-auto",
    "bg-gray-50 rounded-lg",
    "border border-gray-200",
  ])}
>
  <div
    class={clsx([
      "flex flex-row justify-between items-center",
      "bg-gray-200 px-2 mb-2",
    ])}
  >
    <span class="text-xs font-semibold truncate">
      {repoFullName}
    </span>
    <button
      use:tippyAction={{
        content: `<div class="text-xs text-gray-700">cmd + p</div>`,
      }}
      type="button"
      class="text-md text-gray-400 hover:text-gray-800 pl-2"
      on:click={() => (openFileSearch = true)}
    >
      +
    </button>
  </div>

  <div class="pl-2">
    <TreeView
      items={tree}
      {handleClickFile}
      currentFilePath={$snapshot.context.currentFile?.path}
    />
  </div>
</div>
