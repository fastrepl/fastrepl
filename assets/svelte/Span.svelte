<script lang="ts">
  import { clsx } from "clsx";

  export let start: number;
  export let end: number;
</script>

<div
  class={clsx([
    "flex flex-row gap-1",
    "px-1.5 py-1 rounded-md",
    "bg-gray-200 hover:bg-yellow-100",
    "text-xs text-black",
  ])}
>
  <div class="flex flex-row gap-0">
    <span class="text-gray-500">L</span>
    <span>{start}</span>
  </div>
  <span>-</span>
  <div class="flex flex-row gap-0">
    <span class="text-gray-500">L</span>
    <span>{end}</span>
  </div>
</div>
