<script lang="ts">
  export let handleSubmit: (value: string) => void;
  export let placeholder = "Instruction or information...";

  const items = ["Comment"];
  let currentIndex = null;
  let value = "";

  const handleSubmitWrapper = () => {
    if (!value) {
      return;
    }

    handleSubmit(value);
  };

  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === "Enter") {
      handleSubmitWrapper();
    }
  };
</script>

<div
  class="bg-gray-100 rounded-lg shadow-[0_0_0_1px_rgba(0,0,0,0.05),0px_10px_20px_rgba(0,0,0,0.1)] text-opacity-80 text-black text-sm overflow-hidden p-1 relative"
>
  {#if currentIndex === null}
    {#each items as item, index}
      <button
        class={"border border-transparent rounded-md block m-0 py-1 px-2 text-left w-full"}
        on:click={() => (currentIndex = index)}
      >
        {item}
      </button>
    {/each}
  {:else}
    <div class="flex flex-row gap-1 items-center">
      <!-- svelte-ignore a11y-autofocus -->
      <input
        type="text"
        bind:value
        on:keydown={handleKeyDown}
        autofocus={true}
        class="w-[400px] h-8 border border-gray-300 bg-gray-50 focus:outline-none focus:ring-0 rounded-lg"
        {placeholder}
      />
      <button
        type="button"
        on:click={handleSubmitWrapper}
        class="w-12 h-8 bg-gray-800 text-gray-200 rounded-lg">Add</button
      >
    </div>
  {/if}
</div>
