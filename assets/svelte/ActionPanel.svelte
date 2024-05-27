<script lang="ts">
  import { clsx } from "clsx";
  import { Tabs } from "bits-ui";

  import type { Diff, Message, Comment } from "$lib/interfaces";

  import Comments from "$components/Comments.svelte";
  import ChatEditor from "$components/ChatEditor.svelte";
  import Messages from "$components/Messages.svelte";

  const TABS = ["Overview", "Chat"];
  let currentTab: (typeof TABS)[number] = TABS[0];

  export let showDiffs = false;
  export let handleToggleShowDiffs: () => void;

  export let paths: string[] = [];
  export let diffs: Diff[] = [];
  export let comments: Comment[] = [];
  export let messages: Message[] = [];
  export let handleClickExecute: () => void;
  export let executing: boolean;

  const references = [];
  const handleSubmitChat = () => {};
  const handleResetReferences = () => {};
  const handleDeleteReference = () => {};
</script>

<div class="h-[calc(100vh-90px)] border border-gray-200 rounded-lg">
  <Tabs.Root
    value={currentTab}
    onValueChange={(value) => (currentTab = value)}
    class="h-[calc(100vh-115px)]"
  >
    <Tabs.List class={clsx(["flex flex-row gap-0.5", "text-xs bg-gray-200"])}>
      <Tabs.Trigger
        value={TABS[0]}
        class={clsx([
          "data-[state=active]:font-semibold",
          "data-[state=active]:border-b-2 border-b-gray-500",
          "data-[state=inactive]:opacity-40 mx-1.5 py-0.5",
        ])}
      >
        {TABS[0]}
      </Tabs.Trigger>
      <Tabs.Trigger
        value={TABS[1]}
        class={clsx([
          "data-[state=active]:font-semibold",
          "data-[state=active]:border-b-2 border-b-gray-500",
          "data-[state=inactive]:opacity-40 mx-1.5 py-0.5",
        ])}
      >
        {TABS[1]}
      </Tabs.Trigger>
    </Tabs.List>
    <Tabs.Content value={TABS[0]} class="bg-gray-50 p-4 h-full">
      <Comments
        {showDiffs}
        {handleToggleShowDiffs}
        {executing}
        diffsSize={diffs.length}
        items={comments}
        wipPaths={[]}
        handleClickComment={() => {}}
        handleUpdateComments={() => {}}
        {handleClickExecute}
      />
    </Tabs.Content>
    <Tabs.Content value={TABS[1]} class="bg-gray-50 h-full relative p-4">
      <Messages {messages} />
      <div
        class={clsx([
          "w-full px-3",
          "absolute bottom-1 left-0",
          "flex flex-col gap-2",
        ])}
      >
        <ChatEditor
          {paths}
          {references}
          {handleResetReferences}
          {handleDeleteReference}
          handleSubmit={handleSubmitChat}
          placeholder="Ask anything about making changes to the codebase..."
        />
      </div>
    </Tabs.Content>
  </Tabs.Root>
</div>
