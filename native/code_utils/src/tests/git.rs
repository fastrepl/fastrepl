use insta::assert_snapshot;

fn patches() {
    assert_eq!(result.len(), 2);
    assert_snapshot!(result.get("random.txt").unwrap(), @r###"
    diff --git a/random.txt b/random.txt
    new file mode 100644
    index 0000000..b6fc4c6
    --- /dev/null
    +++ b/random.txt
    @@ -0,0 +1 @@
    +hello
    \ No newline at end of file
    "###);
    assert_snapshot!(result.get("README.md").unwrap(), @r###"
    diff --git a/README.md b/README.md
    index f6d2639..b6fc4c6 100644
    --- a/README.md
    +++ b/README.md
    @@ -1,6 +1 @@
    -<h1 align="center">Fastrepl</h1>
    -<h4 align="center">
    -    <a href="https://discord.gg/Y8bJkzuQZU" target="_blank">
    -        <img src="https://dcbadge.vercel.app/api/server/nMQ8ZqAegc?style=flat">
    -    </a>
    -</h4>
    +hello
    \ No newline at end of file
    "###);