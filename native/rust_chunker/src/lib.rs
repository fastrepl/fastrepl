#[cfg(test)]
mod tests;

rustler::init!("Elixir.Fastrepl.Native.RustChunker", [chunk_code]);

#[derive(rustler::NifStruct)]
#[module = "Fastrepl.Retrieval.Chunker.Chunk"]
struct Chunk<'a> {
    file_path: &'a str,
    content: String,
    line_start: usize,
    line_end: usize,
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

#[rustler::nif(schedule = "DirtyCpu")]
fn chunk_code<'a>(path: &'a str, code: &str) -> Vec<Chunk<'a>> {
    _chunk_code(path, code)
}

const NAIVE_CHUNKING_LINE_COUNT: usize = 50;
const NAIVE_CHUNKING_OVERLAP: usize = 10;

fn _chunk_code<'a>(path: &'a str, code: &str) -> Vec<Chunk<'a>> {
    let ext = path.split(".").last().unwrap_or("");
    let language = match ext {
        "js" | "mjs" | "cjs" => Some(rs_tree_sitter_languages::javascript::language()),
        "ts" | "mts" | "cts" => Some(rs_tree_sitter_languages::typescript::language()),
        "jsx" | "tsx" => Some(rs_tree_sitter_languages::tsx::language()),
        "rs" => Some(rs_tree_sitter_languages::rust::language()),
        "py" => Some(rs_tree_sitter_languages::python::language()),
        "go" => Some(rs_tree_sitter_languages::go::language()),
        "ex" | "exs" => Some(rs_tree_sitter_languages::elixir::language()),
        "erl" | "hrl" => Some(rs_tree_sitter_languages::erlang::language()),
        "pl" => Some(rs_tree_sitter_languages::perl::language()),
        "rb" => Some(rs_tree_sitter_languages::ruby::language()),
        _ => None,
    };

    if let Some(language) = language {
        language_aware_chunking(path, code, &language)
    } else {
        naive_chunking(path, code)
    }
}

fn naive_chunking<'a>(path: &'a str, code: &str) -> Vec<Chunk<'a>> {
    let mut chunks = vec![];
    let code_lines: Vec<&str> = code.split('\n').collect();

    let mut start = 0;
    let mut end = NAIVE_CHUNKING_LINE_COUNT;

    while start < code_lines.len() {
        end = std::cmp::min(end, code_lines.len());

        let chunk = Chunk {
            file_path: path,
            line_start: start + 1,
            line_end: end,
            content: code_lines[start..end].join("\n"),
        };

        chunks.push(chunk);

        start += NAIVE_CHUNKING_LINE_COUNT - NAIVE_CHUNKING_OVERLAP;
        end += NAIVE_CHUNKING_LINE_COUNT - NAIVE_CHUNKING_OVERLAP;
    }

    chunks
}
fn language_aware_chunking<'a>(
    path: &'a str,
    code: &str,
    _language: &tree_sitter::Language,
) -> Vec<Chunk<'a>> {
    naive_chunking(path, code)
}
