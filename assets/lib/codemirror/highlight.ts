import { EditorView, Decoration } from "@codemirror/view";
import { StateEffect, StateField } from "@codemirror/state";

const BACKGROUND_COLOR = "#fef16033";

const lineHighlightMark = Decoration.line({
  attributes: { style: `background-color: ${BACKGROUND_COLOR}` },
});

export const lineHighlightField = StateField.define({
  create() {
    return Decoration.none;
  },
  update(lines, tr) {
    lines = lines.map(tr.changes);

    for (let e of tr.effects) {
      if (e.is(removeLineHighlight)) {
        lines = Decoration.none;
      }
      if (e.is(addLineHighlight)) {
        lines = lines.update({
          add: e.value.map((line) => lineHighlightMark.range(line)),
        });
      }
    }
    return lines;
  },
  provide: (f) => EditorView.decorations.from(f),
});

export const addLineHighlight = StateEffect.define<number[]>();
export const removeLineHighlight = StateEffect.define();
