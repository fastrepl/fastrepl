use crate::lexical;

#[test]
fn simple() {
    let root = tempfile::tempdir().unwrap().into_path();

    std::fs::write(
        root.join("variables.py"),
        "a = 1\nb = 2\nc = 3\nd = 4\ne = 5\nf = 6\n",
    )
    .unwrap();
    std::fs::write(
        root.join("hello1.py"),
        "def hello():\n    print(\"hello\")\n",
    )
    .unwrap();

    std::fs::write(
        root.join("hello2.py"),
        "def hello():\n    print(\"hello\")\n",
    )
    .unwrap();

    let index_path = lexical::index(root.to_str().unwrap()).unwrap();
    let ret = lexical::search(&index_path, "hello():").unwrap();

    assert_eq!(ret.len(), 2);
    assert_eq!(ret[0].content, "def hello():\n    print(\"hello\")\n");
    assert_eq!(ret[1].content, "def hello():\n    print(\"hello\")\n");
}

#[test]
fn code_tokenizer() {
    let mut tok = lexical::code_tokenizer();
    let mut stream = tok.token_stream("def hello():\n    print(\"hello\")\n");

    let mut tokens = vec![];
    while let Some(token) = stream.next() {
        tokens.push(token.text.to_string());
    }

    assert_eq!(tokens, ["def", "hello():", "print(\"hello\")"]);
}

#[test]
fn path_tokenizer() {
    let mut tok = lexical::path_tokenizer();
    let mut stream = tok.token_stream("/a/b/c.py");

    let mut tokens = vec![];
    while let Some(token) = stream.next() {
        tokens.push(token.text.to_string());
    }

    assert_eq!(tokens, ["a", "b", "c.py"]);
}
