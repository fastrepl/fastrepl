import StarterKit from "@tiptap/starter-kit";
import Link from "@tiptap/extension-link";
import { common, createLowlight } from "lowlight";

import { CodeBlockLowlight } from "./codeBlockLowlight";
import { HandleEnter } from "./handleEnter";

export const Shared = [
  StarterKit.configure({
    bulletList: {
      HTMLAttributes: {
        class: "list-disc pl-4",
      },
    },
    orderedList: {
      HTMLAttributes: {
        class: "list-decimal pl-4",
      },
    },
    code: {
      HTMLAttributes: {
        class: "bg-gray-200 rounded-sm",
      },
    },
    codeBlock: false,
  }),
  CodeBlockLowlight.configure({
    lowlight: createLowlight(common),
    // HEX value taken from highlight.js theme
    HTMLAttributes: {
      class:
        "bg-[#0d1117] text-sm text-[#c9d1d9] rounded-lg w-[680px] overflow-auto px-3 py-4",
    },
  }),
  HandleEnter(),
  Link.configure({
    linkOnPaste: true,
    HTMLAttributes: {
      class: "text-blue-500 underline bg-gray-200 p-1 rounded-md",
    },
  }),
];
