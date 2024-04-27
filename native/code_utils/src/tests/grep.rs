use crate::*;

use include_uri::include_str_from_url;

#[test]
fn small() {
    let code: &str = r#"
a = 1
b = 2
a = 3
c = 3"#;

    let result = _grep(code.as_bytes(), "a");
    assert_eq!(result, vec![2, 4]);
}

#[test]
fn big() {
    let code = include_str_from_url!(
        "https://raw.githubusercontent.com/langchain-ai/langchain/6ccecf23639ef5cbebcbc4eaeda99eb1f7b84deb/README.md"
    );

    let result = _grep(code.as_bytes(), "langchain");
    assert_eq!(result.len(), 60);
}
