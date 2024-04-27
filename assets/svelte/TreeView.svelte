<script>
  /**
   * @typedef {Object} Item
   * @property {string} name required
   * @property {string} path required
   * @property {boolean} [current] optional
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
      class={`${item.children?.length ? "" : "hover:bg-gray-50"}`}
      class:current={item.current}
    >
      {#if item.children}
        <details open>
          <summary class="flex hover:underline p-0.5" tabindex="0">
            <slot {item} list={items} id={i}>
              {item.name}
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
                <slot {item} list={items} id={i}>{item.name}</slot>
              </svelte:self>
            </div>
          {/if}
        </details>
      {:else}
        <slot {item} list={items} id={i}>
          {item.name}
        </slot>
      {/if}
    </li>
  {/each}
</ul>

<style>
  li.current {
    padding-left: 0.5em;
    padding-top: 0.1em;
    padding-bottom: 0.1em;
    background-color: rgb(243 244 246);
  }
</style>
