<script lang="ts">
  import { clsx } from "clsx";
  import { DropdownMenu } from "bits-ui";

  import type { Mode } from "$lib/types";
  import type { Diff, File } from "$lib/interfaces";
  import type { Writable } from "svelte/store";

  export let mode: Writable<Mode>;
  export let currentFile: File | null = null;
  export let handleClickCreatePR: () => Promise<any>;
  export let handleClickDownloadPatch: () => Promise<any>;
  export let handleSelectExistingFile: (path: string) => void;

  export let diffs: Diff[] = [];

  const handleClickDiff = (diff: Diff) => {
    handleSelectExistingFile(diff.path);
    $mode = "diff_edit";
  };

  let isLoadingCreatePR = false;
  let isLoadingDownloadPatch = false;

  const wrappedhandleClickCreatePR = async () => {
    isLoadingCreatePR = true;
    const url = await handleClickCreatePR();
    isLoadingCreatePR = false;

    window.open(url, "_blank");
  };

  const wrappedhandleClickDownloadPatch = async () => {
    isLoadingDownloadPatch = true;
    const url = await handleClickDownloadPatch();
    isLoadingDownloadPatch = false;

    window.open(url, "_blank");
  };
</script>

<div class="flex flex-col gap-2 h-full text-sm">
  <div class="h-full overflow-y-hidden hover:overflow-y-auto">
    <div class="flex flex-col gap-2">
      {#each diffs as diff}
        <button
          on:click={() => handleClickDiff(diff)}
          class={clsx([
            "w-full flex flex-row justify-between gap-2",
            "px-2 py-1 border border-gray-200 rounded-md",
            "bg-gray-100 hover:bg-gray-200",
            $mode === "diff_edit" &&
              currentFile?.path === diff.path &&
              "bg-gray-200",
          ])}
        >
          <span class="truncate">
            {diff.path}
          </span>
          <span class="text-yellow-700 opacity-50">M</span>
        </button>
      {/each}
    </div>
  </div>

  {#if $mode !== "diffs_summary"}
    <button
      type="button"
      on:click={() => {
        $mode = "diffs_summary";
      }}
      class={clsx([
        "py-1.5 rounded-md w-full",
        "border border-gray-300 rounded-md",
        "bg-gray-200 hover:bg-gray-300",
      ])}
    >
      Show changes summary
    </button>
  {/if}

  <div class="flex flex-row items-center relative">
    <button
      type="button"
      on:click={wrappedhandleClickCreatePR}
      class={clsx([
        "flex flex-row items-center justify-center gap-2 w-full",
        "py-1.5 rounded-md",
        "bg-gray-800 hover:bg-gray-900 text-white",
      ])}
    >
      <span>
        {isLoadingCreatePR
          ? "Creating pull request..."
          : isLoadingDownloadPatch
            ? "Downloading patch..."
            : "Create pull request"}
      </span>
    </button>

    <DropdownMenu.Root>
      <DropdownMenu.Trigger
        class={clsx([
          "absolute right-1",
          "text-gray-200 hover:text-white",
          "px-2 py-1 border-l-[0.5px] border-gray-500",
        ])}
      >
        <span class="hero-chevron-up w-4 h-4" />
      </DropdownMenu.Trigger>
      <DropdownMenu.Content
        class="z-50 text-sm p-0.5 bg-gray-800 text-white rounded-md border border-gray-400"
      >
        <DropdownMenu.Item
          on:click={wrappedhandleClickDownloadPatch}
          class="hover:bg-gray-700 rounded-sm px-2 py-1"
        >
          Download patch
        </DropdownMenu.Item>
        <DropdownMenu.Separator class="bg-gray-600 w-full h-[1px] my-0.5" />

        <DropdownMenu.Item
          on:click={wrappedhandleClickCreatePR}
          class="hover:bg-gray-700 rounded-sm px-2 py-1"
        >
          Create pull request
        </DropdownMenu.Item>
      </DropdownMenu.Content>
    </DropdownMenu.Root>
  </div>
</div>
