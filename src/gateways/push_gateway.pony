/*
Push notification gateway (no-op example).

The example Push gateway is currently a no-op and intentionally
comments out logging; it's a placeholder where real push
notification service integration would be implemented.
*/

use "collections"
use ".."

actor PushGateway is Gateway
    be send(msg: ProcessedMessage) =>
        try
            let pm = msg.original as PushMessage
            // Logger.print("[PUSH] to=" + pm.recipient() +
            //    " body=" + pm.body())
        end
