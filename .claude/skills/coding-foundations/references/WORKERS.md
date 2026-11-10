# Workers guide (web workers, worker threads, job queues)

Read when a ticket has CPU-heavy or long-running work. With: the stack guide and PERFORMANCE.md. Use a worker because a measurement shows the main thread or the event loop is blocked, not by default: a worker adds complexity.

## 1. Which tool
| Situation | Use |
|---|---|
| Browser work over about 50 ms that would freeze the UI (parsing or transforming large data, search over a big list, image or file processing, encryption) | **Web Worker** |
| Server CPU-bound work that must answer within the request (hashing, compression, image resize, heavy parsing) | **Worker threads** (or the runtime's equivalent thread/process pool) |
| Work that takes more than a few seconds, must survive a crash, needs retries or runs on a schedule | **A durable job queue** with separate worker processes (ARCHITECTURE L7) |
| Waiting on I/O (database, HTTP, files) | **Nothing special:** async I/O is already non-blocking. A thread doesn't make it faster |

## 2. Rules for both kinds of worker (must)
- **A typed message protocol:** every message has a `type`, a request `id` and a payload; responses echo the `id` and carry either a result or an error. Define the types once and share them between both sides.
- **Never share mutable state.** Send copies, or transfer ownership of large binary buffers (transferables) instead of copying them. Shared memory is used only with an ADR.
- **Handle failure:** listen for error and exit events, reject the pending request, restart the worker, and report the error. A crashed worker never leaves a request waiting forever.
- **Timeouts and cancellation:** every request has a deadline; a cancelled or superseded request tells the worker to stop (or the result is discarded).
- **Report progress** for work longer than about a second, so the UI or the caller can show it.
- **Clean up:** terminate workers that are no longer needed; on shutdown, finish or hand back in-flight work within the deadline.
- Validate what goes into a worker like any other input: a worker is not a trust boundary.

## 3. Browser web workers
- Create workers through the bundler's module-worker support so they are code-split and typed.
- Keep one worker (or a small pool) alive for repeated work; don't create one per call.
- Workers have no DOM access: return data, and let the component render it.
- Wrap the worker in a hook, composable or service that hides the messaging and cleans up on unmount.
- Chunk very large inputs and yield between chunks so cancellation stays responsive.

## 4. Server worker threads
- **Use a pool,** never a new thread per request. Size it from the available cores (leave one for the event loop) and the memory each task needs. Use a maintained pool library rather than writing one.
- **Bound the queue:** when the pool is saturated, apply backpressure or return a "busy" error; an unbounded queue becomes an outage.
- Set resource limits (memory, time) per worker; recycle a worker after a number of tasks if the work can leak.
- Pass only serializable data; open connections and file handles inside the worker that uses them.
- Log with the request id; export metrics for queue length, wait time, task time and failures.

## 5. Durable jobs (when it must not be lost)
Idempotent handlers (a job can run twice), bounded retries with backoff, a dead-letter queue with an alert, a visibility timeout longer than the job, and the outbox pattern when a job is enqueued together with a database change. Details: the stack guide and ARCHITECTURE L7.

## 6. Testing
- Test the pure function the worker runs on its own (most of the logic).
- Test the wrapper: a result resolves the right request, an error rejects it, a timeout fires, cancel stops the work, a crashed worker is replaced.
- Measure before and after: the reason for the worker is a number (main-thread long task, event-loop delay, p95) that must improve.

## Review checklist
- [ ] A measurement justifies the worker, and the right tool was chosen (web worker, thread pool, or durable job).
- [ ] Typed protocol with request ids; errors, exits, timeouts and cancellation handled.
- [ ] No shared mutable state; large buffers transferred, not copied.
- [ ] Browser: one long-lived worker or small pool, cleaned up on unmount.
- [ ] Server: a bounded pool sized from cores and memory; backpressure when saturated; metrics exported.
- [ ] Work that must survive a crash is a durable, idempotent job, not an in-memory thread task.
