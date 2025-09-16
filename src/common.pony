/*
Common utilities used across the project.

This module provides a tiny `Logger` primitive used by the
example gateways and main program to print simple log messages to
stdout. The logger is intentionally minimal and synchronous to keep
the example focused on Pony actors and message routing.

Public API:
- `Logger.print(message: String)`: print a single-line message
    (adds a trailing newline).
*/

use @printf[I32](fmt: Pointer[U8] tag, ...)

primitive Logger
        fun print(message: String) =>
                @printf("%s\n".cstring(), message.cstring())
