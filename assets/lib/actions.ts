import runTippy from "tippy.js";
import type { Props } from "tippy.js";

export const tippy = (
  element: HTMLElement,
  props: Partial<Omit<Props, "trigger">>,
) => {
  const { destroy, setProps: update } = runTippy(element, {
    allowHTML: true,
    ...props,
  });

  return { destroy, update };
};
