import TurndownService from "turndown";
import type { Rule } from "turndown";

const fileReference: Rule = {
  filter: (node, options) => {
    return !!node.getAttribute("data-file-path");
  },
  replacement: (content, node, options) => {
    const filePath = node.firstChild.textContent;
    return `[${filePath}](${filePath})`;
  },
};

export const turndownService = new TurndownService({
  codeBlockStyle: "fenced",
  headingStyle: "atx",
}).addRule("fileReference", fileReference);
