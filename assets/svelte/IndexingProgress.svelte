<script lang="ts">
  export let indexingProgress: number;
  export let indexingTotal: number;
</script>

<div
  class="flex flex-col gap-3 px-1 py-2 border border-black rounded-lg bg-gray-100 text-sm w-full items-center"
>
  <div class="font-semibold">Repository Indexing</div>
  <div class="w-[calc(100%-2rem)] bg-gray-200 rounded-full h-1">
    <div
      class="bg-gray-500 h-1 rounded-full"
      style="width: {Math.round((indexingProgress / indexingTotal) * 100)}%"
    ></div>
  </div>
</div>
