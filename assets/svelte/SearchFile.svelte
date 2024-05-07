<script lang="ts">
  import { clsx } from "clsx";
  import Fuse from "fuse.js";
  import { onMount } from "svelte";

  export let paths: string[];
  export let handleSelectFile: (path: string) => void;

  let query = "";
  let currentIndex = null;

  $: fuse = new Fuse(paths, { threshold: 0.4 });
  $: matches = fuse.search(query, { limit: 20 }).map((match) => match.item);
  $: if (matches.length > 0 && currentIndex === null) {
    currentIndex = 0;
  }

  $: if (query.length === 0) {
    matches = paths;
  }

  onMount(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Enter") {
        handleSelectFile(matches[currentIndex]);
      }
      if (e.key === "ArrowUp") {
        currentIndex = (currentIndex + matches.length - 1) % matches.length;
      }
      if (e.key === "ArrowDown") {
        currentIndex = (currentIndex + 1) % matches.length;
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  });
</script>

<div class="flex flex-col gap-2 w-[500px]">
  <!-- svelte-ignore a11y-autofocus -->
  <input
    autofocus
    type="search"
    placeholder="Search files..."
    bind:value={query}
    on:change={() => (currentIndex = null)}
    class={clsx([
      "border-transparent focus:border-transparent focus:ring-0",
      "rounded-lg",
    ])}
  />

  <div
    class="max-h-[300px] overflow-y-auto border border-gray-400 rounded-lg p-2 bg-gray-800"
  >
    {#if query.length !== 0 && matches.length === 0}
      <span class="text-sm text-gray-300">No mathing results</span>
    {/if}

    {#each matches as match, index}
      <button
        type="button"
        on:click={() => handleSelectFile(match)}
        class={clsx([
          "w-full flex flex-row gap-4 items-center",
          "antialiased text-sm",
          "text-gray-300 hover:bg-gray-700 hover:text-gray-100",
          currentIndex === index && "bg-gray-600 text-gray-100",
        ])}
      >
        <span class="truncate">{match}</span>
      </button>
    {/each}
  </div>
</div>
