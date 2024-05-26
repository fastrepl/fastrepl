<script lang="ts">
  import { PaneGroup, Pane, PaneResizer } from "paneforge";

  import type { File, Diff, Comment, Message } from "$lib/interfaces";
  import type { Selection } from "$lib/types";

  import ActionPanel from "$components/ActionPanel.svelte";
  import FileViewer from "$components/FileViewer.svelte";
  import FileNavigator from "$components/FileNavigator.svelte";

  export let live: any;
  export let repoFullName: string;
  export let paths: string[] = [];
  export let diffs: Diff[] = [];
  export let files: File[] = [];
  export let comments: Comment[] = [];
  export let messages: Message[] = [];

  let showDiffs = false;
  let currentDiff: Diff | null = null;
  let currentFile: File | null = null;
  let currentSelection: Selection | null = null;

  $: if (!currentFile && files.length > 0) {
    currentFile = files[0];
  }

  const handleSelectExistingFile = (path: string) => {
    const nextFile = files.find((f) => f.path === path);
    if (nextFile) {
      currentFile = nextFile;
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
  const handleAddComment = (comment: Comment) => {
    live.pushEvent("comment:add", { comment });
  };
</script>

<PaneGroup direction="horizontal">
  <Pane defaultSize={34} minSize={10} order={1}>
    <ActionPanel {paths} {diffs} {comments} {messages} />
  </Pane>
  <PaneResizer class="w-2" />
  <Pane defaultSize={50} order={2} minSize={10} class="relative">
    <FileViewer
      {diffs}
      {showDiffs}
      {currentFile}
      {currentDiff}
      {currentSelection}
      {handleChangeSelection}
      {handleAddComment}
    />
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
