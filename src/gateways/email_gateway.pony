/*
Simple Email gateway implementation.

For the purposes of this example the gateway simply logs an email
message using `Logger.print`. In a real system this would interface
with an SMTP client or external email provider.
*/

use "collections"
use ".."

actor EmailGateway is Gateway
    be send(msg: ProcessedMessage) =>
        try
            let em = msg.original as EmailMessage
            Logger.print("[EMAIL] to=" + em.recipient() +
                " subject=" + em.subject() +
                " body=" + em.body())
        end
