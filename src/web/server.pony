/*
Minimal HTTP server that accepts POST requests to create messages.

This module exposes `WebServer` which listens on a TCP port and
accepts simple HTTP requests. It recognizes `POST /api/v1/messages/send`
with a tiny JSON body (fields `type`, `recipient`, `body` and
optional `subject`) and forwards them to a provided `Receiver`.

This is a deliberately small HTTP parser implemented just for the
demo; it is not a full HTTP or JSON implementation and will need to
be replaced or extended for production use.
*/

use "net"
use "collections"
use ".."

actor WebServer
  let _listener: TCPListener
  let _receiver: Receiver

  new create(auth: AmbientAuth, receiver: Receiver, port: String = "8080") =>
    _receiver = receiver
    _listener = TCPListener(TCPListenAuth(auth), WebListenNotify(_receiver), "", port)

class WebListenNotify is TCPListenNotify
  let _receiver: Receiver

  new iso create(receiver: Receiver) =>
    _receiver = receiver

  fun ref listening(listener: TCPListener ref) =>
    None

  fun ref not_listening(listener: TCPListener ref) =>
    None

  fun ref connected(listener: TCPListener ref): TCPConnectionNotify iso^ =>
    WebConnection(_receiver)

class WebConnection is TCPConnectionNotify
  let _receiver: Receiver
  var _buffer: String = ""

  new iso create(receiver: Receiver) =>
    _receiver = receiver

  fun ref connected(conn: TCPConnection ref) =>
    None

  fun ref connect_failed(conn: TCPConnection ref) =>
    None

  fun ref closed(conn: TCPConnection ref) =>
    None

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    _buffer = _buffer + String.from_array(consume data)

    try
      if _buffer.contains("\r\n\r\n") then
        let parts = _buffer.split_by("\r\n\r\n", 2)
        let headers = parts(0)?
        let body = if parts.size() > 1 then parts(1)? else "" end

        if headers.contains("POST /api/v1/messages/send") then
          _handle_message(conn, body)
        else
          _send_error(conn, 404, "Not Found")
        end
        _buffer = ""
      end
    end
    true

  fun ref _handle_message(conn: TCPConnection ref, body: String) =>
    if body.contains("\"type\"") and body.contains("\"recipient\"") and body.contains("\"body\"") then
      let msg_type = _extract_json_field(body, "type")
      let recipient = _extract_json_field(body, "recipient")
      let body_text = _extract_json_field(body, "body")
      let subject_str = _extract_json_field(body, "subject")
      let subject = if subject_str.size() > 0 then subject_str else None end

      let kind: MessageKind = match msg_type
      | "email" => EmailKind
      | "sms" => SmsKind
      | "push" => PushKind
      else
        _send_error(conn, 400, "Invalid message type")
        return
      end

      _receiver.receive(kind, recipient, body_text, subject)
      _send_response(conn, 200, "{\"status\":\"accepted\"}")
    else
      _send_error(conn, 400, "Missing required fields")
    end

    fun ref _extract_json_field(json: String, field: String): String =>
      try
        let field_start = json.find("\"" + field + "\":")?.isize() + field.size().isize() + 3
        var start_pos: ISize = field_start
        while (start_pos < json.size().isize()) and (json(start_pos.usize())? == ' ') do
          start_pos = start_pos + 1
        end
        if json(start_pos.usize())? == '"' then
          start_pos = start_pos + 1
          let end_pos = json.find("\"", start_pos)?
          json.substring(start_pos, end_pos)
        else
          ""
        end
      else
        ""
      end

    fun ref _send_response(conn: TCPConnection ref, status: U16, response_body: String) =>
      let headers = "HTTP/1.1 " + status.string() + " OK\r\n" +
                    "Content-Type: application/json\r\n" +
                    "Content-Length: " + response_body.size().string() + "\r\n" +
                    "Connection: close\r\n\r\n"
      conn.write(consume headers)
      conn.write(response_body)
      conn.dispose()

    fun ref _send_error(conn: TCPConnection ref, status: U16, message: String) =>
      let response_body = "{\"error\":\"" + message + "\"}"
      let headers = "HTTP/1.1 " + status.string() + " Error\r\n" +
                    "Content-Type: application/json\r\n" +
                    "Content-Length: " + response_body.size().string() + "\r\n" +
                    "Connection: close\r\n\r\n"
      conn.write(consume headers)
      conn.write(consume response_body)
      conn.dispose()
