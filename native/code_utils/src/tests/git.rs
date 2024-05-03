use crate::git;
use std::env::temp_dir;

#[test]
fn it_works() {
    let url = "https://github.com/fastrepl/fastrepl.git";
    let file_path = "lib/fastrepl/tokenizer.ex";
    let file_test_path = "test/fastrepl/tokenizer_test.exs";

    let repo_path = temp_dir().join("fastrepl");
    if repo_path.exists() {
        std::fs::remove_dir_all(&repo_path).unwrap();
    }
    let repo = git2::Repository::clone(url, &repo_path).unwrap();

    let paths = git::find_top_cocommitted_files(repo.path().to_str().unwrap(), file_path).unwrap();
    assert_eq!(paths.len(), 1);
    assert!(paths.contains(&file_test_path.to_string()));
}
