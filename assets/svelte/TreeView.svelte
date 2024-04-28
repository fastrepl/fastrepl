<script>
  import clsx from "clsx";

  /**
   * @typedef {Object} Item
   * @property {string} name required
   * @property {string} path required
   * @property {Item[]} [children] optional
   */

  /**
   * @type {Item[]}
   */
  export let items = [];
</script>

<ul class="text-sm text-gray-600 hover:text-gray-900">
  {#each items as item, i}
    <li
      phx-click="tree:select"
      phx-value-path={item.path}
      class={clsx(
        "max-w-[200px] truncate",
        !item.children?.length && "hover:bg-gray-100"
      )}
    >
      {#if item.children}
        <details open>
          <summary class="flex hover:underline p-0.5" tabindex="0">
            <slot {item} list={items} id={i}>
              <span class="max-w-[200px] truncate">{item.name}</span>
            </slot>
          </summary>

          {#if item.children}
            <div class="pl-4">
              <svelte:self
                items={item.children}
                let:item
                let:list={items}
                let:id={i}
              >
                <slot {item} list={items} id={i}>
                  <span class="max-w-[200px] truncate">{item.name}</span>
                </slot>
              </svelte:self>
            </div>
          {/if}
        </details>
      {:else}
        <slot {item} list={items} id={i}>
          <span class="max-w-[200px] truncate">{item.name}</span>
        </slot>
      {/if}
    </li>
  {/each}
</ul>
