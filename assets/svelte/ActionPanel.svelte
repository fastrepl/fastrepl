<script lang="ts">
  import { clsx } from "clsx";
  import { Tabs } from "bits-ui";

  import CommentsPanel from "$components/CommentsPanel.svelte";
  import ChangesPanel from "$components/ChangesPanel.svelte";

  import type { Diff, Comment } from "$lib/interfaces";

  import type { Mode } from "$lib/types";
  import type { Writable } from "svelte/store";

  export let mode: Writable<Mode>;
  export let diffs: Diff[] = [];
  export let comments: Comment[] = [];
  export let handleClickExecute: () => void;
  export let executing: boolean;

  export let handleClickCreatePR: () => Promise<any>;
  export let handleClickDownloadPatch: () => Promise<any>;
  export let handleClickShareComments: () => Promise<any>;

  export let handleClickComment: (comment: Comment) => void;
  export let handleDeleteComments: (comments: Comment[]) => void;
  export let handleUpdateComments: (comments: Comment[]) => void;
  export let handleSelectExistingFile: (path: string) => void;

  const TABS = ["comments", "changes"];
  let currentTab: (typeof TABS)[number] =
    $mode === "comments" ? TABS[0] : TABS[1];

  $: {
    if (currentTab === TABS[0]) {
      $mode = "comments";
    } else {
      $mode = "diffs_summary";
    }
  }

  const handleShowDiffsSummary = () => {
    currentTab = TABS[1];
  };
</script>

<div class="h-[calc(100vh-90px)] border border-gray-200 rounded-lg">
  <Tabs.Root bind:value={currentTab} class="h-[calc(100vh-115px)]">
    <Tabs.List
      class={clsx(["flex flex-row gap-2 px-1.5 py-0.5", "text-xs bg-gray-200"])}
    >
      {#each TABS as tab}
        <Tabs.Trigger
          value={tab}
          class={clsx([
            "data-[state=active]:font-semibold",
            "data-[state=active]:border-b-2 border-b-gray-500",
            "data-[state=inactive]:opacity-40",
          ])}
        >
          {tab}
        </Tabs.Trigger>
      {/each}
    </Tabs.List>
    <Tabs.Content value={TABS[0]} class="bg-gray-50 p-4 h-full">
      <CommentsPanel
        {diffs}
        {comments}
        {executing}
        {handleClickExecute}
        {handleClickComment}
        {handleDeleteComments}
        {handleUpdateComments}
        {handleClickShareComments}
        {handleShowDiffsSummary}
      />
    </Tabs.Content>
    <Tabs.Content value={TABS[1]} class="bg-gray-50 p-4 h-full">
      <ChangesPanel
        {mode}
        {diffs}
        {handleClickCreatePR}
        {handleClickDownloadPatch}
        {handleSelectExistingFile}
      />
    </Tabs.Content>
  </Tabs.Root>
</div>
