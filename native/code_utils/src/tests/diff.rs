use crate::*;

use insta::assert_snapshot;

#[test]
fn readable() {
    let old = "1\n2\n3";
    let new = "1\n2\n4";

    assert_snapshot!(diff::readable(old, new), @r###"
      1
      2
    - 3
    + 4
    "###);
}

#[test]
fn unified() {
    let old = "1\n2\n3";
    let new = "1\n2\n4";

    assert_snapshot!(diff::unified(old, new), @r###"
    @@ -1,3 +1,3 @@
     1
     2
    -3
    \ No newline at end of file
    +4
    \ No newline at end of file
    "###);
}
