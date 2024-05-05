<script lang="ts">
  import { slide } from "svelte/transition";
  import { clsx } from "clsx";

  import { type TreeNode } from "$lib/utils/tree";

  export let root: string;
  export let items: TreeNode[] = [];
  export let currentFilePath: string;
  export let handleClickFile: (path: string) => void;
</script>

<ul class="text-xs text-gray-600 hover:text-gray-900">
  {#each items as item, i (item.path)}
    <li
      class={clsx(
        !item.children?.length && "hover:bg-gray-200",
        item.path === currentFilePath && "bg-gray-200 px-0.5 rounded-sm",
      )}
      transition:slide={{ duration: 600 }}
    >
      {#if item.children}
        <details open>
          <summary
            tabindex="0"
            class={clsx([
              "flex hover:underline p-0.5",
              item.name === root && "font-semibold",
            ])}
          >
            <slot {item} list={items} id={i}>
              <span>{item.name}</span>
            </slot>
          </summary>

          {#if item.children}
            <div class="pl-2">
              <svelte:self
                items={item.children}
                {currentFilePath}
                {handleClickFile}
                let:item
                let:list={items}
                let:id={i}
              >
                <slot {item} list={items} id={i}>
                  <button on:click={() => handleClickFile(item.path)}>
                    {item.name}
                  </button>
                </slot>
              </svelte:self>
            </div>
          {/if}
        </details>
      {:else}
        <slot {item} list={items} id={i}>
          <button on:click={() => handleClickFile(item.path)}>
            {item.name}
          </button>
        </slot>
      {/if}
    </li>
  {/each}
</ul>
