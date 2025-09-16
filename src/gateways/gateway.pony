/*
Gateway interface for delivering processed messages.

Each concrete gateway implements `be send(msg: ProcessedMessage)`
and is expected to handle delivery for a specific `MessageKind`.
The `Router` sends `ProcessedMessage` values to gateways.
*/

use "collections"
use ".."

trait Gateway
  be send(msg: ProcessedMessage)
