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

  const handlePressedChange = (index: number) => {
    const newComments = items.map((comment, i) => {
      if (i === index) {
        return { ...comment, read_only: !comment.read_only };
      }

      return comment;
    });

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
          (X)
        </button>
      </div>
      <div
        in:fly={{ duration: 300, x: 30 }}
        out:fly={{ duration: 300, x: -30 }}
        class="pl-4 mt-1 flex flex-col gap-2 text-sm text-gray-700"
      >
        {#each comments as comment, index (`${comment.file_path}-${comment.line_start}`)}
          <div
            in:fly={{ duration: 300, x: 30 }}
            out:fly={{ duration: 300, x: -30 }}
            class="flex flex-row gap-2 items-center group"
          >
            <Toggle.Root
              onPressedChange={(_pressed) => handlePressedChange(index)}
            >
              <div
                class="w-[24px] border border-gray-100 rounded-md p-1 text-xs text-gray-400 hover:text-gray-600"
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
            <div class="truncate">
              {comment.content}
            </div>
            <button
              on:click={() => handleDeleteComment(comment.id)}
              class="hidden group-hover:block text-gray-400 hover:text-gray-700"
            >
              (X)
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
