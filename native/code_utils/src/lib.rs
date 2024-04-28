mod chunk;
mod ds;
mod query;

#[cfg(test)]
mod tests;

rustler::init!("Elixir.Fastrepl.Native.CodeUtils", [chunk_code, grep_file]);

#[rustler::nif(schedule = "DirtyCpu")]
fn chunk_code<'a>(path: &'a str, code: &'a str) -> Vec<ds::Chunk<'a>> {
    _chunk_code(path, code)
}

fn _chunk_code<'a>(path: &'a str, code: &'a str) -> Vec<ds::Chunk<'a>> {
    let ext = path.split('.').last().unwrap_or("");
    let language = match ext {
        "js" | "mjs" | "cjs" => Some(rs_tree_sitter_languages::javascript::language()),
        "ts" | "mts" | "cts" => Some(rs_tree_sitter_languages::typescript::language()),
        "jsx" | "tsx" => Some(rs_tree_sitter_languages::tsx::language()),
        "rs" => Some(rs_tree_sitter_languages::rust::language()),
        "py" => Some(rs_tree_sitter_languages::python::language()),
        "go" => Some(rs_tree_sitter_languages::go::language()),
        "ex" | "exs" => Some(rs_tree_sitter_languages::elixir::language()),
        "erl" | "hrl" => Some(rs_tree_sitter_languages::erlang::language()),
        "pl" => Some(rs_tree_sitter_languages::perl::language()),
        "rb" => Some(rs_tree_sitter_languages::ruby::language()),
        _ => None,
    };

    match language {
        Some(language) => chunk::language_aware(path, &code, &language),
        None => chunk::naive(path, &code),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn grep_file(path: &str, pattern: &str) -> Vec<usize> {
    let reader = std::fs::File::open(path);

    match reader {
        Ok(reader) => _grep(reader, pattern),
        Err(_) => vec![],
    }
}

fn _grep<R: std::io::Read>(reader: R, pattern: &str) -> Vec<usize> {
    query::grep(reader, pattern).unwrap_or(vec![])
}
