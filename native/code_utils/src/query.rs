use grep::{
    printer::JSONBuilder,
    regex::RegexMatcherBuilder,
    searcher::{BinaryDetection, SearcherBuilder},
};

use crate::ds::GrepResult;

pub fn grep<R: std::io::Read>(reader: R, pattern: &str) -> anyhow::Result<Vec<usize>> {
    let matcher = RegexMatcherBuilder::new()
        .case_smart(true)
        .fixed_strings(true)
        .line_terminator(Some(b'\n'))
        .build(pattern)?;

    let mut searcher = SearcherBuilder::new()
        .binary_detection(BinaryDetection::quit(b'\x00'))
        .build();

    let mut printer = JSONBuilder::new().build(vec![]);
    let _ = searcher.search_reader(&matcher, reader, printer.sink(&matcher))?;

    let json_string = String::from_utf8(printer.get_mut().to_owned())?;

    let line_numbers: Vec<usize> = json_string
        .lines()
        .filter_map(|line| serde_json::from_str(line).ok())
        .filter_map(|result: GrepResult| result.data.line_number)
        .collect();

    Ok(line_numbers)
}

struct SourceText<'a> {
    source_code: &'a [u8],
}

impl<'a> tree_sitter::TextProvider<&'a [u8]> for SourceText<'a> {
    type I = std::iter::Once<&'a [u8]>;

    fn text(&mut self, node: tree_sitter::Node) -> Self::I {
        std::iter::once(&self.source_code[node.start_byte()..node.end_byte()])
    }
}

pub fn ast_query<'a>(
    code: &'a str,
    language: &tree_sitter::Language,
    query: &str,
) -> Vec<(usize, usize)> {
    let mut parser = tree_sitter::Parser::new();
    parser.set_language(language).unwrap();

    let tree = parser.parse(code, None).unwrap();
    let query = tree_sitter::Query::new(language, query).unwrap();
    let mut cursor = tree_sitter::QueryCursor::new();

    let source_text = SourceText {
        source_code: code.as_bytes(),
    };
    let captures = cursor.captures(&query, tree.root_node(), source_text);

    captures
        .flat_map(|(query_match, _)| {
            query_match
                .captures
                .iter()
                .map(|capture| (capture.node.start_byte(), capture.node.end_byte()))
        })
        .collect()
}
