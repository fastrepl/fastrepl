<script lang="ts">
  import type { Comment, Diff, File, Message } from "$lib/interfaces";
  import type { Reference } from "$lib/types";

  import Initialization from "$components/Initialization.svelte";
  import Planning from "$components/Planning.svelte";

  export let live: any;
  export let steps: string[] = [];
  export let currentStep: (typeof steps)[number];
  export let searching: boolean;

  export let repoFullName: string;
  export let repoDescription: string;
  export let repoSha: string;
  export let issueTitle: string;
  export let issueNumber: number;
  export let indexingTotal: number;
  export let indexingProgress: number;

  export let files: File[] = [];
  export let paths: string[] = [];
  export let wipPaths: string[] = [];
  export let comments: Comment[];
  export let messages: Message[] = [];

  const handleClickContinue = () => {
    const currentIndex = steps.indexOf(currentStep);
    const nextIndex = currentIndex + 1;

    if (nextIndex < steps.length) {
      currentStep = steps[nextIndex];
      live.pushEvent("step:set", { step: currentStep });
    }
  };

  const handleDoneInitialization = () => {};

  const handleClickExecute = () => {
    live.pushEvent("execute", {});
  };

  const handleSetComments = (comments: Comment[]) => {
    live.pushEvent("comment:set", { comments });
  };

  const handleAddFile = (path: string) => {
    live.pushEvent("file:add", { path });
  };

  const handleSubmitChat = (message: Message, references: Reference[]) => {
    live.pushEvent("chat:submit", { message, references });
  };
</script>

<div class="flex flex-col gap-2 items-center">
  {#if currentStep === steps[0]}
    <Initialization
      {repoFullName}
      {repoDescription}
      {repoSha}
      {issueTitle}
      {issueNumber}
      {indexingTotal}
      {indexingProgress}
      {handleClickContinue}
      handleDone={handleDoneInitialization}
    />
  {:else if currentStep === steps[1]}
    <Planning
      {searching}
      {repoFullName}
      {files}
      {paths}
      {wipPaths}
      {comments}
      {messages}
      {handleSetComments}
      {handleClickExecute}
      {handleAddFile}
      {handleSubmitChat}
    />
  {/if}
</div>
