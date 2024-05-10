<script lang="ts">
  import { clsx } from "clsx";
  import { DropdownMenu, Dialog } from "bits-ui";
  import { fade } from "svelte/transition";

  import { Diff2HtmlUI } from "diff2html/lib/ui/js/diff2html-ui";
  import codeTheme from "svelte-highlight/styles/one-light";

  export let threadId: string;
  export let unifiedDiff: string;

  let diffElement: HTMLElement;

  $: if (diffElement && unifiedDiff) {
    const diff2htmlUi = new Diff2HtmlUI(diffElement, unifiedDiff, {
      fileListStartVisible: false,
      fileContentToggle: false,
      outputFormat: "side-by-side",
      synchronisedScroll: true,
      highlight: true,
      renderNothingWhenEmpty: false,
      drawFileList: false,
    });

    diff2htmlUi.draw();
    diff2htmlUi.highlightCode();
  }

  let openPrDialog = false;
  let openPatchDialog = false;

  const handleOpenPrDialog = () => {
    openPrDialog = true;
  };

  const handleOpenPatchDialog = () => {
    openPatchDialog = true;
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
        class="w-[400px] h-[300px] bg-gray-100 text-black rounded-md flex flex-col items-center justify-center"
      >
        <a href="/api/patch/{threadId}" class="text-blue-500 underline">
          Download Git Patch
        </a>
      </div>
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>

<svelte:head>
  {@html codeTheme}
  <link
    rel="stylesheet"
    type="text/css"
    href="https://cdn.jsdelivr.net/npm/diff2html/bundles/css/diff2html.min.css"
  />
</svelte:head>

<div
  class="relative mt-6 w-[calc(100vw-4rem)] h-[calc(100vh-170px)] overflow-y-hidden hover:overflow-y-auto"
>
  <div bind:this={diffElement} />
</div>

{#if unifiedDiff}
  <DropdownMenu.Root>
    <div
      class={clsx([
        "absolute right-[32px] top-[110px]",
        "w-[136px] h-[24px] flex flex-row gap-2 justify-center items-center",
        "px-2 py-1",
        "bg-gray-700 hover:bg-gray-800 font-[500] text-white text-xs rounded-md ",
      ])}
    >
      <button on:click={() => handleOpenPatchDialog()}> Download Patch </button>
      <DropdownMenu.Trigger
        class={clsx(["text-gray-200 hover:text-white text-md"])}
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
