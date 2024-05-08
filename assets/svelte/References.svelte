<script lang="ts">
  import type { Reference } from "$lib/types";

  export let references: Reference[];
  export let handleDelete: (index: number) => void;
</script>

<div class="flex flex-row gap-2 items-center text-xs">
  {#each references as reference, index}
    <div
      class="relative flex flex-col gap-1 px-2 py-1 border border-gray-200 bg-gray-100 rounded-md"
    >
      <button
        type="button"
        class="text-lg absolute -left-[5px] -top-[15px] text-gray-400 hover:text-gray-500"
        on:click={() => handleDelete(references.indexOf(reference))}
      >
        <span class="hero-x-circle-solid w-4 h-4" />
      </button>
      <div class="flex flex-row justify-between">
        <span class="ml-2 font-semibold">#{index + 1}</span>
        <button
          type="button"
          class="border border-gray-300 rounded-md bg-gray-200 hover:bg-gray-300 px-0.5"
          on:click={() => reference.handleClick(reference)}
        >
          {`L${reference.lineStart}-L${reference.lineEnd}`}
        </button>
      </div>
      <span class="w-[120px] truncate" style="direction: rtl;">
        {reference.filePath}
      </span>
    </div>
  {/each}
</div>
