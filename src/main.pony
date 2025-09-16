/*
Main program wiring for the example application.

This file constructs the gateways, router, processor and receiver
actors and starts a small HTTP server (see `web/server.pony`) that
accepts POST requests to create messages. It also contains a small
demo sequence that sends a few example messages to exercise the
pipeline.

This file is an executable entry point when compiled as a Pony
program; it intentionally performs only wiring and demos — the
application logic lives in other modules (`receiver.pony`,
`message.pony`, and the `gateways/` actors).
*/

use "gateways"
use "web"

actor Main
    new create(env: Env) =>
        let email = EmailGateway
        let sms = SmsGateway
        let push = PushGateway
        let router = Router(email, sms, push)
        let processor = Processor(router)
        let receiver = Receiver(processor)

        // Start web server
        let web_server = WebServer(env.root, receiver, "8080")
        env.out.print("Web server started on port 8080")
        env.out.print("POST /api/v1/messages/send to send messages")

        // Demo traffic
        receiver.receive(EmailKind, "alice@example.com", "Welcome aboard!", "Hello Alice")
        receiver.receive(SmsKind, "+1555123456", "Code 123456")
        receiver.receive(PushKind, "device:xyz", "You have a new notification")
        receiver.receive(EmailKind, "", "Will be dropped", "No recipient") // invalid
