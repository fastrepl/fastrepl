<script lang="ts">
  import { clsx } from "clsx";

  export let steps: string[];
  export let currentStep: string;
  export let handleChange: (step: string) => void;
</script>

<div
  class="relative after:absolute after:inset-x-0 after:top-1/2 after:block after:h-0.5 after:-translate-y-1/2 after:rounded-lg after:bg-gray-100"
>
  <ol
    class="relative z-10 flex justify-between text-sm font-medium text-gray-500"
  >
    {#each steps as step, index}
      <li>
        <button
          type="button"
          on:click={() => handleChange(step)}
          class={clsx([
            "flex items-center gap-2 p-2 group",
            "bg-white disabled:opacity-50",
          ])}
        >
          {#if currentStep === step}
            <span
              class="size-6 rounded-full bg-gray-600 text-center text-[10px]/6 font-bold text-white"
            >
              {index + 1}
            </span>
          {:else}
            <span
              class="size-6 rounded-full bg-gray-100 group-hover:bg-gray-600 group-hover:text-white text-center text-[10px]/6 font-bold"
            >
              {index + 1}
            </span>
          {/if}
          <span>{step}</span>
        </button>
      </li>
    {/each}
  </ol>
</div>
