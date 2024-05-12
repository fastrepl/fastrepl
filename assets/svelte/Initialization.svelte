<script lang="ts">
  import { clsx } from "clsx";

  import Repository from "$components/Repository.svelte";
  import Issue from "$components/Issue.svelte";

  export let repoFullName: string;
  export let repoDescription: string;
  export let repoSha: string;
  export let issueTitle: string;
  export let issueNumber: number;

  export let indexingTotal: number;
  export let indexingProgress: number;

  export let handleNextStep: () => void;
  export let handleDone: () => void;

  let done = false;

  $: if (indexingTotal && indexingProgress) {
    if (indexingTotal === indexingProgress) {
      handleDone();
      done = true;
    }
  }
</script>

<div class="flex flex-col gap-4 mt-10 items-center">
  <Repository {repoFullName} {repoDescription} {repoSha} />
  <Issue {repoFullName} {issueTitle} {issueNumber} />

  {#if indexingTotal && indexingProgress}
    <div class="w-[calc(100%-2rem)] bg-gray-200 rounded-full h-1">
      <div
        class="bg-gray-500 h-1 rounded-full"
        style="width: {Math.round((indexingProgress / indexingTotal) * 100)}%"
      ></div>
    </div>
  {/if}

  <button
    class={clsx([
      "w-full",
      "py-2 px-3 rounded-lg bg-gray-900 hover:bg-gray-700 text-white",
      "text-sm font-semibold leading-6 text-white active:text-white/80",
      "disabled:opacity-50",
    ])}
    on:click={handleNextStep}
    disabled={!done}
  >
    Next
  </button>
</div>
