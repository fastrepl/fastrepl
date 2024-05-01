use crate::*;

use include_uri::include_str_from_url;
use insta::assert_debug_snapshot;

#[test]
fn markdown() {
    let code = include_str_from_url!(
        "https://raw.githubusercontent.com/langchain-ai/langchain/6ccecf23639ef5cbebcbc4eaeda99eb1f7b84deb/README.md"
    );
    let result = _chunk_code("test.md", code);

    assert_eq!(result.len(), 4);
    assert_eq!(result[0].file_path, "test.md");
    assert_eq!(result[0].spans, vec![(1, 50)]);

    assert_eq!(result[1].file_path, "test.md");
    assert_eq!(result[1].spans, vec![(41, 90)]);

    assert_eq!(result[2].file_path, "test.md");
    assert_eq!(result[2].spans, vec![(81, 130)]);

    assert_eq!(result[3].file_path, "test.md");
    assert_eq!(result[3].spans, vec![(121, 137)]);

    assert_debug_snapshot!(result);
}
