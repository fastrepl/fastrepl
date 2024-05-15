use crate::*;

use include_uri::include_str_from_url;
use insta::assert_debug_snapshot;

#[test]
fn markdown() {
    let code = include_str_from_url!(
        "https://raw.githubusercontent.com/langchain-ai/langchain/6ccecf23639ef5cbebcbc4eaeda99eb1f7b84deb/README.md"
    );
    let result = _chunk_code("test.md", code);

    assert_eq!(result.len(), 1);
    assert_eq!(result[0].file_path, "test.md");
    assert_eq!(result[0].span, (1, 137));

    assert_debug_snapshot!(result);
}
