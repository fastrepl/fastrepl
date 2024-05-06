<script lang="ts">
  import { clsx } from "clsx";

  export let handleSubmitComment: (value: string) => void;
  export let handleSubmitReference: () => void;
  export let placeholder = "Instruction or information...";

  const items = ["Comment", "Chat"];

  let currentIndex = null;
  let value = "";

  const handleChangeIndex = (index: number) => {
    currentIndex = index;

    if (currentIndex === 1) {
      handleSubmitReference();
    }
  };

  const handleSubmitCommentWrapper = () => {
    if (!value) {
      return;
    }
    handleSubmitComment(value);
  };

  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === "Enter") {
      handleSubmitCommentWrapper();
    }
  };
</script>

<div
  class={clsx([
    "border border-gray-300 rounded-lg",
    "text-opacity-80 text-black text-sm",
    "bg-gray-100 overflow-hidden relative p-0.5",
  ])}
>
  {#if currentIndex === null}
    {#each items as item, index}
      <button
        on:click={() => handleChangeIndex(index)}
        class={clsx([
          "border border-transparent py-1 px-2 m-0",
          "rounded-md block text-left w-full",
          "bg-gray-100 hover:bg-gray-200",
        ])}
      >
        {item}
      </button>
    {/each}
  {:else if currentIndex === 0}
    <div class="flex flex-row gap-1 items-center">
      <!-- svelte-ignore a11y-autofocus -->
      <input
        type="text"
        bind:value
        on:keydown={handleKeyDown}
        autofocus={true}
        class={clsx([
          "w-[400px] h-8 bg-gray-50",
          "border border-gray-300 rounded-lg",
          "border-transparent focus:border-transparent focus:ring-0",
        ])}
        {placeholder}
      />
      <button
        type="button"
        on:click={handleSubmitCommentWrapper}
        class={clsx([
          "w-12 h-8 rounded-lg",
          "bg-gray-200 hover:bg-gray-300",
          "text-gray-400 hover:text-gray-500 text-md",
        ])}
      >
        +
      </button>
    </div>
  {/if}
</div>
