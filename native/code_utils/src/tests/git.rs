use crate::git;

use nanoid::nanoid;
use std::{env::temp_dir, io::Write};

#[test]
fn clone() {
    let repo_url = "https://github.com/fastrepl/fastrepl.git";
    let dest_path = temp_dir().join(nanoid!()).to_str().unwrap().to_string();
    git::clone(repo_url, &dest_path, 1).unwrap();
}

#[test]
fn patch() {
    let repo_url = "https://github.com/fastrepl/fastrepl.git";
    let dest_path = temp_dir().join(nanoid!()).to_str().unwrap().to_string();
    git::clone(repo_url, &dest_path, 1).unwrap();

    let result = git::patches(&dest_path).unwrap();
    assert_eq!(result.len(), 0);

    let mut file = std::fs::File::create(dest_path.clone() + "/random.txt").unwrap();
    file.write(b"hello").unwrap();

    let mut file = std::fs::File::create(dest_path.clone() + "/README.md").unwrap();
    file.write(b"hello").unwrap();

    let result = git::patch(&dest_path).unwrap();
    assert_eq!(result.split("diff --git").count(), 2 + 1);
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

    let result = git::patches(&dest_path).unwrap();

    assert_eq!(result.len(), 1 + 1);
    assert!(result.contains_key("random.txt"));
    assert!(result.contains_key("README.md"));
    assert!(result.get("random.txt").unwrap().contains("diff --git"));
    assert!(result.get("README.md").unwrap().contains("diff --git"));
}

#[test]
fn commits() {
    let repo_url = "https://github.com/fastrepl/fastrepl.git";
    let dest_path = temp_dir().join(nanoid!()).to_str().unwrap().to_string();
    git::clone(repo_url, &dest_path, 5).unwrap();

    let result = git::commits(&dest_path).unwrap();
    assert_eq!(result.len(), 5 - 1);
}
