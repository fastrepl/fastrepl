export type Reference = {
  filePath: string;
  lineStart: number;
  lineEnd: number;
  handleClick: (ref: Reference) => void;
};
