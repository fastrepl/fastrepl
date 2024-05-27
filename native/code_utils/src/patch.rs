pub fn create<'a>(
    old_path: &'a str,
    new_path: &'a str,
    old_content: &'a str,
    new_content: &'a str,
) -> String {
    let patch = diffy::create_patch(old_content, new_content).to_string();

    patch.replacen(
        "--- original\n+++ modified\n",
        &format!("--- {}\n+++ {}\n", old_path, new_path),
        1,
    )
}

pub fn apply<'a>(base_content: &'a str, patch_content: &'a str) -> String {
    let patch = diffy::Patch::from_str(patch_content).unwrap();
    diffy::apply(&base_content, &patch).unwrap()
}
