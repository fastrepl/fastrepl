export type Comment = {
  file_path: string;
  line_start: number;
  line_end: number;
  content: string;
};

export type File = {
  path: string;
  content: string;
};
