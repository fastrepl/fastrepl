<script lang="ts">
  import { slide } from "svelte/transition";
  import { clsx } from "clsx";

  import type { TreeNode } from "$lib/utils/tree";

  export let items: TreeNode[] = [];
  export let current_file_path: string;
  export let handleClickFile: (path: string) => void;
</script>

<ul class="text-sm text-gray-600 hover:text-gray-900">
  {#each items as item, i (item.path)}
    <li
      class={clsx(
        "max-w-[280px] truncate",
        !item.children?.length && "hover:bg-gray-200",
        item.path === current_file_path && "bg-gray-200 px-0.5 rounded-sm",
      )}
      transition:slide={{ duration: 600 }}
    >
      {#if item.children}
        <details open>
          <summary class="flex hover:underline p-0.5" tabindex="0">
            <slot {item} list={items} id={i}>
              <span class="max-w-[280px] truncate">{item.name}</span>
            </slot>
          </summary>

          {#if item.children}
            <div class="pl-4">
              <svelte:self
                items={item.children}
                {current_file_path}
                {handleClickFile}
                let:item
                let:list={items}
                let:id={i}
              >
                <slot {item} list={items} id={i}>
                  <button
                    class="max-w-[280px] truncate"
                    on:click={() => handleClickFile(item.path)}
                  >
                    {item.name}
                  </button>
                </slot>
              </svelte:self>
            </div>
          {/if}
        </details>
      {:else}
        <slot {item} list={items} id={i}>
          <button
            class="max-w-[280px] truncate"
            on:click={() => handleClickFile(item.path)}
          >
            {item.name}
          </button>
        </slot>
      {/if}
    </li>
  {/each}
</ul>
