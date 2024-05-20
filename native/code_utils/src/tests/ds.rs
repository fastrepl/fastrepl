use crate::ds::Chunk;

use insta::assert_debug_snapshot;

#[test]
fn debug() {
    let chunk = Chunk {
        file_path: "test.md",
        content: "3\n4".to_string(),
        span: (3, 5),
    };

    assert_debug_snapshot!(chunk, @r###"
    ```test.md#L3-L5
    3
    4
    ```
    ---
    "###);
}
