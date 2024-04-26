#[derive(rustler::NifStruct)]
#[module = "Fastrepl.Retrieval.Chunker.Chunk"]
pub struct Chunk<'a> {
    pub file_path: &'a str,
    pub content: String,
    pub line_start: usize,
    pub line_end: usize,
}

impl<'a> std::fmt::Debug for Chunk<'a> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(
            f,
            "```{}#L{}-L{}",
            self.file_path, self.line_start, self.line_end
        )?;
        writeln!(f, "{}", self.content)?;
        writeln!(f, "```")
    }
}
