<script lang="ts">
  import { onMount } from "svelte";
  import { fly } from "svelte/transition";

  const MAX_ACTIONS = 3;

  export let live: any;
  export let actions = [];

  onMount(() => {
    live.handleEvent("action:add", (action: any) => {
      actions = [...actions.slice(-(MAX_ACTIONS - 1)), action];
    });
  });

  const handleClick = (i: number) => {
    const action = actions[i];
    actions = actions.filter((_, index) => index !== i);
    live.pushEvent("action:run", { action });
  };
</script>

<div class="flex flex-row gap-6 items-center justify-center">
  {#each actions as action, i (action.name)}
    <button
      type="button"
      class="px-3 py-2 rounded-md bg-gray-100 hover:bg-gray-200"
      transition:fly={{ duration: 200 }}
      on:click={() => handleClick(i)}
    >
      <span>{action.name}</span>
    </button>
  {/each}
</div>
