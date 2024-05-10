use similar::{ChangeTag, TextDiff};

pub fn readable<'a>(old: &'a str, new: &'a str) -> String {
    let diff = TextDiff::from_lines(old, new);

    let mut ret = String::new();

    for change in diff.iter_all_changes() {
        match change.tag() {
            ChangeTag::Delete => ret.push_str(&format!("-{}\n", change.value())),
            ChangeTag::Insert => ret.push_str(&format!("+{}\n", change.value())),
            ChangeTag::Equal => ret.push_str(&format!(" {}", change.value())),
        };
    }

    ret
}

pub fn unified<'a>(
    old_path: &'a str,
    new_path: &'a str,
    old_content: &'a str,
    new_content: &'a str,
) -> String {
    TextDiff::from_lines(old_content, new_content)
        .unified_diff()
        .header(old_path, new_path)
        .to_string()
}
