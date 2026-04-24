# TEI Addon

[HuggingFace text-embeddings-inference](https://github.com/huggingface/text-embeddings-inference)
as a sidecar embedder for APE. Purpose-built Rust server for embedding models,
OpenAI-compatible `/v1/embeddings` endpoint, dynamic batching, ONNX and
SafeTensors support.

APE does not run embedders in-process. Any OpenAI-compatible embedder URL
works — TEI is the recommended default because it loads HF-format ONNX
directories unmodified.

## Layout

```
MODEL_DIR/
  model.onnx (or *.safetensors)
  tokenizer.json
  tokenizer_config.json
  config.json
  special_tokens_map.json
```

This is the same directory `glyph-embedder-v1` exports to.

## Dev

```
MODEL_DIR=/path/to/glyph-embedder-v1/onnx \
  docker compose -f addons/tei/docker-compose.tei.yml up -d
```

TEI listens on `localhost:8080`. Point APE at it via `ape.toml`:

```toml
[concept_spaces.default.embedder]
type = "api"
url = "http://tei:80/v1/embeddings"   # same docker network
model = "glyph-embedder-v1"
dimension = 384
```

Or, from the host:

```toml
url = "http://localhost:8080/v1/embeddings"
```

## Prod

`docker-compose.tei.prod.yml` enables CUDA. Drop the `deploy:` block and
switch the image tag to `cpu-latest` for CPU-only hosts.

## Alternatives

TEI is one option. APE doesn't care what's behind the URL as long as it
speaks OpenAI `/v1/embeddings`:

- **Infinity** — similar scope, broader model coverage, Python.
- **LM Studio** / **Ollama** — if you converted the model to GGUF.
- **Hosted** (OpenAI, Cohere, Voyage, Jina) — set `api_key_env` on the
  `api`-type embedder config.
