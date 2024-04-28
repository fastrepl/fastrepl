<script lang="ts">
  import { onMount } from "svelte";
  import { fly } from "svelte/transition";

  export let live: any;
  export let tasks = [];

  onMount(() => {
    live.handleEvent("task:upsert", ({ task }: any) => {
      tasks = [task, ...tasks];
    });
  });
</script>

<div class="flex flex-col gap-2 text-xs w-fit max-h-[200px] overflow-y-auto">
  {#each tasks as task (task.name)}
    <div
      in:fly={{ duration: 300, y: 30 }}
      out:fly={{ duration: 300, x: 30 }}
      class="rounded-md bg-gray-100 px-2 py-1"
    >
      <span class="w-4 truncate">{task.name}</span>
    </div>
  {/each}
</div>
