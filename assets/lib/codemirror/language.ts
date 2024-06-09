import { python } from "@codemirror/lang-python";
import { elixir } from "codemirror-lang-elixir";
import { javascript } from "@codemirror/lang-javascript";

export const getLanguage = (path: string) => {
  if (path.endsWith(".py")) {
    return python();
  } else if (path.endsWith(".ex") || path.endsWith(".exs")) {
    return elixir();
  } else {
    return javascript();
  }
};
