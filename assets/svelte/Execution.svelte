<script lang="ts">
  import { clsx } from "clsx";
  import { Drawer } from "vaul-svelte";
  import { DropdownMenu, Dialog } from "bits-ui";
  import { fade } from "svelte/transition";

  import type { Diff } from "$lib/interfaces";
  import MergeView from "$components/MergeView.svelte";

  export let threadId: string;
  export let diffs: Diff[] = [];

  let openPrDialog = false;
  let openPatchDialog = false;

  const handleOpenPrDialog = () => {
    openPrDialog = true;
  };

  const handleOpenPatchDialog = () => {
    openPatchDialog = true;
  };

  let openDrawer = false;
  let currentDiffContent = "";

  const handleClickDiff = (diff: Diff) => {
    openDrawer = true;
    currentDiffContent = diff.content;
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
      <div
        class="w-[400px] h-[300px] bg-gray-100 text-black rounded-md flex flex-col items-center justify-center"
      >
        <span>Create PR</span>
        <span>(Not implemented yet)</span>
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
      <div
        class="w-[630px] h-[160px] bg-gray-100 text-black rounded-md flex flex-col items-center justify-center"
      >
        <a href="/api/patch/{threadId}" class="text-blue-500 underline">
          Git Patch
        </a>

        <span class="text-sm mt-4"
          >{`curl http://${window.location.host}/api/patch/${threadId} | git apply`}</span
        >
      </div>
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>

<Drawer.Root direction="bottom" bind:open={openDrawer}>
  <Drawer.Portal>
    <Drawer.Overlay class="fixed inset-0 z-50 bg-black/60" />
    <Drawer.Content
      class={clsx([
        "flex flex-col",
        "z-50 fixed bottom-0",
        "w-full h-[70vh]",
        "bg-gray-50 rounded-lg",
      ])}
    >
      <MergeView content={currentDiffContent} />
    </Drawer.Content>
  </Drawer.Portal>
</Drawer.Root>

<div
  class={clsx([
    "mt-12 flex flex-col",
    "h-[calc(100vh-170px)] overflow-y-hidden hover:overflow-y-auto",
  ])}
>
  <div class="flex flex-col gap-0.5 w-[400px] text-gray-700">
    {#each diffs as diff}
      <button
        on:click={() => handleClickDiff(diff)}
        class={clsx([
          "flex flex-row items-center justify-between",
          "px-2 py-0.5 border rounded-md",
          "bg-green-100 hover:bg-green-200",
        ])}
      >
        <span>{diff.path}</span>
        <span class="hero-check-circle w-4 h-4 text-gray-600" />
      </button>
    {/each}
  </div>

  {#if diffs.length > 0}
    <DropdownMenu.Root>
      <div
        class={clsx([
          "flex flex-row gap-2 justify-center items-center",
          "px-1 py-0.5 mt-6",
          "bg-gray-700 hover:bg-gray-800 font-[500] text-white text-sm rounded-md ",
        ])}
      >
        <button on:click={() => handleOpenPatchDialog()}>
          Download Patch
        </button>
        <DropdownMenu.Trigger
          class={clsx(["text-gray-200 hover:text-white text-lg"])}
        >
          +
        </DropdownMenu.Trigger>
      </div>
      <DropdownMenu.Content
        class="z-50 bg-white rounded-md shadow-lg border border-gray-200"
      >
        <DropdownMenu.Item
          on:click={() => handleOpenPatchDialog()}
          class="px-2 py-1 border-b border-gray-200 hover:bg-gray-100 text-xs"
        >
          Download Patch
        </DropdownMenu.Item>
        <DropdownMenu.Item
          on:click={() => handleOpenPrDialog()}
          class="px-2 py-1 hover:bg-gray-100 text-xs"
        >
          Create PR
        </DropdownMenu.Item>
      </DropdownMenu.Content>
    </DropdownMenu.Root>
  {/if}
</div>
