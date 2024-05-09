export interface Comment {
  file_path: string;
  line_start: number;
  line_end: number;
  content: string;
  read_only: boolean;
}

export interface File {
  path: string;
  content: string;
}

export interface Diff {
  file_path: string;
  content: string;
}

export interface Message {
  role: "assistant" | "user";
  content: string;
}
