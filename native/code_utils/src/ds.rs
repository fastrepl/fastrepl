#[derive(rustler::NifStruct)]
#[module = "Fastrepl.Retrieval.Chunker.Chunk"]
pub struct Chunk<'a> {
    pub file_path: &'a str,
    pub content: String,
    pub span: (usize, usize),
}

impl<'a> std::fmt::Debug for Chunk<'a> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let (line_start, line_end) = self.span;

        writeln!(
            f,
            "```{}#L{}-L{}\n{}\n```",
            self.file_path, line_start, line_end, self.content
        )?;
        writeln!(f, "---")
    }
}

// https://docs.rs/grep-printer/latest/grep_printer/struct.JSON.html
#[derive(serde::Deserialize)]
pub struct GrepResult {
    pub r#type: String,
    pub data: GrepResultData,
}

#[derive(serde::Deserialize)]
pub struct GrepResultData {
    pub line_number: Option<usize>,
}
