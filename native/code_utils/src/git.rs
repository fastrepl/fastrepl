use std::collections::HashMap;
use std::path::Path;

pub fn clone<'a>(repo_url: &'a str, dest_path: &'a str, depth: i32) -> anyhow::Result<()> {
    let mut fo = git2::FetchOptions::new();
    fo.depth(depth);

    let mut builder = git2::build::RepoBuilder::new();
    builder.fetch_options(fo);

    builder.clone(repo_url, Path::new(dest_path))?;
    Ok(())
}

pub fn patches<'a>(repo_root_path: &'a str) -> anyhow::Result<HashMap<String, String>> {
    let repo = git2::Repository::open(repo_root_path)?;

    let mut index = repo.index()?;
    index.add_all(["*"].iter(), git2::IndexAddOption::DEFAULT, None)?;
    index.write()?;

    let head = repo.head()?.peel_to_tree()?;
    let diff = repo.diff_tree_to_index(Some(&head), Some(&index), None)?;
    let mut patches = HashMap::new();

    for (idx, delta) in diff.deltas().enumerate() {
        if let Some(mut patch) = git2::Patch::from_diff(&diff, idx)? {
            let path = delta.new_file().path().unwrap().to_str().unwrap();

            let buf = patch.to_buf()?;
            let patch_str = std::str::from_utf8(&buf)?;

            patches.insert(path.to_string(), patch_str.to_string());
        }
    }

    Ok(patches)
}

pub fn commits<'a>(repo_root_path: &'a str) -> anyhow::Result<HashMap<String, Vec<String>>> {
    let repo = git2::Repository::open(repo_root_path)?;

    let mut ret: HashMap<String, Vec<String>> = HashMap::new();
    let mut revwalk = repo.revwalk()?;
    revwalk.push_head()?;

    let head_commit = repo.head()?.peel_to_commit()?;
    let head_tree = head_commit.tree()?;

    for oid in revwalk {
        let mut modified_files = Vec::new();

        let oid = oid?;
        let commit = repo.find_commit(oid)?;
        let tree = commit.tree()?;

        if let Ok(parent_commit) = commit.parent(0) {
            let parent_tree = parent_commit.tree()?;
            let diff = repo.diff_tree_to_tree(Some(&parent_tree), Some(&tree), None)?;

            let mut file_cb = |delta: git2::DiffDelta, _progress: f32| -> bool {
                if let Some(path) = delta.new_file().path() {
                    if let Some(name) = path.to_str() {
                        if head_tree.get_path(path).is_ok() {
                            modified_files.push(name.to_string());
                        }
                    }
                }
                true
            };

            diff.foreach(&mut file_cb, None, None, None)?;
            ret.insert(commit.id().to_string(), modified_files);
        }
    }

    Ok(ret)
}
