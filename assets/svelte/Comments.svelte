<script lang="ts">
  import { fly } from "svelte/transition";

  import { clsx } from "clsx";
  import { nanoid } from "nanoid";
  import { Toggle } from "bits-ui";

  import type { Comment } from "$lib/interfaces";

  export let items: Comment[] = [];
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

  const handlePressedChange = (commentId: string) => {
    const newComments = Object.entries(map)
      .map(([_, comments]) =>
        comments.map((comment) =>
          comment.id === commentId
            ? { ...comment, read_only: !comment.read_only }
            : comment,
        ),
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
        <div class="underline">{filePath}</div>
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
            class="flex flex-row gap-2 items-center group"
          >
            <Toggle.Root
              onPressedChange={(_pressed) => handlePressedChange(comment.id)}
            >
              <div
                class="w-[24px] border border-gray-100 rounded-md p-1 text-xs text-gray-600 hover:text-gray-900"
              >
                {#if comment.read_only}
                  <span> R </span>
                {:else}
                  <span> RW </span>
                {/if}
              </div>
            </Toggle.Root>

            <button
              type="button"
              class={clsx([
                "px-1 py-0.5 rounded-md",
                "bg-gray-200 hover:bg-yellow-100",
                "text-sm w-fit text-nowrap",
              ])}
              on:click={() => handleClickComment(comment)}
            >
              L{comment.line_start}-{comment.line_end}
            </button>

            {#if editingComment && editingComment.id === comment.id}
              <!-- svelte-ignore a11y-autofocus -->
              <input
                type="text"
                autofocus={true}
                value={comment.content}
                class={clsx([
                  "py-0.5 px-1 border rounded-md",
                  "border-gray-300 focus:border-gray-300 focus:ring-0",
                  "truncate text-sm",
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
            {/if}

            <button
              on:click={() => handleDeleteComment(comment.id)}
              class="hidden group-hover:flex text-gray-400 hover:text-gray-700"
            >
              <span class="hero-backspace h-4 w-4" />
            </button>
          </div>
        {/each}
      </div>
    </div>
  {/each}

  {#if items.length !== 0}
    <button
      type="button"
      in:fly={{ duration: 300, x: 30 }}
      out:fly={{ duration: 300, x: -30 }}
      on:click={handleClickExecute}
      class={clsx([
        "mt-auto px-4 py-2 rounded-md",
        "bg-gray-800 hover:bg-gray-700 text-white",
      ])}
    >
      Execute plan
    </button>
  {/if}
</div>
