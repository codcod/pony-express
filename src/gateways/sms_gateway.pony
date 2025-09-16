/*
Simple SMS gateway implementation.

This gateway logs SMS deliveries. Replace with a real SMS API
integration to send messages in production.
*/

use "collections"
use ".."

actor SmsGateway is Gateway
    be send(msg: ProcessedMessage) =>
        try
            let sm = msg.original as SmsMessage
            Logger.print("[SMS] to=" + sm.recipient() +
                " body=" + sm.body())
        end
