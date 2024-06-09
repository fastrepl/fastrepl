import { textblockTypeInputRule, mergeAttributes } from "@tiptap/core";
import Original, {
  CodeBlockLowlightOptions,
} from "@tiptap/extension-code-block-lowlight";
// https://github.com/ueberdosis/tiptap/blob/main/packages/extension-code-block-lowlight/src/code-block-lowlight.ts

const backtickInputRegex = /^```([\w./]+)?[\s\n]$/;

export const CodeBlockLowlight = Original.extend<CodeBlockLowlightOptions>({
  // https://github.com/ueberdosis/tiptap/blob/main/packages/extension-code-block/src/code-block.ts#L216
  addInputRules() {
    return [
      textblockTypeInputRule({
        find: backtickInputRegex,
        type: this.type,
        getAttributes: (match) => {
          const info = match[1];

          if (!info) {
            return { language: null, path: null };
          }

          const path = info;
          const arr = path.split(".");
          const language = arr[arr.length - 1];
          return { language, path };
        },
      }),
    ];
  },
  // https://github.com/ueberdosis/tiptap/blob/677642eda8f56b24f4d9874e1d9f950614c1296b/packages/extension-code-block/src/code-block.ts#L66-L87
  addAttributes() {
    return {
      language: {
        default: null,
        rendered: false,
      },
      path: {
        default: null,
        rendered: false,
      },
    };
  },
  // https://github.com/ueberdosis/tiptap/blob/677642eda8f56b24f4d9874e1d9f950614c1296b/packages/extension-code-block/src/code-block.ts#L98-L112
  renderHTML({ node, HTMLAttributes }) {
    const languageClass = node.attrs.language
      ? this.options.languageClassPrefix + node.attrs.language
      : null;
    const pathClass = node.attrs.path ? "path-" + node.attrs.path : null;

    const classes = [languageClass, pathClass];

    return [
      "pre",
      mergeAttributes(this.options.HTMLAttributes, HTMLAttributes),
      ["code", { class: classes.filter(Boolean).join(" ") }, 0],
    ];
  },
});
