<script lang="ts">
  import { onMount, createEventDispatcher } from "svelte";

  import { clsx } from "clsx";
  import tippy, { type Instance as TippyInstance } from "tippy.js";

  import type { File, Comment } from "$lib/interfaces";
  import type { Selection } from "$lib/types";

  import CodeActionList from "$components/CodeActionList.svelte";
  import Minimap from "$components/Minimap.svelte";

  import {
    EditorView,
    lineNumbers,
    highlightSpecialChars,
    drawSelection,
  } from "@codemirror/view";
  import { EditorState, StateEffect, type Extension } from "@codemirror/state";

  import { githubLight as theme } from "$lib/codemirror/theme";
  import { getLanguage } from "$lib/codemirror/language";
  import {
    lineHighlightField,
    addLineHighlight,
    removeLineHighlight,
  } from "$lib/codemirror/highlight";

  const extensionsWithoutLanguage = (): Extension[] => [
    EditorView.editable.of(false),
    EditorState.readOnly.of(true),
    EditorState.allowMultipleSelections.of(false),
    drawSelection({ drawRangeCursor: false }),
    theme,
    lineNumbers(),
    highlightSpecialChars(),
    lineHighlightField,
  ];

  const createEditorState = (file: File) => {
    return EditorState.create({
      doc: file.content,
      extensions,
    });
  };

  const dispatch = createEventDispatcher<{ ready: EditorView }>();

  onMount(() => {
    view = new EditorView({ parent: codeContainer });
    dispatch("ready", view);
    return () => view.destroy();
  });

  $: extensions = extensionsWithoutLanguage();
  $: view && highlights && view.dispatch({ selection: { anchor: 0 } });
  $: view && view.setState(createEditorState(file));
  $: view && view.dispatch({ effects: StateEffect.reconfigure.of(extensions) });

  $: if (view) {
    const addLineHighlights = highlights.flatMap(({ start, end }) => {
      const lines = Array.from(
        { length: end - start + 1 },
        (_, index) => start + index,
      );
      const positions = lines.map((line) => view.state.doc.line(line).from);
      return addLineHighlight.of(positions);
    });

    view.dispatch({
      effects: [removeLineHighlight.of(null), ...addLineHighlights],
    });
  }

  $: if (file.path) {
    extensions = [...extensionsWithoutLanguage(), getLanguage(file.path)];
  }

  let codeContainer: HTMLDivElement;
  let contextMenuInstance: TippyInstance | null = null;
  let view: EditorView;

  export let file: File;
  export let highlights: Selection[] = [];
  export let handleCreateComments: (comments: Comment[]) => void;

  const currentSelection = (): Selection | null => {
    if (!view) {
      return null;
    }

    const selection = view.state.selection.main;
    if (!selection || selection.from === selection.to) {
      return null;
    }

    const start = view.state.doc.lineAt(selection.from).number;
    const end = view.state.doc.lineAt(selection.to).number;

    return { start, end };
  };

  const handleContextMenu = (e: MouseEvent) => {
    e.preventDefault();

    if (currentSelection() === null) {
      return;
    }

    contextMenuInstance.setProps({
      getReferenceClientRect: () =>
        ({
          width: 0,
          height: 0,
          top: e.clientY,
          bottom: e.clientY,
          left: e.clientX,
          right: e.clientX,
        }) as DOMRect,
    });

    contextMenuInstance.show();
  };

  const handleSubmitComment = (content: string) => {
    contextMenuInstance.hide();

    if (!view) {
      return;
    }

    const selection = currentSelection();
    if (!selection) {
      return;
    }

    handleCreateComments([
      {
        id: -1,
        content,
        file_path: file.path,
        line_start: selection.start,
        line_end: selection.end,
      },
    ]);
  };

  $: {
    const createCodeActionList = (target: Element) => {
      return new CodeActionList({
        target,
        props: { handleSubmitComment },
      });
    };

    if (codeContainer && !contextMenuInstance) {
      contextMenuInstance = tippy(codeContainer, {
        placement: "auto",
        onCreate: (instance) => {
          const target = instance.popper.querySelector(".tippy-content");
          createCodeActionList(target);
        },
        onHidden: (instance) => {
          const target = instance.popper.querySelector(".tippy-content");
          target.firstChild.remove();
          createCodeActionList(target);
        },
        trigger: "manual",
        allowHTML: true,
        interactive: true,
        appendTo: () => document.body,
      });
    }
  }
</script>

<div class="flex flex-col">
  <span class="text-xs rounded-t-lg bg-gray-200 py-1 px-2 font-semibold">
    {file.path}
  </span>

  <!-- svelte-ignore a11y-no-static-element-interactions -->
  <div
    bind:this={codeContainer}
    on:contextmenu={handleContextMenu}
    class={clsx([
      "h-[calc(100vh-115px)] overflow-y-auto scrollbar-hide",
      "text-sm selection:bg-[#fef16033]",
      "border-b border-x border-gray-200 rounded-b-lg",
    ])}
  />

  {#if codeContainer}
    <div class="absolute right-1 top-7">
      <Minimap
        root={codeContainer}
        config={{
          "cm-selectionBackground": {
            alpha: 0.8,
            fillStyle: "rgb(253 224 71)",
          },
        }}
      />
    </div>
  {/if}
</div>
