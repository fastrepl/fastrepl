<script lang="ts">
  export let name: string;
  export let time: string;
</script>

<div class="flex px-4 py-3 relative">
  <div class="h-10 w-10 rounded flex-shrink-0 bg-[#f0e9e9]">
    <img
      alt={name}
      src={`//ui-avatars.com/api/?name=${name}&background=f0e9e9&font-size=0.35`}
      class="h-10 w-10 rounded flex-shrink-0"
    />
  </div>

  <div class="ml-2">
    <div class="-mt-1">
      <span class="text-sm font-semibold">
        {name}
      </span>
      <span class="ml-1 text-xs text-gray-500">
        {time}
      </span>
    </div>

    <div class="text-sm">
      <slot />
    </div>
  </div>
</div>
