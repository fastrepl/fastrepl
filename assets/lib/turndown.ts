import TurndownService from "turndown";

export const turndownService = new TurndownService({
  codeBlockStyle: "fenced",
  headingStyle: "atx",
}).addRule("fencedCodeBlock", {
  filter: (node, options) => {
    return (
      node.nodeName === "PRE" &&
      node.firstChild &&
      node.firstChild.nodeName === "CODE" &&
      node.firstChild.className &&
      node.firstChild.className.startsWith("language-")
    );
  },
  replacement: (content, node, options) => {
    const { className } = node.firstChild;
    const [language, path] = className.split(" ");

    const languageInfo = language.substring("language-".length);
    const pathInfo = path.substring("path-".length);
    const codeBlockInfo = pathInfo ? pathInfo : languageInfo;

    return (
      "\n\n```" +
      codeBlockInfo +
      "\n" +
      node.firstChild.textContent +
      "\n```\n\n"
    );
  },
});
