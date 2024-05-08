<script lang="ts">
  import { afterUpdate } from "svelte";
  import type { Message } from "$lib/interfaces";

  import ChatMessage from "$components/ChatMessage.svelte";
  import Typing from "$components/Typing.svelte";

  export let messages: Message[] = [];

  let messagesContainer: HTMLElement;

  afterUpdate(() => {
    if (messagesContainer) {
      messagesContainer.scrollTo({
        top: messagesContainer.scrollHeight,
        behavior: "smooth",
      });
    }
  });
</script>

<div
  bind:this={messagesContainer}
  class="overflow-y-hidden hover:overflow-y-auto h-[calc(100%-120px)] scrollbar-hide"
>
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
</div>
