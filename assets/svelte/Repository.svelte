<script lang="ts">
  export let repoFullName: string;
  export let repoDescription: string;
  export let repoSha: string;
</script>

<div
  class="flex flex-col items-center gap-2 p-2 border border-black rounded-lg bg-gray-100 relative w-full"
>
  <div class="flex flex-row items-center truncate max-w-72">
    <a
      href="https://github.com/{repoFullName}"
      class="text-sm font-semibold hover:underline w-fit"
    >
      {repoFullName}
    </a>

    <a
      href="https://github.com/{repoFullName}/tree/{repoSha}"
      class="text-xs hover:underline ml-1 border border-gray-300 rounded-md px-1 py-0.5 text-gray-700"
    >
      {repoSha.slice(0, 7)}
    </a>
  </div>

  <span class="text-xs truncate max-w-72">
    {repoDescription}
  </span>
</div>
