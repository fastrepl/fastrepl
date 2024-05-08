<script lang="ts">
  export let name: string;
  export let time: string;
</script>

<div class="flex p-2">
  <div class="h-10 w-10 rounded flex-shrink-0 bg-[#e5e7eb]">
    <img
      alt={name}
      src={`//ui-avatars.com/api/?name=${name}&background=e5e7eb&font-size=0.35`}
      class="h-10 w-10 rounded flex-shrink-0"
    />
  </div>

  <div class="ml-2 flex flex-col justify-between pb-1 text-xs">
    <div class="-mt-1">
      <span class="font-semibold">
        {name}
      </span>
      <span class="ml-0.5 text-gray-500">
        {time}
      </span>
    </div>

    <div class="text-sm">
      <slot />
    </div>
  </div>
</div>
