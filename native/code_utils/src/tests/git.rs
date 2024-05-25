use crate::git;

use nanoid::nanoid;
use std::{env::temp_dir, io::Write};

use insta::assert_snapshot;

#[test]
fn clone() {
    let repo_url = "https://github.com/fastrepl/fastrepl.git";
    let dest_path = temp_dir().join(nanoid!()).to_str().unwrap().to_string();

    git::clone_commit(
        repo_url,
        &dest_path,
        "048621d82171d930eec6c8cda41b164eff424c6b",
    )
    .unwrap();
}

#[test]
fn patches() {
    let repo_url = "https://github.com/fastrepl/fastrepl.git";
    let dest_path = temp_dir().join(nanoid!()).to_str().unwrap().to_string();
    git::clone_depth(repo_url, &dest_path, 1).unwrap();

    let result = git::patches(&dest_path).unwrap();
    assert_eq!(result.len(), 0);

    let mut file = std::fs::File::create(dest_path.clone() + "/random.txt").unwrap();
    file.write(b"hello").unwrap();

    let mut file = std::fs::File::create(dest_path.clone() + "/debug.sh").unwrap();
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

    assert_snapshot!(result.get("debug.sh").unwrap(), @r###"
    diff --git a/debug.sh b/debug.sh
    index 418602b..b6fc4c6 100644
    --- a/debug.sh
    +++ b/debug.sh
    @@ -1,5 +1 @@
    -#!/bin/bash
    -
    -set -e
    -
    -fly ssh console --pty --select -C "/app/bin/fastrepl remote"
    +hello
    \ No newline at end of file
    "###);

    assert_snapshot!(result.get(".iex.exs").unwrap(), @r###"
    diff --git a/.iex.exs b/.iex.exs
    deleted file mode 100644
    index 3860f7d..0000000
    --- a/.iex.exs
    +++ /dev/null
    @@ -1,9 +0,0 @@
    -import Ecto.Query
    -alias Fastrepl.Repo
    -
    -alias Identity.User
    -alias Fastrepl.Accounts.Member
    -alias Fastrepl.Accounts.Account
    -alias Fastrepl.Billings.Billing
    -
    -alias Fastrepl.Github
    "###);
}

#[test]
fn commits() {
    let repo_url = "https://github.com/fastrepl/fastrepl.git";
    let dest_path = temp_dir().join(nanoid!()).to_str().unwrap().to_string();
    git::clone_depth(repo_url, &dest_path, 5).unwrap();

    let result = git::commits(&dest_path).unwrap();
    assert_eq!(result.len(), 4);
}
