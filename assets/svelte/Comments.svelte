<script lang="ts">
  import { fly } from "svelte/transition";
  import { Circle } from "svelte-loading-spinners";

  import { clsx } from "clsx";

  import type { Comment } from "$lib/interfaces";

  import Span from "$components/Span.svelte";
  import CommentEditor from "$components/CommentEditor.svelte";

  let searching = false;

  export let items: Comment[] = [];
  export let wipPaths: string[] = [];

  export let handleClickComment: (comment: Comment) => void;
  export let handleUpdateComments: (comments: Comment[]) => void;
  export let handleDeleteComments: (comments: Comment[]) => void;

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
        acc[comment.file_path].push(comment);
        return acc;
      },
      {} as Record<string, Comment[]>,
    );

  const handleDeleteFile = (filePath: string) => {
    const targets = items.filter((item) => item.file_path === filePath);
    handleDeleteComments(targets);
  };

  const handleEditCommentContent = (commentId: number, content: string) => {
    if (!content) {
      return;
    }

    const [target] = items.filter((item) => item.id === commentId);
    if (target) {
      target.content = content;
      handleUpdateComments([target]);
    }
  };
</script>

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
      class="px-2 mt-1 flex flex-col gap-3 text-sm text-gray-700"
    >
      {#each comments as comment (comment.id)}
        <div
          in:fly={{ duration: 300, x: 30 }}
          out:fly={{ duration: 300, x: -30 }}
          class="flex flex-row gap-2 group"
        >
          <button
            type="button"
            on:click={() => handleClickComment(comment)}
            class="h-fit"
          >
            <Span start={comment.line_start} end={comment.line_end} />
          </button>

          <div class="flex flex-row gap-2 w-full relative pr-1">
            <CommentEditor
              content={comment.content}
              handleChangeContent={(content) =>
                handleEditCommentContent(comment.id, content)}
            />
            <button
              on:click={() => handleDeleteComments([comment])}
              class={clsx([
                "absolute -right-2",
                "hidden group-hover:flex",
                "mt-1 text-gray-400 hover:text-gray-700",
              ])}
            >
              <span class="hero-backspace h-4 w-4" />
            </button>
          </div>
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
</div>
