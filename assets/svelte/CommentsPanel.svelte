<script lang="ts">
  import { fly } from "svelte/transition";
  import { Circle } from "svelte-loading-spinners";

  import { clsx } from "clsx";
  import { DropdownMenu } from "bits-ui";

  import type { Diff, Comment } from "$lib/interfaces";

  import CommentList from "$components/CommentList.svelte";

  export let diffs: Diff[] = [];
  export let comments: Comment[] = [];
  export let handleClickExecute: () => void;
  export let executing: boolean;

  export let handleClickComment: (comment: Comment) => void;
  export let handleDeleteComments: (comments: Comment[]) => void;
  export let handleUpdateComments: (comments: Comment[]) => void;
  export let handleClickShareComments: () => Promise<any>;
  export let handleShowDiffsSummary: () => void;

  let isSharingComments = false;

  const wrappedHandleClickShareComments = async () => {
    isSharingComments = true;
    const url = await handleClickShareComments();
    isSharingComments = false;

    window.open(url, "_blank");
  };
</script>

<div class="flex flex-col gap-2 h-full text-sm">
  <div class="h-full overflow-y-hidden hover:overflow-y-auto">
    <CommentList
      items={comments}
      {handleClickComment}
      {handleDeleteComments}
      {handleUpdateComments}
    />
  </div>

  {#if diffs.length > 0}
    <div
      in:fly={{ duration: 300, x: 30 }}
      out:fly={{ duration: 300, x: -30 }}
      class="flex flex-row items-center relative"
    >
      <button
        type="button"
        on:click={handleShowDiffsSummary}
        class={clsx([
          "py-1.5 rounded-md w-full",
          "border border-gray-200 rounded-md",
          "bg-gray-100 hover:bg-gray-200",
        ])}
      >
        Show changes
      </button>
    </div>
  {/if}

  {#if comments.length > 0}
    <div
      class="flex flex-row items-center relative"
      in:fly={{ duration: 300, x: 30 }}
      out:fly={{ duration: 300, x: -30 }}
    >
      <button
        type="button"
        on:click={handleClickExecute}
        class={clsx([
          "flex flex-row items-center justify-center gap-2 w-full",
          "py-1.5 rounded-md",
          "bg-gray-800 hover:bg-gray-900 text-white",
          executing ? "opacity-70" : "",
        ])}
      >
        {#if executing}
          <span>Making changes</span>
        {:else if isSharingComments}
          <span>Sharing comments</span>
        {:else}
          <span>Make changes</span>
        {/if}

        {#if executing || isSharingComments}
          <Circle size="14" color="white" unit="px" duration="2s" />
        {/if}
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
            on:click={wrappedHandleClickShareComments}
            class="hover:bg-gray-700 rounded-sm px-2 py-1"
          >
            Share comments
          </DropdownMenu.Item>
          <DropdownMenu.Separator class="bg-gray-600 w-full h-[1px] my-0.5" />
          <DropdownMenu.Item
            on:click={handleClickExecute}
            class="hover:bg-gray-700 rounded-sm px-2 py-1"
          >
            Make changes
          </DropdownMenu.Item>
        </DropdownMenu.Content>
      </DropdownMenu.Root>
    </div>
  {/if}
</div>
