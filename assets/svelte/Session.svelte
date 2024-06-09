<script lang="ts">
  import { clsx } from "clsx";

  import { PaneGroup, Pane, PaneResizer } from "paneforge";
  import { EditorView } from "@codemirror/view";
  import { EditorSelection } from "@codemirror/state";

  import ActionPanel from "$components/ActionPanel.svelte";
  import FileViewer from "$components/FileViewer.svelte";
  import DiffEditor from "$components/DiffEditor.svelte";
  import DiffsViewer from "$components/DiffsViewer.svelte";
  import FileNavigator from "$components/FileNavigator.svelte";

  import type { Live, Diff, Comment } from "$lib/interfaces";
  import { createMachine } from "$lib/fsm";
  import { useMachine } from "@xstate/svelte";

  export let live: Live;
  let view: EditorView | null = null;
  const { snapshot, send } = useMachine(createMachine({ live }));

  export let repoFullName: string;
  export let paths: string[] = [];
  export let comments: Comment[] = [];
  export let executing: boolean;

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
    send({ type: "click_comment", comment });

    setTimeout(() => {
      if (view) {
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
      {send}
      {snapshot}
      {comments}
      {executing}
      {handleClickExecute}
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
    {#if $snapshot.value === "VIEW_CHANGES"}
      <DiffsViewer
        content={$snapshot.context.diffs.map((d) => d.content).join("\n\n")}
      />
    {:else if $snapshot.value === "EDIT_CHANGE"}
      <DiffEditor
        currentFile={$snapshot.context.currentFile}
        originalFile={$snapshot.context.originalFile}
        handleChange={(file) => send({ type: "file_updated", file })}
      />
    {:else if $snapshot.context.currentFile}
      <FileViewer
        on:ready={(e) => (view = e.detail)}
        file={$snapshot.context.currentFile}
        highlights={comments
          .filter((c) => c.file_path === $snapshot.context.currentFile?.path)
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
    <FileNavigator {send} {snapshot} {repoFullName} {paths} />
  </Pane>
</PaneGroup>
