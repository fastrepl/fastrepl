<script lang="ts">
  import { fade } from "svelte/transition";
  import { Dialog } from "bits-ui";
</script>

<Dialog.Root>
  <Dialog.Trigger>
    <span class="hero-plus-solid w-4 h-4 text-gray-700 hover:text-black" />
  </Dialog.Trigger>
  <Dialog.Portal>
    <Dialog.Overlay
      transition={fade}
      transitionConfig={{ duration: 150 }}
      class="fixed inset-0 z-50 bg-black/60"
    />
    <Dialog.Content
      class="fixed left-[50%] top-[200px] z-50 translate-x-[-50%]"
    >
      <div class="flex flex-col">
        <textarea
          class="w-[500px] h-[200px] border border-gray-300 rounded-t-lg"
          placeholder="Write a issue..."
        />
        <button class="w-full bg-black text-white text-sm py-2 rounded-b-lg"
          >Submit</button
        >
      </div>
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>
