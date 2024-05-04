<script>
  import { clsx } from "clsx";

  export let items = [];
  export let command;

  let selectedIndex = 0;

  const selectItem = (index) => {
    const item = items[index];

    if (item) {
      command({ id: item });
    }
  };

  const upHandler = () => {
    selectedIndex = (selectedIndex + items.length - 1) % items.length;
  };

  const downHandler = () => {
    selectedIndex = (selectedIndex + 1) % items.length;
  };

  const enterHandler = () => {
    selectItem(selectedIndex);
  };

  export const onKeyDown = (event) => {
    if (event.key === "ArrowUp") {
      upHandler();
      return true;
    }

    if (event.key === "ArrowDown") {
      downHandler();
      return true;
    }

    if (event.key === "Enter") {
      event.stopPropagation();

      enterHandler();
      return true;
    }

    return false;
  };

  $: {
    selectedIndex = 0;
  }
</script>

<div
  class="bg-gray-100 rounded-lg shadow-[0_0_0_1px_rgba(0,0,0,0.05),0px_10px_20px_rgba(0,0,0,0.1)] text-opacity-80 text-black text-sm overflow-hidden p-1 relative"
>
  {#if items.length}
    {#each items as item, index}
      <button
        class={clsx(
          "border border-transparent rounded-md block m-0 py-1 px-2 text-left w-full",
          index === selectedIndex ? "bg-gray-200" : "bg-transparent",
        )}
        on:click={() => selectItem(index)}
      >
        {item}
      </button>
    {/each}
  {/if}
</div>
