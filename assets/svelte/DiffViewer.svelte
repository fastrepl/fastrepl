<script lang="ts">
  import { clsx } from "clsx";

  import type { Diff } from "$lib/interfaces";
  import CodeDiff from "$components/CodeDiff.svelte";

  export let diffs: Diff[] = [];
</script>

<div class="flex flex-col">
  <span class="text-xs rounded-t-lg bg-gray-200 py-1 px-2"> changes </span>

  <div
    class={clsx([
      "h-[calc(100vh-90px)] overflow-y-auto scrollbar-hide bg-gray-50 relative",
      "border-b border-x border-gray-200 rounded-b-lg",
    ])}
  >
    <CodeDiff content={diffs.map((diff) => diff.content).join("\n")} />
  </div>
</div>
