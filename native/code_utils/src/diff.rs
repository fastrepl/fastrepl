use similar::Algorithm::Patience;
use similar::TextDiff;

pub fn unified<'a>(
    old_path: &'a str,
    new_path: &'a str,
    old_content: &'a str,
    new_content: &'a str,
) -> String {
    TextDiff::configure()
        .algorithm(Patience)
        .diff_lines(old_content, new_content)
        .unified_diff()
        .header(old_path, new_path)
        .to_string()
}
