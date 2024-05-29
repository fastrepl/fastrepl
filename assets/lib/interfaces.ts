export interface Comment {
  id: string;
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
  path: string;
  content: string;
}

export interface Message {
  role: "assistant" | "user";
  content: string;
}
