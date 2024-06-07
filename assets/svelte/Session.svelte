<script lang="ts">
  import { clsx } from "clsx";
  import { writable } from "svelte/store";

  import { PaneGroup, Pane, PaneResizer } from "paneforge";
  import { EditorView } from "@codemirror/view";
  import { EditorSelection } from "@codemirror/state";

  import type { Mode } from "$lib/types";
  import type { File, Diff, Comment } from "$lib/interfaces";

  import ActionPanel from "$components/ActionPanel.svelte";
  import FileViewer from "$components/FileViewer.svelte";
  import DiffEditor from "$components/DiffEditor.svelte";
  import DiffsViewer from "$components/DiffsViewer.svelte";
  import FileNavigator from "$components/FileNavigator.svelte";

  export let live: any;
  let view: EditorView | null = null;

  export let repoFullName: string;
  export let paths: string[] = [];
  export let diffs: Diff[] = [];
  export let originalFiles: File[] = [];
  export let currentFiles: File[] = [];
  export let comments: Comment[] = [];
  export let executing: boolean;

  const mode = writable<Mode>("comments");

  let currentFile: File | null = null;

  $: if (!currentFile && originalFiles.length > 0) {
    currentFile = originalFiles[0];
  }

  const handleSelectExistingFile = (path: string) => {
    const nextFile = originalFiles.find((f) => f.path === path);
    if (nextFile) {
      currentFile = nextFile;
    }
  };
  const handleSelectNewFile = (path: string) => {
    live.pushEvent("file:add", { path }, ({ file }) => {
      currentFile = file;
    });
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
    const file = originalFiles.find((f) => f.path === comment.file_path);

    if (file && file.path != currentFile?.path) {
      currentFile = file;
    }

    setTimeout(() => {
      if (view && currentFile) {
        const selection = EditorSelection.range(
          view.state.doc.line(comment.line_start).from,
          view.state.doc.line(comment.line_end).to,
        );

        view.dispatch({
          effects: [
            EditorView.scrollIntoView(selection, { x: "start", y: "center" }),
          ],
        });
      }
    }, 10);
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
      {mode}
      {diffs}
      {comments}
      {executing}
      {currentFile}
      {handleClickExecute}
      {handleClickCreatePR}
      {handleClickComment}
      {handleClickDownloadPatch}
      {handleClickShareComments}
      {handleDeleteComments}
      {handleUpdateComments}
      {handleSelectExistingFile}
    />
  </Pane>
  <PaneResizer class="w-2" />
  <Pane defaultSize={50} order={2} minSize={10} class="relative">
    {#if $mode === "diffs_summary"}
      <DiffsViewer content={diffs.map((d) => d.content).join("\n\n")} />
    {:else if $mode === "diff_edit"}
      <DiffEditor
        currentFile={currentFiles.find((f) => f.path === currentFile.path)}
        originalFile={currentFile}
        handleChange={console.log}
      />
    {:else if currentFile}
      <FileViewer
        on:ready={(e) => (view = e.detail)}
        file={currentFile}
        highlights={comments
          .filter((c) => c.file_path === currentFile?.path)
          .map((c) => ({ start: c.line_start, end: c.line_end }))}
        {handleCreateComments}
      />
    {:else}
      <div
        class={clsx([
          "flex flex-col items-center justify-center h-full",
          "border border-gray-200 rounded-lg",
        ])}
      >
        <div class="text-sm text-gray-500">No file selected.</div>
      </div>
    {/if}
  </Pane>
  <PaneResizer class="w-2" />
  <Pane defaultSize={10} minSize={5} order={3}>
    <FileNavigator
      {paths}
      files={originalFiles}
      {repoFullName}
      currentFilePath={currentFile?.path}
      {handleSelectExistingFile}
      {handleSelectNewFile}
    />
  </Pane>
</PaneGroup>
