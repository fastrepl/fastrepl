<script lang="ts">
  export let repoFullName: string;
  export let repoDescription: string;

  export let indexingTotal: number;
  export let indexingProgress: number;
</script>

<div
  class="flex flex-col items-center gap-2 p-2 border border-black rounded-xl bg-gray-100 relative"
>
  <a
    href="https://github.com/{repoFullName}"
    class="text-sm font-semibold hover:underline w-fit"
  >
    {repoFullName}
  </a>

  <span class="text-xs truncate max-w-72">
    {repoDescription}
  </span>

  {#if indexingTotal && indexingProgress}
    <div class="w-[calc(100%-2rem)] bg-gray-200 rounded-full h-1">
      <div
        class="bg-gray-500 h-1 rounded-full"
        style="width: {Math.round((indexingProgress / indexingTotal) * 100)}%"
      ></div>
    </div>
  {/if}
</div>
