use similar::{ChangeTag, TextDiff};

pub fn readable<'a>(old: &'a str, new: &'a str) -> String {
    let diff = TextDiff::from_lines(old, new);

    let mut ret = String::new();

    for change in diff.iter_all_changes() {
        match change.tag() {
            ChangeTag::Delete => ret.push_str(&format!("- {}\n", change.value())),
            ChangeTag::Insert => ret.push_str(&format!("+ {}\n", change.value())),
            ChangeTag::Equal => ret.push_str(&format!("  {}", change.value())),
        };
    }

    ret
}

pub fn unified<'a>(old: &'a str, new: &'a str) -> String {
    TextDiff::from_lines(old, new).unified_diff().to_string()
}
