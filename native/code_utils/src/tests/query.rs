use crate::query;

#[test]
fn simple() {
    let code = r#"
def hello():
    print("hello")

def world():
    print("world")
    print("hello")
"#;

    let result = query::ast_query(
        code,
        &rs_tree_sitter_languages::python::language(),
        "(function_definition) @function",
    );

    assert_eq!(result.len(), 2);
}
