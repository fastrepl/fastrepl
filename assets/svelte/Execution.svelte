<script lang="ts">
  import { clsx } from "clsx";
  import { DropdownMenu, Dialog } from "bits-ui";
  import { fade } from "svelte/transition";

  import CodeDiff from "$components/CodeDiff.svelte";
  import type { Diff } from "$lib/types";

  export let diffs: Diff[] = [];

  let currentFilePath = null;
  $: if (!currentFilePath && diffs.length > 0) {
    currentFilePath = diffs[0].file_path;
  }

  let openPrDialog = false;
  let openPatchDialog = false;

  const handleOpenPrDialog = () => {
    openPrDialog = true;
  };

  const handleOpenPatchDialog = () => {
    openPatchDialog = true;
  };

  let codeDiffContainer: HTMLElement;

  const handleClickFile = (path: string) => {
    currentFilePath = path;

    const startLine = codeDiffContainer.getElementsByTagName("tr")[0];
    startLine.scrollIntoView({ behavior: "smooth" });
  };
</script>

<Dialog.Root bind:open={openPrDialog}>
  <Dialog.Portal>
    <Dialog.Overlay
      transition={fade}
      transitionConfig={{ duration: 150 }}
      class="fixed inset-0 z-50 bg-black/60"
    />
    <Dialog.Content
      class="fixed left-[50%] top-[50%] z-50 translate-x-[-50%] translate-y-[-50%]"
    >
      <div class="text-black w-[400px] h-[300px] bg-gray-100 rounded-md">
        Create PR
      </div>
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>

<Dialog.Root bind:open={openPatchDialog}>
  <Dialog.Portal>
    <Dialog.Overlay
      transition={fade}
      transitionConfig={{ duration: 150 }}
      class="fixed inset-0 z-50 bg-black/60"
    />
    <Dialog.Content
      class="fixed left-[50%] top-[50%] z-50 translate-x-[-50%] translate-y-[-50%]"
    >
      <div class="text-black w-[400px] h-[300px] bg-gray-100 rounded-md">
        Download Patch
      </div>
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>

<div
  class={clsx([
    "w-full grid grid-cols-5 gap-2",
    "border border-gray-200 rounded-lg p-2",
  ])}
>
  <div
    class={clsx([
      "col-span-1 h-[calc(100vh-170px)]",
      "border border-gray-200 rounded-lg py-1 px-2",
      "text-sm bg-gray-50 ",
    ])}
  >
    <DropdownMenu.Root>
      <div
        class={clsx([
          "relative flex flex-row justify-center items-center",
          "px-3 py-1 my-3",
          "w-full bg-gray-800 text-white rounded-md",
        ])}
      >
        <button on:click={() => handleOpenPrDialog()}> Create PR </button>
        <DropdownMenu.Trigger
          class={clsx([
            "absolute right-2",
            "text-lg text-gray-300 hover:text-white",
          ])}
        >
          +
        </DropdownMenu.Trigger>
      </div>
      <DropdownMenu.Content
        class="z-50 text-sm bg-white rounded-md shadow-lg border border-gray-200"
      >
        <DropdownMenu.Item
          on:click={() => handleOpenPatchDialog()}
          class="px-2 py-1 border-b border-gray-200 hover:bg-gray-100"
        >
          Download Patch
        </DropdownMenu.Item>
        <DropdownMenu.Item
          on:click={() => handleOpenPrDialog()}
          class="px-2 py-1 hover:bg-gray-100"
        >
          Create PR
        </DropdownMenu.Item>
      </DropdownMenu.Content>
    </DropdownMenu.Root>

    <div
      class="flex flex-row justify-between items-center mt-1 border-b border-gray-200 py-1"
    >
      <div>Changes</div>
      <div
        class="w-[20px] h-[20px] bg-gray-700 text-gray-100 rounded-full flex justify-center items-center"
      >
        {diffs.length}
      </div>
    </div>

    <ol class="mt-2">
      {#each diffs as diff}
        <li>
          <button
            on:click={() => handleClickFile(diff.file_path)}
            type="button"
            class={clsx([
              "px-2 py-1 w-full rounded-sm text-left truncate",
              diff.file_path === currentFilePath
                ? "bg-gray-200"
                : "bg-gray-50 hover:bg-gray-100",
            ])}
          >
            {diff.file_path.split("/").pop()}
          </button>
        </li>
      {/each}
    </ol>
  </div>

  <div class="col-span-4 border border-gray-200 rounded-lg bg-gray-50">
    {#if currentFilePath}
      {@const diff = diffs.find((diff) => diff.file_path === currentFilePath)}
      <div class="flex flex-col">
        <span class="text-xs rounded-t-lg bg-gray-200 py-0.5 px-2">
          {diff.file_path}
        </span>
        <div
          bind:this={codeDiffContainer}
          class={clsx([
            "h-[calc(100vh-190px)] overflow-y-auto scrollbar-hide",
            "text-sm rounded-b-lg  selection:bg-[#fef16033]",
            "border-b border-x border-gray-200 rounded-b-lg",
          ])}
        >
          <CodeDiff content={diff.content} />
        </div>
      </div>
    {/if}
  </div>
</div>
