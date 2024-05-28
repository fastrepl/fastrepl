<script lang="ts">
  import { fly } from "svelte/transition";
  import { Circle } from "svelte-loading-spinners";

  import { clsx } from "clsx";
  import { Tabs } from "bits-ui";

  import type { Diff, Comment } from "$lib/interfaces";

  import Comments from "$components/Comments.svelte";

  const TABS = ["Controls"];
  let currentTab: (typeof TABS)[number] = TABS[0];

  export let showDiffs = false;
  export let handleToggleShowDiffs: () => void;

  export let diffs: Diff[] = [];
  export let comments: Comment[] = [];
  export let handleClickExecute: () => void;
  export let executing: boolean;

  export let handleClickCreatePR: () => Promise<any>;
  export let handleClickDownloadPatch: () => Promise<any>;

  export let handleClickComment: (comment: Comment) => void;
  export let handleUpdateComments: (comments: Comment[]) => void;

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

<div class="h-[calc(100vh-90px)] border border-gray-200 rounded-lg">
  <Tabs.Root
    value={currentTab}
    onValueChange={(value) => (currentTab = value)}
    class="h-[calc(100vh-115px)]"
  >
    <Tabs.List class={clsx(["flex flex-row gap-0.5", "text-xs bg-gray-200"])}>
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
    </Tabs.List>
    <Tabs.Content value={TABS[0]} class="bg-gray-50 p-4 h-full">
      <div class="flex flex-col gap-2 h-full text-sm">
        <Comments
          items={comments}
          wipPaths={[]}
          {handleClickComment}
          {handleUpdateComments}
        />

        {#if diffs.length > 0 && showDiffs}
          <div
            in:fly={{ duration: 300, x: 30 }}
            out:fly={{ duration: 300, x: -30 }}
            class="flex flex-row items-center justify-center gap-2"
          >
            <button
              type="button"
              disabled={isLoadingCreatePR}
              on:click={wrappedhandleClickCreatePR}
              class={clsx([
                "relative",
                "flex flex-row items-center justify-center gap-2",
                "bg-gray-800 hover:bg-gray-900 text-white",
                "py-1.5 rounded-md w-full",
                "disabled:opacity-70",
              ])}
            >
              <span>Create PR</span>
            </button>
            <button
              type="button"
              disabled={isLoadingDownloadPatch}
              on:click={wrappedhandleClickDownloadPatch}
              class={clsx([
                "flex flex-row items-center justify-center gap-2",
                "bg-gray-800 hover:bg-gray-900 text-white",
                "py-1.5 rounded-md w-full",
                "disabled:opacity-70",
              ])}
            >
              <span>Download Git Patch</span>
            </button>
          </div>
        {/if}

        {#if diffs.length > 0}
          <button
            type="button"
            in:fly={{ duration: 300, x: 30 }}
            out:fly={{ duration: 300, x: -30 }}
            on:click={() => handleToggleShowDiffs()}
            class={clsx([
              "flex flex-row items-center justify-center gap-2",
              "py-1.5 rounded-md",
              "bg-gray-800 hover:bg-gray-900 text-white",
            ])}
          >
            <span>
              {showDiffs ? "Hide changes" : `Show ${diffs.length} changes`}
            </span>
          </button>
        {/if}

        {#if comments.length > 0}
          <button
            type="button"
            disabled={executing}
            in:fly={{ duration: 300, x: 30 }}
            out:fly={{ duration: 300, x: -30 }}
            on:click={handleClickExecute}
            class={clsx([
              "flex flex-row items-center justify-center gap-2",
              "py-1.5 rounded-md",
              "bg-gray-800 hover:bg-gray-900 text-white",
              "disabled:opacity-70",
            ])}
          >
            <span>
              {executing ? "Making changes" : "Make changes"}
            </span>
            {#if executing}
              <Circle size="14" color="white" unit="px" duration="2s" />
            {/if}
          </button>
        {/if}
      </div>
    </Tabs.Content>
  </Tabs.Root>
</div>
