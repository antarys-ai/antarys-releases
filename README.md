# Antarys

This repo is dedicated to host antarys beta binary releases until we are going production ready.

This will also act as a starter guide to get started with antarys and how to use it.

Download Antarys for [Apple Silicon](https://github.com/antarys-ai/antarys-releases/releases/download/beta-mac-arm/antarys-apple-silicon.zip) and
for [Linux x64](https://github.com/antarys-ai/antarys-releases/releases/download/beta-linux-amd64/antarys.zip) here.

We will be creating more builds to support more platforms and architectures!

After downloading the antarys binary for your respective platform, you can get started with the following command

```bash
./antarys --port=8080
```

For more advance configuration you can pass the following parameters


```
--port=8080                     #API server port
--data-dir=./data               #Path to data directory
--enable-gpu=false              #Enable GPU acceleration
--shards=16                     #Number of data shards
--query-threads=NUM_CPUx2       #Number of query threads
--commit-interval=60            #Auto-commit interval in seconds
--cache-size=10000              #Size of result cache
--enable-hnsw=true              #Enable HNSW indexing
--enable-pq=false               #Enable Product Quantization
--optimization=3                #Optimization level (0-3)
--max-results=100               #Default maximum results
--batch-size=5000               #Default batch size
--similarity=0.7                #Default similarity threshold
--meta-dir=./metadata           #Path to metadata storage
```

## Clients

For now we have only released a [python client](https://pypi.org/project/antarys/) which can be installed via

```bash
pip install antarys
```

our python client uses asyncio heavily for performance and handling vector operations with threading turned on by default

```python
import asyncio
from antarys import Client


async def main():
    # Initialize client with performance optimizations
    client = Client(
        host="http://localhost:8080",
        connection_pool_size=100,  # Auto-sized based on CPU count
        use_http2=True,
        cache_size=1000,
        thread_pool_size=16
    )

    # Create collection
    await client.create_collection(
        name="my_vectors",
        dimensions=1536,
        enable_hnsw=True,
        shards=16
    )

    vectors = client.vector_operations("my_vectors")

    # Upsert vectors
    await vectors.upsert([
        {"id": "1", "values": [0.1] * 1536, "metadata": {"category": "A"}},
        {"id": "2", "values": [0.2] * 1536, "metadata": {"category": "B"}}
    ])

    # Query similar vectors
    results = await vectors.query(
        vector=[0.1] * 1536,
        top_k=10,
        include_metadata=True
    )

    await client.close()


asyncio.run(main())
```

> the python client needs http2 to work, install via `pip3 install httpx[http2]`

We are working to release gRPC support to our datbase and python client as the immediate feature!

We are extensively working to bring client SDKS for the following platforms
* go (Antarys native + REST API + gRPC)
* node.js (REST API + gRPC)
* JVM (REST API + gRPC)
* .NET (REST API + gRPC)
* C/C++ (REST API + gRPC)
* zig (REST API + gRPC)
* rust (REST API + gRPC)

## Benchmarks

For the benchmarks shown below, we used this command

```bash
./antarys \
  --port=8080 \
  --data-dir=./data \
  --enable-gpu=false \
  --shards=16 \
  --query-threads=8 \
  --commit-interval=60 \
  --cache-size=10000 \
  --enable-hnsw=true \
  --optimization=3 \
  --meta-dir=./metadata \
  --enable-pq=true
```

The following result is generated using our python client with the help of dbpedia 1M vector dataset from huggingface,
the benchmarking script can be [found here](https://github.com/antarys-ai/antarys-samples/blob/main/dbpedia/benchmark.py)

```
WRITE PERFORMANCE (batch size 1000)
- Total points inserted: 100000
- Successful batches: 100
- Average batch time: 0.4957s
- Throughput: 2017.54 vectors/sec
- Percentiles: P50=0.4910s, P90=0.5208s, P99=0.5703s

READ PERFORMANCE (100 queries)
- Successful queries: 100
- Average query time: 0.0014s
- Throughput: 692.61 queries/sec
- Percentiles: P50=0.0013s, P90=0.0014s, P99=0.0069s

READ PERFORMANCE (1000 queries)
- Successful queries: 1000
- Average query time: 0.0025s
- Throughput: 395.38 queries/sec
- Percentiles: P50=0.0000s, P90=0.0000s, P99=0.0001s


SUMMARY
======================================================================
Best write performance: 2017.54 vectors/sec (batch size 1000)
Best read performance: 692.61 queries/sec (100 queries)
```

For a similar test we are recording the following performance for Qdrant

```
WRITE PERFORMANCE (batch size 1000)
- Total points inserted: 100000
- Successful batches: 100
- Average batch time: 0.9631s
- Throughput: 1038.31 vectors/sec
- Percentiles: P50=0.9542s, P90=1.0083s, P99=1.0496s

READ PERFORMANCE (100 queries)
- Successful queries: 100
- Average query time: 0.0417s
- Throughput: 23.99 queries/sec
- Percentiles: P50=0.0325s, P90=0.0559s, P99=0.0916s

READ PERFORMANCE (1000 queries)
- Successful queries: 1000
- Average query time: 0.0359s
- Throughput: 27.88 queries/sec
- Percentiles: P50=0.0328s, P90=0.0550s, P99=0.0564s


SUMMARY
======================================================================
Best write performance: 1038.31 vectors/sec (batch size 1000)
Best read performance: 27.88 queries/sec (1000 queries)
```

Both of these tests have been ran on Apple M1 Pro, similar results have been found on an intel machine.

## Image Query

We have an image [similarity searching sample](https://github.com/antarys-ai/antarys-samples/tree/main/image_similarity)

We have measured the performance of Qdrant and Antarys for comparing. This test was inspired from the milvus image similarity test,
which can be [found here](https://milvus.io/docs/image_similarity_search.md)

Here are the results

### For Qdrant
![Qdrant Image Search](./qdrant_image_search.png)

### For Milvus
![Milvus Image Search](./milvus_image_search.png)

### For Antarys
![Antarys Image Search](./antarys_image_search.png)

## Image search results

```
Qdrant Query Time  ->  0.0497 Seconds
Milvus Query Time  ->  0.0417 Seconds
Antarys Query Time ->  0.0024 Seconds

Almost a 20x query time bump
```

## AHNSW

Unlike tradtional sequential HNSW, we are using a different asynchronous approach to HNSW and eliminating thread locks with the help of
architectural fine tuning. We will soon release more technical details on the Async HNSW algorithmic approach.
