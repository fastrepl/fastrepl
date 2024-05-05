<script lang="ts">
  import { clsx } from "clsx";
  import type { Comment } from "$lib/types";

  export let items: Comment[] = [];
  export let handleClickComment: (comment: Comment) => void;
  export let handleUpdateComments: (comments: Comment[]) => void;

  $: map = items.reduce(
    (acc, comment) => {
      acc[comment.file_path] = acc[comment.file_path] || [];
      acc[comment.file_path].push(comment);
      return acc;
    },
    {} as Record<string, Comment[]>,
  );

  const handleDeleteFile = (filePath: string) => {
    handleUpdateComments(items.filter((item) => item.file_path !== filePath));
  };

  const handleDeleteComment = (index: number) => {
    const newComments = items.filter((_, i) => i !== index);
    handleUpdateComments(newComments);
  };
</script>

<div
  class={clsx([
    "flex flex-col gap-4 h-full",
    "border border-gray-200 rounded-lg px-4 py-2",
    "bg-gray-50 text-sm",
  ])}
>
  {#each Object.entries(map) as [filePath, comments]}
    <div class="flex flex-col gap-1">
      <div class="flex flex-row gap-2 items-center text-md group">
        <div class="underline">{filePath}</div>
        <button
          on:click={() => handleDeleteFile(filePath)}
          class="hidden group-hover:block text-gray-400 hover:text-gray-700"
        >
          (X)
        </button>
      </div>
      <div class="pl-4 flex flex-col gap-0.5 text-sm text-gray-700">
        {#each comments as comment, i}
          <div class="flex flex-row gap-2 items-center group">
            <button
              type="button"
              class="px-2 py-1 rounded-md bg-gray-100 hover:bg-gray-200 text-sm"
              on:click={() => handleClickComment(comment)}
            >
              L{comment.line_start}-{comment.line_end}
            </button>
            <div>{comment.content}</div>
            <button
              on:click={() => handleDeleteComment(i)}
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
      class={clsx([
        "mt-auto px-4 py-2 rounded-md",
        "bg-gray-800 hover:bg-gray-700 text-white",
      ])}
    >
      Execute plan
    </button>
  {/if}
</div>
