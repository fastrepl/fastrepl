<script lang="ts">
  import type { Comment, File, Diff, Message } from "$lib/interfaces";
  import Stepper from "$components/Stepper.svelte";
  import Initialization from "$components/Initialization.svelte";
  import Planning from "$components/Planning.svelte";
  import Execution from "$components/Execution.svelte";

  export let live: any;

  export let steps: string[] = [];
  export let currentStep: (typeof steps)[number];

  export let repoFullName: string;
  export let repoDescription: string;
  export let issueTitle: string;
  export let issueNumber: number;
  export let indexingTotal: number;
  export let indexingProgress: number;

  export let files: File[] = [];
  export let paths: string[] = [];
  export let comments: Comment[];
  export let messages: Message[] = [];
  export let diffs: Diff[] = [];

  const handleChangeStep = (step: string) => {
    currentStep = step;
    live.pushEvent("step:set", { step });
  };

  const handleNextStep = () => {
    const currentIndex = steps.indexOf(currentStep);
    const nextIndex = currentIndex + 1;

    if (nextIndex < steps.length) {
      currentStep = steps[nextIndex];
      live.pushEvent("step:set", { step: currentStep });
    }
  };

  const handleDoneInitialization = () => {};

  const handleClickExecute = () => {
    handleNextStep();
  };

  const handleSetComments = (comments: Comment[]) => {
    live.pushEvent("comment:set", { comments });
  };

  const handleAddFile = (path: string) => {
    live.pushEvent("file:add", { path });
  };

  const handleSubmitChat = (message: Message) => {
    live.pushEvent("chat:submit", { message });
  };
</script>

<div class="flex flex-col gap-2 items-center">
  <div class="w-[600px]">
    <Stepper {steps} {currentStep} handleChange={handleChangeStep} />
  </div>

  {#if currentStep === steps[0]}
    <Initialization
      {repoFullName}
      {repoDescription}
      {issueTitle}
      {issueNumber}
      {indexingTotal}
      {indexingProgress}
      {handleNextStep}
      handleDone={handleDoneInitialization}
    />
  {:else if currentStep === steps[1]}
    <Planning
      {repoFullName}
      {files}
      {paths}
      {comments}
      {messages}
      {handleSetComments}
      {handleClickExecute}
      {handleAddFile}
      {handleSubmitChat}
    />
  {:else if currentStep === steps[2]}
    <Execution {diffs} />
  {/if}
</div>
