export interface Comment {
  file_path: string;
  line_start: number;
  line_end: number;
  content: string;
}

export interface File {
  path: string;
  content: string;
}

export interface Diff {
  file_path: string;
  content: string;
}
