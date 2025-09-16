/*
Receiver and processing pipeline actors.

This module contains three cooperating actors:

- `Receiver`: receives raw message requests (from the web server
  or other producers), assigns a monotonically increasing id and
  constructs a concrete `OutboundMessage`.
- `Processor`: performs simple validation and enrichment of an
  `OutboundMessage`, producing a `ProcessedMessage` that includes
  a metadata map (e.g. `processed_at` and `gateway_key`). If
  validation fails (empty recipient) the message is dropped.
- `Router`: routes a `ProcessedMessage` to the appropriate
  gateway actor (`EmailGateway`, `SmsGateway` or `PushGateway`) by
  inspecting the message kind.

The module is intentionally small: the actors are examples of how
to structure an actor-based pipeline in Pony.
*/

use "collections"
use "time"
use "gateways"

actor Router
  let _email: EmailGateway
  let _sms: SmsGateway
  let _push: PushGateway
  new create(email: EmailGateway, sms: SmsGateway, push: PushGateway) =>
    _email = email
    _sms = sms
    _push = push

  be route(msg: ProcessedMessage) =>
    match msg.original.kind()
    | EmailKind => _email.send(msg)
    | SmsKind => _sms.send(msg)
    | PushKind => _push.send(msg)
    end

actor Processor
  let _router: Router
  new create(router: Router) =>
    _router = router

  be process(m: OutboundMessage) =>
    // Example: basic validation & enrichment
    if m.recipient().size() == 0 then
      // Drop silently or could log
      return
    end
    let meta = recover val
      let m2 = Map[String, String]
      m2("processed_at") = Time.seconds().string()
      m2("gateway_key") =
        match m.kind()
        | EmailKind => "email"
        | SmsKind => "sms"
        | PushKind => "push"
        end
      m2
    end
    let processed = ProcessedMessage(m, meta)
    _router.route(processed)

actor Receiver
  let _processor: Processor
  var _next_id: U64 = 1
  new create(p: Processor) =>
    _processor = p

  be receive(kind: MessageKind, recipient: String, body: String, subject: (String | None) = None) =>
    let id' = _next_id
    _next_id = _next_id + 1
    let msg: OutboundMessage =
      match kind
      | EmailKind =>
        let subj = match subject | let s: String => s | None => "(no subject)" end
        EmailMessage(id', recipient, body, subj)
      | SmsKind =>
        SmsMessage(id', recipient, body)
      | PushKind =>
            PushMessage(id', recipient, body)
        end
    _processor.process(msg)
