use std::collections::HashMap;

mod git;

#[cfg(test)]
mod tests;

rustler::init!("Elixir.Fastrepl.Native.GitUtils", [clone, patch, patches, commits]);

#[rustler::nif]
fn clone<'a>(repo_url: &'a str, dest_path: &'a str, depth: i32) -> bool {
    match git::clone(repo_url, dest_path, depth) {
        Ok(_) => true,
        Err(_) => false,
    }
}

#[rustler::nif]
fn patch<'a>(repo_root_path: &'a str) -> String {
    git::patch(repo_root_path).unwrap_or_default()
}

#[rustler::nif]
fn patches<'a>(repo_root_path: &'a str) -> HashMap<String, String> {
    git::patches(repo_root_path).unwrap_or_default()
}

#[rustler::nif]
fn commits<'a>(repo_root_path: &'a str) -> HashMap<String, Vec<String>> {
    git::commits(repo_root_path).unwrap_or_default()
}
