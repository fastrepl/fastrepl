<script lang="ts">
  import { PaneGroup, Pane, PaneResizer } from "paneforge";

  import type { File, Diff, Comment, Message } from "$lib/interfaces";
  import type { Selection } from "$lib/types";

  import ActionPanel from "$components/ActionPanel.svelte";
  import FileViewer from "$components/FileViewer.svelte";
  import DiffViewer from "$components/DiffViewer.svelte";
  import FileNavigator from "$components/FileNavigator.svelte";

  export let live: any;

  export let repoFullName: string;
  export let paths: string[] = [];
  export let diffs: Diff[] = [];
  export let files: File[] = [];
  export let comments: Comment[] = [];
  export let executing: boolean;

  let showDiffs = false;
  let handleToggleShowDiffs = () => (showDiffs = !showDiffs);

  let currentFile: File | null = null;
  let currentSelection: Selection | null = null;

  $: if (!currentFile && files.length > 0) {
    currentFile = files[0];
  }

  const removeSelection = () => {
    document.getSelection().removeAllRanges();
    currentSelection = null;
  };

  const handleSelectExistingFile = (path: string) => {
    const nextFile = files.find((f) => f.path === path);
    if (nextFile) {
      currentFile = nextFile;
      removeSelection();
    }
  };
  const handleSelectNewFile = (path: string) => {
    live.pushEvent("file:add", { path }, ({ file }) => {
      currentFile = file;
    });
  };

  const handleChangeSelection = (selection: Selection) => {
    currentSelection = selection;
  };

  const handleClickExecute = () => {
    live.pushEvent("execute", {});
  };

  const handleClickCreatePR = () => {
    return new Promise((resolve, reject) => {
      live.pushEvent("pr:create", {}, ({ url }) => {
        resolve(url);
      });
    });
  };

  const handleClickDownloadPatch = () => {
    return new Promise((resolve, reject) => {
      live.pushEvent("patch:download", {}, ({ url }) => {
        resolve(url);
      });
    });
  };

  const handleClickShareComments = () => {
    return new Promise((resolve, reject) => {
      live.pushEvent("comments:share", {}, ({ url }) => {
        resolve(url);
      });
    });
  };

  const handleClickComment = (comment: Comment) => {
    const file = files.find((f) => f.path === comment.file_path);

    if (file) {
      currentFile = file;
      currentSelection = { start: comment.line_start, end: comment.line_end };
    }
  };

  const handleCreateComments = (comments: Comment[]) => {
    live.pushEvent("comments:create", { comments });
  };

  const handleDeleteComments = (comments: Comment[]) => {
    live.pushEvent("comments:delete", { comments });
  };

  const handleUpdateComments = (comments: Comment[]) => {
    live.pushEvent("comments:update", { comments });
  };
</script>

<PaneGroup direction="horizontal">
  <Pane defaultSize={34} minSize={10} order={1}>
    <ActionPanel
      {diffs}
      {showDiffs}
      {handleToggleShowDiffs}
      {comments}
      {handleClickExecute}
      {executing}
      {handleClickCreatePR}
      {handleClickComment}
      {handleClickDownloadPatch}
      {handleClickShareComments}
      {handleDeleteComments}
      {handleUpdateComments}
    />
  </Pane>
  <PaneResizer class="w-2" />
  <Pane defaultSize={50} order={2} minSize={10} class="relative">
    {#if showDiffs}
      <DiffViewer {diffs} />
    {:else if currentFile}
      <FileViewer
        file={currentFile}
        {currentSelection}
        additionalSelections={comments
          .filter((c) => c.file_path === currentFile.path)
          .map((c) => ({ start: c.line_start, end: c.line_end }))}
        {handleChangeSelection}
        {handleCreateComments}
      />
    {:else}
      <div
        class="flex flex-col items-center justify-center h-full border border-gray-200 rounded-lg"
      >
        <div class="text-sm text-gray-500">No file selected.</div>
      </div>
    {/if}
  </Pane>
  <PaneResizer class="w-2" />
  <Pane defaultSize={10} minSize={5} order={3}>
    <FileNavigator
      {paths}
      {files}
      {repoFullName}
      currentFilePath={currentFile?.path}
      {handleSelectExistingFile}
      {handleSelectNewFile}
    />
  </Pane>
</PaneGroup>
