<script lang="ts">
  export let delay: number = 0;
</script>

<div class="flex gap-1">
  <div class="w-2 h-2 bg-gray-500 rounded-full opacity-0 animate-pulse" />
  <div
    class="w-2 h-2 bg-gray-500 rounded-full opacity-0 animate-pulse"
    style={`animation-delay: ${delay}ms`}
  />
  <div
    class="w-2 h-2 bg-gray-500 rounded-full opacity-0 animate-pulse"
    style={`animation-delay: ${delay * 2}ms`}
  />
</div>
