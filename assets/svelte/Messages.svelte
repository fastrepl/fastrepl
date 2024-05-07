<script lang="ts">
  import type { Message } from "$lib/types";

  import ChatMessage from "$components/ChatMessage.svelte";
  import Typing from "$components/Typing.svelte";

  export let messages: Message[] = [];
</script>

{#each messages as message}
  <ChatMessage
    name={message.role === "assistant" ? "AI" : "User"}
    time={new Date().toLocaleTimeString()}
  >
    {#if message.content === ""}
      <Typing delay={2000} />
    {:else}
      {message.content}
    {/if}
  </ChatMessage>
{/each}
