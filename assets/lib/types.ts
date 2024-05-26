export type Reference = {
  filePath: string;
  lineStart: number;
  lineEnd: number;
  handleClick: (ref: Reference) => void;
};

export type Selection = {
  start: number;
  end: number;
};
