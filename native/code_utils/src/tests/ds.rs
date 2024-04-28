use crate::ds::Chunk;
use insta::assert_debug_snapshot;

#[test]
fn debug() {
    let chunk = Chunk {
        file_path: "test.md",
        content: &(1..=10)
            .map(|n| n.to_string())
            .collect::<Vec<_>>()
            .join("\n"),
        spans: vec![(3, 5)],
    };

    assert_debug_snapshot!(chunk, @r###"
    ```test.md#L3-L5
    3
    4
    5
    ```
    ---
    "###);
}
