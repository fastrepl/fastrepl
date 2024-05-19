use tantivy::collector::TopDocs;
use tantivy::query::QueryParser;
use tantivy::schema::{IndexRecordOption, Schema, TantivyDocument, TextFieldIndexing, TextOptions};
use tantivy::tokenizer::*;
use tantivy::Document;
use tantivy::{Index, IndexWriter, ReloadPolicy};

use crate::ds::{RetrievedDocument, File};

const CODE_TOKENIZER: &str = "code_tokenizer";
const PATH_TOKENIZER: &str = "path_tokenizer";

const CODE_FIELD: &str = "content";
const PATH_FIELD: &str = "path";

pub fn code_tokenizer() -> TextAnalyzer {
    TextAnalyzer::builder(WhitespaceTokenizer::default())
        .filter(LowerCaser)
        .build()
}

pub fn path_tokenizer() -> TextAnalyzer {
    TextAnalyzer::builder(RegexTokenizer::new(r"[^/]+").unwrap())
        .filter(LowerCaser)
        .build()
}

fn build_schema() -> Schema {
    let mut schema_builder = Schema::builder();

    let path_field_indexing = TextFieldIndexing::default()
        .set_tokenizer(PATH_TOKENIZER)
        .set_index_option(IndexRecordOption::WithFreqs);
    let path_field_option = TextOptions::default()
        .set_indexing_options(path_field_indexing)
        .set_stored();

    let code_field_indexing = TextFieldIndexing::default()
        .set_tokenizer(CODE_TOKENIZER)
        .set_index_option(IndexRecordOption::WithFreqsAndPositions);
    let code_field_option = TextOptions::default()
        .set_indexing_options(code_field_indexing)
        .set_stored();

    schema_builder.add_text_field(PATH_FIELD, path_field_option);
    schema_builder.add_text_field(CODE_FIELD, code_field_option);
    schema_builder.build()
}

pub fn index(path: &str) -> anyhow::Result<String> {
    let index_path = format!("{}-index", path);
    if std::path::Path::new(&index_path).exists() {
        return Ok(index_path);
    }

    std::fs::create_dir_all(index_path.clone())?;

    let schema = build_schema();
    let path_field = schema.get_field(PATH_FIELD)?;
    let code_field = schema.get_field(CODE_FIELD)?;

    let index = Index::create_in_dir(index_path.clone(), schema)?;
    index
        .tokenizers()
        .register(CODE_TOKENIZER, code_tokenizer());
    index
        .tokenizers()
        .register(PATH_TOKENIZER, path_tokenizer());

    let mut index_writer: IndexWriter = index.writer(50_000_000)?;

    for entry in std::fs::read_dir(path)? {
        let entry = entry?;
        let path = entry.path();

        let file_content = std::fs::read_to_string(path.clone())?;

        let mut doc = TantivyDocument::default();
        doc.add_text(path_field, path.to_str().unwrap());
        doc.add_text(code_field, file_content);
        index_writer.add_document(doc)?;
    }

    index_writer.commit()?;

    Ok(index_path)
}

pub fn search(index_path: &str, query: &str) -> anyhow::Result<Vec<File>> {
    let index = Index::open_in_dir(index_path)?;
    index
        .tokenizers()
        .register(CODE_TOKENIZER, code_tokenizer());
    index
        .tokenizers()
        .register(PATH_TOKENIZER, path_tokenizer());

    let reader = index
        .reader_builder()
        .reload_policy(ReloadPolicy::Manual)
        .try_into()?;

    let searcher = reader.searcher();

    let schema = build_schema();
    let fields = schema.fields().map(|(f, _)| f).collect();
    let query_parser = QueryParser::for_index(&index, fields);

    let query = query_parser.parse_query(&format!("\"{}\"", query))?;
    let top_docs = searcher.search(&query, &TopDocs::with_limit(10))?;

    let mut ret = vec![];

    for (_score, doc_address) in top_docs {
        let retrieved_doc: TantivyDocument = searcher.doc(doc_address)?;
        let retrieved_doc = serde_json::from_str::<RetrievedDocument>(&retrieved_doc.to_json(&schema))?;

        ret.push(File {
            path: retrieved_doc.path[0].clone(),
            content: retrieved_doc.content[0].clone()
        });
    }

    return Ok(ret);
}
