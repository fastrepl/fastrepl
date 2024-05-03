use std::collections::HashMap;

const MAX_COMMITS: usize = 300;
const TOP_K: usize = 1;

pub fn find_top_cocommitted_files(repo_path: &str, file_path: &str) -> anyhow::Result<Vec<String>> {
    let repo = git2::Repository::open(repo_path)?;

    let mut file_map: HashMap<String, HashMap<String, usize>> = HashMap::new();
    let mut revwalk = repo.revwalk()?;
    revwalk.push_head()?;

    let head_commit = repo.head()?.peel_to_commit()?;
    let head_tree = head_commit.tree()?;

    let mut commit_count = 0;
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

            for file in &modified_files {
                let entry = file_map.entry(file.clone()).or_insert_with(HashMap::new);
                for other_file in &modified_files {
                    if file != other_file {
                        *entry.entry(other_file.clone()).or_insert(0) += 1;
                    }
                }
            }
        }

        commit_count += 1;
        if commit_count >= MAX_COMMITS {
            break;
        }
    }

    match file_map.get(file_path) {
        Some(pairs) => {
            let mut sorted_pairs: Vec<(String, usize)> = pairs
                .iter()
                .map(|(file, &count)| (file.clone(), count))
                .collect();
            sorted_pairs.sort_by(|a, b| b.1.cmp(&a.1));

            let top_files: Vec<String> = sorted_pairs
                .into_iter()
                .take(TOP_K)
                .map(|(file, _)| file)
                .collect();

            Ok(top_files)
        }
        None => Ok(vec![]),
    }
}
