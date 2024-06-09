export interface Comment {
  id: number;
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

export interface Live {
  pushEvent: (
    event:
      | "open_file"
      | "open_file_for_edit"
      | "update_file"
      | "diffs_fetch"
      | "open_file_for_edit"
      | "execute"
      | "pr:create"
      | "patch:download"
      | "comments:share"
      | "comments:create"
      | "comments:delete"
      | "comments:update"
      | "issue:submit",
    input: { [key: string]: any },
    cb?: (output: { [key: string]: any }) => void,
  ) => void;
}
