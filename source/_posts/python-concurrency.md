---
title: Python Concurrency Explained With Network Requests
date: 2026-02-08 13:30:11
tags:
    - Python
    - Concurrency
    - asyncio
    - threading
categories:
    - Guides
---

If you've ever written a script that makes a bunch of HTTP requests one at a time and thought "this is painfully slow," this post is for you.

We're going to take a slow, synchronous script and make it fast using Python's `asyncio` and `threading`, and talk about when to reach for each.

## Scenario

Let's say you need to fetch data from 10 different URLs. One naive approach might look like this:

```python
import requests
import time

urls = [f"https://httpbin.org/delay/1" for _ in range(10)]

start = time.time()

for url in urls:
    response = requests.get(url)
    print(f"Status: {response.status_code}")

print(f"Total time: {time.time() - start:.2f}s")
```

Each request takes about 1 second because the endpoint simulates a 1-second delay. We have 10 requests, so this takes roughly **10 seconds**.

While we're waiting for a response from the server, our program is doing absolutely nothing until bytes arrive over the network. Then it moves to the next request and waits for information again. 

## Concurrency to Save the Day

Concurrency doesn't mean doing things "at the same time" on multiple CPU cores (that's parallelism). Concurrency means **managing multiple tasks that are in progress at once**.

Concurrency is great for network requests because the "slow part" is waiting for a remote server to respond — not doing computation on your CPU. 

## The Fix: asyncio + aiohttp

Python's `asyncio` module lets us write concurrent code using `async`/`await`. Combined with `aiohttp` (an async HTTP library), we can fire off all 10 requests without waiting for each one to finish:

```python
import asyncio
import aiohttp
import time

urls = [f"https://httpbin.org/delay/1" for _ in range(10)]

async def fetch(session, url):
    async with session.get(url) as response:
        print(f"Status: {response.status}")
        return response.status

async def main():
    async with aiohttp.ClientSession() as session:
        tasks = [fetch(session, url) for url in urls]
        await asyncio.gather(*tasks)

start = time.time()
asyncio.run(main())
print(f"Total time: {time.time() - start:.2f}s")
```

This finishes in roughly **1 second** instead of 10. Same 10 requests, ~10x faster.

## What's Happening Under the Hood

Let's walk through this step by step:

1. `asyncio.run(main())` starts the **event loop** — this is the "waiter" from our restaurant analogy.

2. We create a list of `tasks`, one for each URL. Each task is a call to `fetch()` that hasn't started yet.

3. `asyncio.gather(*tasks)` tells the event loop: "start all of these and let me know when they're all done."

4. The event loop starts the first request. When it hits `session.get(url)`, instead of blocking, it says "I'll come back when the network responds" and **moves on to start the next request**.

5. It does this for all 10 requests. Now all 10 are "in flight" simultaneously.

6. As responses come back, the event loop picks up each one right where it left off (the line after `await`) and finishes processing it.

The key insight: **`await` is not `time.sleep()`.** When you `await` something, you're telling the event loop "I'm waiting on I/O, go do something else in the meantime." That's what makes it concurrent.

## The Other Option: Threading

`asyncio` isn't the only way to do this. Python's `threading` module can solve the same problem, and you don't need to change your HTTP library:

```python
import requests
import time
from concurrent.futures import ThreadPoolExecutor

urls = [f"https://httpbin.org/delay/1" for _ in range(10)]

def fetch(url):
    response = requests.get(url)
    print(f"Status: {response.status_code}")
    return response.status_code

start = time.time()

with ThreadPoolExecutor(max_workers=10) as executor:
    results = list(executor.map(fetch, urls))

print(f"Total time: {time.time() - start:.2f}s")
```

This also finishes in roughly **1 second**. Each thread runs `requests.get()` and blocks — but since they're separate threads, the OS can switch between them while they wait on I/O. The `concurrent.futures` module gives us `ThreadPoolExecutor`, which manages a pool of threads and distributes work across them.

## Threading vs asyncio

Both solve the same problem here, so which should you use?

**Threading** is simpler when you're retrofitting existing synchronous code. You keep using `requests`, `psycopg2`, or whatever blocking library you already have. Just wrap the calls in a thread pool and you're done. The mental model is straightforward: each thread runs your normal code, and the OS handles the switching.

**asyncio** scales better. Threads have real overhead — each one consumes memory for its stack, and the OS scheduler has to manage context switches between them. If you're making 10 requests, this doesn't matter. If you're making 10,000, threading starts to struggle while asyncio handles it comfortably because coroutines are much lighter than OS threads.

The tradeoff in practice:

- **Threading**: works with any existing library, easier to reason about, fine for moderate concurrency (dozens to low hundreds of tasks)
- **asyncio**: requires async-compatible libraries (`aiohttp` instead of `requests`), but handles massive concurrency with less overhead

There's also the GIL to consider. Python's Global Interpreter Lock means threads can't run Python code in true parallel — but this doesn't matter for I/O-bound work because threads release the GIL while waiting on network/disk operations. The GIL only becomes a problem for CPU-bound threading, which is why `multiprocessing` exists.

## When to Use This (and When Not To)

**Use asyncio for I/O-bound work:**
- HTTP requests (APIs, web scraping)
- Database queries
- File reads/writes
- Anything where your code spends most of its time *waiting*

**Don't use asyncio for CPU-bound work:**
- Number crunching, image processing, data transformation
- If your code is slow because the CPU is busy computing, concurrency won't help — you need `multiprocessing` for true parallelism across cores

A quick rule of thumb: if you can make your program faster by getting a faster internet connection, it's I/O-bound. If you need a faster CPU, it's CPU-bound.

## Gotchas

A few things that trip people up:

- **You can't mix `requests` with `asyncio` easily.** The `requests` library is synchronous and will block the event loop. Use `aiohttp` instead, or wrap synchronous calls with `asyncio.to_thread()`.
- **`asyncio.run()` can only be called once.** It creates and destroys an event loop. If you're inside a framework that already has a loop (like FastAPI), just `await` directly.
- **Error handling works normally.** Wrap your `await` calls in try/except just like synchronous code.
- **Threads and shared state don't mix well.** If your threads write to the same data structure, you'll need locks. asyncio avoids this entirely because only one coroutine runs at a time within the event loop.
- **Don't create unlimited threads.** Always use a pool (`ThreadPoolExecutor`) instead of spawning a thread per task. Thousands of threads will eat your memory and slow things down.

## Summary

| | Synchronous | Threading | asyncio |
|---|---|---|---|
| 10 requests @ 1s each | ~10 seconds | ~1 second | ~1 second |
| How it works | One at a time, blocking | Multiple OS threads, blocking per thread | Single thread, non-blocking event loop |
| Existing library support | Everything | Everything | Needs async libraries |
| Good for | Simple scripts | Moderate concurrency, retrofitting sync code | High concurrency, greenfield async code |


## Resources

- [asyncio docs](https://docs.python.org/3/library/asyncio.html)
- [aiohttp docs](https://docs.aiohttp.org/)
- [Real Python: Async IO in Python](https://realpython.com/async-io-python/)
