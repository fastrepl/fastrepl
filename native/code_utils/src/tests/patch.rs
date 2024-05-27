use crate::patch;

use insta::assert_snapshot;

#[test]
fn create() {
    let old = format!(
        "{}{}",
        r#"
<h1 align="center">Fastrepl</h1>
<h4 align="center">
    <a href="https://discord.gg/Y8bJkzuQZU" target="_blank">
        <img src="https://dcbadge.vercel.app/api/server/nMQ8ZqAegc?style=flat">
    </a>
</h4>"#
            .trim(),
        "\n"
    );

    let new = "123";

    assert_snapshot!(patch::create("README.md", "README.md", &old, &new), @r###"
    --- README.md
    +++ README.md
    @@ -1,6 +1 @@
    -<h1 align="center">Fastrepl</h1>
    -<h4 align="center">
    -    <a href="https://discord.gg/Y8bJkzuQZU" target="_blank">
    -        <img src="https://dcbadge.vercel.app/api/server/nMQ8ZqAegc?style=flat">
    -    </a>
    -</h4>
    +123
    \ No newline at end of file
    "###);
}

#[test]
fn apply() {
    let old = format!(
        "{}{}",
        r#"
<h1 align="center">Fastrepl</h1>
<h4 align="center">
    <a href="https://discord.gg/Y8bJkzuQZU" target="_blank">
        <img src="https://dcbadge.vercel.app/api/server/nMQ8ZqAegc?style=flat">
    </a>
</h4>"#
            .trim(),
        "\n"
    );

    let new = "123";

    let patch = patch::create("README.md", "README.md", &old, &new);

    let applied = patch::apply(&old, &patch);
    assert_eq!(applied, new);
}
