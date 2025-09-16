# pony-express

Small example Pony project demonstrating an actor-based pipeline
for handling outbound messages (email, SMS, push).

Overview of source files:

- `src/main.pony` — program entry point; wires actors and starts the
  tiny HTTP server.
- `src/common.pony` — tiny `Logger` primitive used for demo logging.
- `src/message.pony` — message domain models (`MessageKind`,
  `OutboundMessage`, `EmailMessage`, `SmsMessage`, `PushMessage`, and
  `ProcessedMessage`).
- `src/receiver.pony` — pipeline actors: `Receiver`, `Processor`,
  and `Router` responsible for validation, enrichment and routing to
  gateways.
- `src/gateways/gateway.pony` — gateway trait defining `be send(msg)`.
- `src/gateways/email_gateway.pony` — example email gateway (logs
  messages).
- `src/gateways/sms_gateway.pony` — example SMS gateway (logs
  messages).
- `src/gateways/push_gateway.pony` — push gateway placeholder (no-op).
- `src/web/server.pony` — minimal HTTP listener that accepts
  `POST /api/v1/messages/send` with tiny JSON bodies and forwards to
  `Receiver`.

Quick build & run (requires Pony compiler `ponyc`):

```bash
# from project root
ponyc -v -o build src
./build/pony-express
```

Notes & limitations:

- The HTTP and JSON parsing here are intentionally minimal and not
  safe for production use. Consider using a proper HTTP server and
  JSON parser for real applications.
- Gateways are examples: replace logging with real provider clients.
- This project is intended as a learning/demo codebase.
