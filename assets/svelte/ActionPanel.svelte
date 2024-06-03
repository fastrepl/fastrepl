<script lang="ts">
  import { fly } from "svelte/transition";
  import { Circle } from "svelte-loading-spinners";

  import { clsx } from "clsx";
  import { Tabs, DropdownMenu } from "bits-ui";

  import type { Diff, Comment } from "$lib/interfaces";

  import Comments from "$components/Comments.svelte";

  const TABS = ["controls"];
  let currentTab: (typeof TABS)[number] = TABS[0];

  export let showDiffs = false;
  export let handleToggleShowDiffs: () => void;

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

  let isLoadingCreatePR = false;
  let isLoadingDownloadPatch = false;
  let isSharingComments = false;

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

  const wrappedHandleClickShareComments = async () => {
    isSharingComments = true;
    const url = await handleClickShareComments();
    isSharingComments = false;

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
        <div class="h-full overflow-y-hidden hover:overflow-y-auto">
          <Comments
            items={comments}
            wipPaths={[]}
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
              disabled={isLoadingCreatePR || isLoadingDownloadPatch}
              on:click={handleToggleShowDiffs}
              class={clsx([
                "py-1.5 rounded-md w-full",
                "border border-gray-200 rounded-md",
                "bg-gray-100 hover:bg-gray-200",
                "disabled:bg-gray-200",
              ])}
            >
              <span>
                {!showDiffs
                  ? `Show ${diffs.length} changes`
                  : isLoadingCreatePR
                    ? "Creating PR..."
                    : "Hide changes"}
              </span>
            </button>

            {#if showDiffs}
              <DropdownMenu.Root>
                <DropdownMenu.Trigger class="absolute right-1">
                  <button
                    type="button"
                    class={clsx([
                      "text-gray-800 hover:text-black",
                      "px-2 py-1 border-l-[0.5px] border-gray-300",
                    ])}
                  >
                    <span class="hero-chevron-up w-4 h-4" />
                  </button>
                </DropdownMenu.Trigger>
                <DropdownMenu.Content
                  class="z-50 text-sm p-0.5 bg-gray-100 text-black rounded-md border border-gray-300"
                >
                  <DropdownMenu.Item
                    on:click={wrappedhandleClickCreatePR}
                    class="hover:bg-gray-200 rounded-sm px-2 py-1"
                  >
                    Create pull request
                  </DropdownMenu.Item>
                  <DropdownMenu.Separator
                    class="bg-gray-300 w-full h-[1px] my-0.5"
                  />
                  <DropdownMenu.Item
                    on:click={wrappedhandleClickDownloadPatch}
                    class="hover:bg-gray-200 rounded-sm px-2 py-1"
                  >
                    Download patch
                  </DropdownMenu.Item>
                  <DropdownMenu.Separator
                    class="bg-gray-300 w-full h-[1px] my-0.5"
                  />
                  <DropdownMenu.Item
                    class="hover:bg-gray-200 rounded-sm px-2 py-1"
                    on:click={handleToggleShowDiffs}
                  >
                    Hide changes
                  </DropdownMenu.Item>
                </DropdownMenu.Content>
              </DropdownMenu.Root>
            {/if}
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
              <DropdownMenu.Trigger class="absolute right-1">
                <button
                  type="button"
                  class={clsx([
                    "text-gray-200 hover:text-white",
                    "px-2 py-1 border-l-[0.5px] border-gray-500",
                  ])}
                >
                  <span class="hero-chevron-up w-4 h-4" />
                </button>
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
                <DropdownMenu.Separator
                  class="bg-gray-600 w-full h-[1px] my-0.5"
                />
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
    </Tabs.Content>
  </Tabs.Root>
</div>
