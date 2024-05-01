use crate::*;

use include_uri::include_str_from_url;
use insta::assert_debug_snapshot;

#[test]
fn class() {
    let code = include_str_from_url!(
        "https://raw.githubusercontent.com/BerriAI/litellm/9f55a99e98de762e853129ba92cb1b038e963187/litellm/router.py"
    );

    let result = _chunk_code("router.py", code);
    assert_debug_snapshot!(result);
}
