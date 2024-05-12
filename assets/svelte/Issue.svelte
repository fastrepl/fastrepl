<script lang="ts">
  export let repoFullName: string;
  export let issueTitle: string;
  export let issueNumber: number;
</script>

<div
  class="flex flex-row gap-2 py-1 px-2 border border-black rounded-lg bg-gray-100 text-sm w-full"
>
  <a
    href="https://github.com/{repoFullName}/issues/{issueNumber}"
    class="text-sm font-semibold hover:underline w-fit px-1"
  >
    #{issueNumber}
  </a>
  <span class="text-sm truncate max-w-72">
    {issueTitle}
  </span>
</div>
