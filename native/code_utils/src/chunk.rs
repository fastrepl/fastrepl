use crate::ds;

const NAIVE_CHUNKING_LINE_COUNT: usize = 50;
const NAIVE_CHUNKING_OVERLAP: usize = 10;

pub fn naive<'a>(path: &'a str, code: &'a str) -> Vec<ds::Chunk<'a>> {
    let mut chunks = vec![];
    let code_lines: Vec<&str> = code.split('\n').collect();

    let mut start = 0;
    let mut end = NAIVE_CHUNKING_LINE_COUNT;

    while start < code_lines.len() {
        end = std::cmp::min(end, code_lines.len());

        let chunk = ds::Chunk {
            file_path: path,
            spans: vec![(start + 1, end)],
            content: code,
        };

        chunks.push(chunk);

        start += NAIVE_CHUNKING_LINE_COUNT - NAIVE_CHUNKING_OVERLAP;
        end += NAIVE_CHUNKING_LINE_COUNT - NAIVE_CHUNKING_OVERLAP;
    }

    chunks
}

pub fn language_aware<'a>(
    path: &'a str,
    code: &'a str,
    _language: &tree_sitter::Language,
) -> Vec<ds::Chunk<'a>> {
    naive(path, code)
}
