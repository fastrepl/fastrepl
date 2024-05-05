export type Comment = {
  file_path: string;
  line_start: number;
  line_end: number;
  content: string;
};

export type Chunk = {
  file_path: string;
  content: string;
  spans: number[][];
};
