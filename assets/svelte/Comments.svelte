<script lang="ts">
  import { fly } from "svelte/transition";
  import { Circle } from "svelte-loading-spinners";

  import { clsx } from "clsx";
  import { nanoid } from "nanoid";

  import type { Comment } from "$lib/interfaces";

  export let searching = false;
  export let executing = false;

  export let items: Comment[] = [];
  export let wipPaths: string[] = [];
  export let handleClickComment: (comment: Comment) => void;
  export let handleUpdateComments: (comments: Comment[]) => void;
  export let handleClickExecute: () => void;

  $: map = items
    .sort((a, b) => {
      if (a.file_path < b.file_path) return -1;
      if (a.file_path > b.file_path) return 1;
      if (a.line_start < b.line_start) return -1;
      if (a.line_start > b.line_start) return 1;
      return 0;
    })
    .reduce(
      (acc, comment) => {
        acc[comment.file_path] = acc[comment.file_path] || [];
        acc[comment.file_path].push({ id: nanoid(), ...comment });
        return acc;
      },
      {} as Record<string, (Comment & { id: string })[]>,
    );

  let editingComment: (Comment & { id: string }) | null = null;

  $: if (
    editingComment &&
    map[editingComment.file_path].findIndex(
      (c) => c.id === editingComment.id,
    ) === -1
  ) {
    editingComment = null;
  }

  const handleDeleteFile = (filePath: string) => {
    const newComments = items.filter((item) => item.file_path !== filePath);
    handleUpdateComments(newComments);
  };

  const handleDeleteComment = (commentId: string) => {
    const newComments = Object.entries(map)
      .map(([_, comments]) =>
        comments.filter((comment) => comment.id !== commentId),
      )
      .flat();

    handleUpdateComments(newComments);
  };

  const handleEditComment = (commentId: string, content: string) => {
    editingComment = null;

    if (!content) {
      return;
    }

    const newComments = Object.entries(map)
      .map(([_, comments]) =>
        comments.map((comment) =>
          comment.id === commentId ? { ...comment, content } : comment,
        ),
      )
      .flat();

    handleUpdateComments(newComments);
  };
</script>

<div class="flex flex-col gap-4 h-full text-sm relative">
  {#if items.length === 0}
    <span
      in:fly={{ duration: 300, x: 30 }}
      out:fly={{ duration: 300, x: -30 }}
      class="text-sm text-gray-500 font-semibold absolute top-1/2 left-1/2 -translate-y-1/2 -translate-x-1/2"
    >
      No comments yet.
    </span>
  {/if}

  {#each Object.entries(map) as [filePath, comments] (filePath)}
    <div class="flex flex-col gap-1">
      <div
        in:fly={{ duration: 300, x: 30 }}
        out:fly={{ duration: 300, x: -30 }}
        class="flex flex-row gap-2 items-center text-md group"
      >
        <div class="underline truncate">{filePath}</div>
        <button
          on:click={() => handleDeleteFile(filePath)}
          class="hidden group-hover:block text-gray-400 hover:text-gray-700"
        >
          <span class="hero-backspace h-4 w-4" />
        </button>
      </div>
      <div
        in:fly={{ duration: 300, x: 30 }}
        out:fly={{ duration: 300, x: -30 }}
        class="pl-4 mt-1 flex flex-col gap-2 text-sm text-gray-700"
      >
        {#each comments as comment (`${comment.file_path}-${comment.line_start}`)}
          <div
            in:fly={{ duration: 300, x: 30 }}
            out:fly={{ duration: 300, x: -30 }}
            class="flex flex-row gap-2 group"
          >
            <button
              type="button"
              class={clsx([
                "px-1 py-0.5 rounded-md",
                "bg-gray-200 hover:bg-yellow-100",
                "text-sm w-fit h-[24px] text-nowrap",
              ])}
              on:click={() => handleClickComment(comment)}
            >
              L{comment.line_start}-{comment.line_end}
            </button>

            {#if editingComment && editingComment.id === comment.id}
              <!-- svelte-ignore a11y-autofocus -->
              <textarea
                autofocus={true}
                value={comment.content}
                class={clsx([
                  "py-0.5 px-1 border rounded-md w-full",
                  "border-gray-300 focus:border-gray-300 focus:ring-0",
                  "text-sm resize-y",
                ])}
                on:blur={(e) =>
                  handleEditComment(comment.id, e.target["value"])}
                on:keydown={(e) => {
                  if (e.key === "Enter") {
                    console.log(e.target);
                    handleEditComment(comment.id, e.target["value"]);
                  }
                }}
              />
            {:else}
              <button
                type="button"
                on:click={() => (editingComment = comment)}
                class="truncate px-1"
              >
                {comment.content}
              </button>
              <button
                on:click={() => handleDeleteComment(comment.id)}
                class="hidden group-hover:flex text-gray-400 hover:text-gray-700 mt-1"
              >
                <span class="hero-backspace h-4 w-4" />
              </button>
            {/if}
          </div>
        {/each}

        {#if wipPaths.includes(filePath)}
          <div
            class={clsx([
              "flex flex-row gap-2 items-center",
              "px-2 py-1 bg-gray-200 rounded-md",
            ])}
          >
            <Circle size="14" color="#6b7280" unit="px" duration="2s" />
            <span class="text-gray-500">{filePath}</span>
          </div>
        {/if}
      </div>
    </div>
  {/each}

  {#each wipPaths as filePath}
    {#if items.findIndex((item) => item.file_path === filePath) === -1}
      <div
        class={clsx([
          "flex flex-row gap-2 items-center",
          "px-2 py-1 bg-gray-200 rounded-md",
        ])}
      >
        <Circle size="14" color="#6b7280" unit="px" duration="2s" />
        <span class="text-gray-500">{filePath}</span>
      </div>
    {/if}
  {/each}

  <div class="flex flex-col gap-2 mt-auto">
    {#if searching}
      <button
        class={clsx([
          "flex flex-col items-center justify-center",
          "py-1.5 rounded-md",
          "bg-gray-600 hover:bg-gray-800 text-white group",
        ])}
      >
        <div class="flex flex-row gap-2 items-center">
          <span class="group-hover:hidden">Searching new files</span>
          <span class="group-hover:block hidden"> Stop </span>
          <div class="group-hover:hidden">
            <Circle size="14" color="white" unit="px" duration="2s" />
          </div>
        </div>
      </button>
    {/if}

    {#if items.length !== 0}
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
</div>
