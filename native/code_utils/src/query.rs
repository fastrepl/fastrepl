use grep::{
    printer::JSONBuilder,
    regex::RegexMatcherBuilder,
    searcher::{BinaryDetection, SearcherBuilder},
};

use crate::ds::GrepResult;

pub fn grep<R: std::io::Read>(reader: R, pattern: &str) -> anyhow::Result<Vec<usize>> {
    let matcher = RegexMatcherBuilder::new()
        .case_smart(true)
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
