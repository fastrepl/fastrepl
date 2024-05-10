use crate::git;

use nanoid::nanoid;
use std::{env::temp_dir, io::Write};

use insta::assert_snapshot;

#[test]
fn clone() {
    let repo_url = "https://github.com/fastrepl/fastrepl.git";
    let dest_path = temp_dir().join(nanoid!()).to_str().unwrap().to_string();
    git::clone(repo_url, &dest_path, 1).unwrap();
}

#[test]
fn patches() {
    let repo_url = "https://github.com/fastrepl/fastrepl.git";
    let dest_path = temp_dir().join(nanoid!()).to_str().unwrap().to_string();
    git::clone(repo_url, &dest_path, 1).unwrap();

    let result = git::patches(&dest_path).unwrap();
    assert_eq!(result.len(), 0);

    let mut file = std::fs::File::create(dest_path.clone() + "/random.txt").unwrap();
    file.write(b"hello").unwrap();

    let mut file = std::fs::File::create(dest_path.clone() + "/README.md").unwrap();
    file.write(b"hello").unwrap();

    std::fs::remove_file(dest_path.clone() + "/.iex.exs").unwrap();

    let result = git::patches(&dest_path).unwrap();

    assert_eq!(result.len(), 3);

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

    assert_snapshot!(result.get(".iex.exs").unwrap(), @r###"
    diff --git a/.iex.exs b/.iex.exs
    deleted file mode 100644
    index 5beac86..0000000
    --- a/.iex.exs
    +++ /dev/null
    @@ -1,3 +0,0 @@
    -import Ecto.Query
    -
    -alias Fastrepl.{Repo}
    "###);
}

#[test]
fn commits() {
    let repo_url = "https://github.com/fastrepl/fastrepl.git";
    let dest_path = temp_dir().join(nanoid!()).to_str().unwrap().to_string();
    git::clone(repo_url, &dest_path, 5).unwrap();

    let result = git::commits(&dest_path).unwrap();
    assert_eq!(result.len(), 5);
}
