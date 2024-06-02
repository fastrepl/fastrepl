import { Extension } from "@tiptap/core";

export const HandleEnter = () => {
  return Extension.create({
    addKeyboardShortcuts() {
      return {
        // Enter is for submit
        Enter: () => true,
        // https://github.com/ueberdosis/tiptap/issues/2755#issuecomment-1518524421
        "Shift-Enter": ({ editor }) =>
          editor.commands.first(({ commands }) => [
            () => commands.newlineInCode(),
            () => commands.splitListItem("listItem"),
            () => commands.createParagraphNear(),
            () => commands.liftEmptyBlock(),
            () => commands.splitBlock(),
          ]),
      };
    },
  });
};
