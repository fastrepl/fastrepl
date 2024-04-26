mod ds;
mod chunk;

#[cfg(test)]
mod tests;

rustler::init!("Elixir.Fastrepl.Native.CodeUtils", [chunk_code]);

#[rustler::nif(schedule = "DirtyCpu")]
fn chunk_code<'a>(path: &'a str, code: &str) -> Vec<ds::Chunk<'a>> {
    _chunk_code(path, code)
}

fn _chunk_code<'a>(path: &'a str, code: &str) -> Vec<ds::Chunk<'a>> {
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
        Some(language) => chunk::language_aware(path, code, &language),
        None => chunk::naive(path, code),
    }
}
