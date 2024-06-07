<script lang="ts">
  import { fly } from "svelte/transition";
  import { clsx } from "clsx";

  import type { Comment } from "$lib/interfaces";

  import Span from "$components/Span.svelte";
  import CommentEditor from "$components/CommentEditor.svelte";

  export let items: Comment[] = [];
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

<div class="flex flex-col gap-4">
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
      </div>
    </div>
  {/each}
</div>
