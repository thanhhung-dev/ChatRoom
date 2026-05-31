# WebSocket Protocol Specification
## Backend ChatRoom

---

## 1. Kết nối

### Endpoint
```
ws://localhost:8000/ws?token={access_token}
```

### Authentication
- Client gửi JWT access_token qua query param khi handshake
- Server validate token, nếu không hợp lệ → close với code `4001`
- Nếu token hết hạn → close với code `4001`, client cần refresh token rồi reconnect

### Close codes
| Code | Meaning |
|---|---|
| 1000 | Normal closure |
| 4001 | Unauthorized (token invalid/expired) |
| 4002 | Rate limit exceeded |
| 4003 | Room not found or access denied |
| 4008 | Server shutting down |

---

## 2. Message Format

Tất cả messages dùng JSON:

```json
{
  "type": "string",
  "payload": { ... },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

---

## 3. Client → Server Events

### `join_room`
Tham gia phòng chat. Phải join trước khi gửi/nhận tin nhắn trong phòng.

```json
{
  "type": "join_room",
  "payload": {
    "room_id": 1
  }
}
```

### `leave_room`
Rời khỏi phòng (trên WebSocket, không phải leave room vĩnh viễn).

```json
{
  "type": "leave_room",
  "payload": {
    "room_id": 1
  }
}
```

### `send_message`
Gửi tin nhắn văn bản.

```json
{
  "type": "send_message",
  "payload": {
    "room_id": 1,
    "content": "Hello everyone!",
    "temp_id": "client-uuid-123"
  }
}
```

- `temp_id`: Client-generated ID để match response với message. Server sẽ echo lại trong `message_sent`.

### `typing`
Báo hiệu đang nhập tin nhắn.

```json
{
  "type": "typing",
  "payload": {
    "room_id": 1
  }
}
```

### `stop_typing`
Dừng nhập tin nhắn.

```json
{
  "type": "stop_typing",
  "payload": {
    "room_id": 1
  }
}
```

### `sync_messages`
Đồng bộ tin nhắn missed khi reconnect.

```json
{
  "type": "sync_messages",
  "payload": {
    "room_id": 1,
    "last_message_id": 42
  }
}
```

### `mark_read`
Đánh dấu tin nhắn đã đọc.

```json
{
  "type": "mark_read",
  "payload": {
    "room_id": 1,
    "last_message_id": 50
  }
}
```

### `ping`
Heartbeat để giữ kết nối.

```json
{
  "type": "ping"
}
```

---

## 4. Server → Client Events

### `connected`
Gửi ngay khi kết nối thành công.

```json
{
  "type": "connected",
  "payload": {
    "user_id": 1,
    "username": "john"
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `room_joined`
Phản hồi khi join phòng thành công.

```json
{
  "type": "room_joined",
  "payload": {
    "room_id": 1,
    "online_members": [
      {
        "user_id": 2,
        "username": "jane",
        "display_name": "Jane"
      }
    ],
    "unread_count": 5
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `user_joined`
Thông báo khi có user khác join phòng.

```json
{
  "type": "user_joined",
  "payload": {
    "room_id": 1,
    "user": {
      "user_id": 3,
      "username": "bob",
      "display_name": "Bob"
    }
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `user_left`
Thông báo khi user rời phòng.

```json
{
  "type": "user_left",
  "payload": {
    "room_id": 1,
    "user_id": 3,
    "username": "bob"
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `message_sent`
Xác nhận tin nhắn đã được lưu (gửi cho người gửi).

```json
{
  "type": "message_sent",
  "payload": {
    "temp_id": "client-uuid-123",
    "message": {
      "id": 42,
      "room_id": 1,
      "user_id": 1,
      "username": "john",
      "display_name": "John",
      "content": "Hello everyone!",
      "message_type": "text",
      "file_url": null,
      "file_name": null,
      "status": "sent",
      "created_at": "2026-05-31T10:00:00Z"
    }
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `new_message`
Broadcast tin nhắn mới cho tất cả thành viên trong phòng (trừ người gửi).

```json
{
  "type": "new_message",
  "payload": {
    "room_id": 1,
    "message": {
      "id": 42,
      "user_id": 1,
      "username": "john",
      "display_name": "John",
      "content": "Hello everyone!",
      "message_type": "text",
      "file_url": null,
      "file_name": null,
      "status": "delivered",
      "created_at": "2026-05-31T10:00:00Z"
    }
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `typing_indicator`
Thông báo có người đang nhập.

```json
{
  "type": "typing_indicator",
  "payload": {
    "room_id": 1,
    "user_id": 2,
    "username": "jane",
    "is_typing": true
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `sync_messages`
Phản hồi đồng bộ tin nhắn.

```json
{
  "type": "sync_messages",
  "payload": {
    "room_id": 1,
    "messages": [
      {
        "id": 43,
        "user_id": 2,
        "username": "jane",
        "content": "Missed message 1",
        "created_at": "2026-05-31T10:01:00Z"
      },
      {
        "id": 44,
        "user_id": 3,
        "username": "bob",
        "content": "Missed message 2",
        "created_at": "2026-05-31T10:02:00Z"
      }
    ],
    "has_more": true
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `messages_read`
Xác nhận đã đánh dấu đọc.

```json
{
  "type": "messages_read",
  "payload": {
    "room_id": 1,
    "user_id": 1,
    "last_message_id": 50
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `unread_update`
Cập nhật số tin nhắn chưa đọc (khi nhận tin nhắn mới ở phòng khác).

```json
{
  "type": "unread_update",
  "payload": {
    "room_id": 1,
    "unread_count": 3
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `user_status`
Thay đổi trạng thái online/offline của user.

```json
{
  "type": "user_status",
  "payload": {
    "user_id": 2,
    "username": "jane",
    "is_online": true
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `error`
Lỗi từ server.

```json
{
  "type": "error",
  "payload": {
    "code": "ROOM_NOT_FOUND",
    "message": "Phòng chat không tồn tại"
  },
  "timestamp": "2026-05-31T10:00:00Z"
}
```

### `pong`
Phản hồi heartbeat.

```json
{
  "type": "pong",
  "timestamp": "2026-05-31T10:00:00Z"
}
```

---

## 5. Heartbeat

- Client gửi `ping` mỗi **30 giây**
- Server phản hồi `pong`
- Nếu server không nhận `ping` trong **60 giây** → coi là stale, close connection
- Client nếu không nhận `pong` trong **10 giây** → reconnect

---

## 6. Reconnection Strategy

1. Client mất kết nối
2. Client reconnect với exponential backoff: 1s → 2s → 4s → 8s → 16s → max 30s
3. Sau khi reconnect thành công, client gửi `sync_messages` cho mỗi room đã join
4. Server trả về tin nhắn missed (dựa trên `last_message_id`)
5. Client merge vào local state

---

## 7. Rate Limiting (WebSocket)

| Event | Limit |
|---|---|
| send_message | 30/phút |
| typing | 10/phút |
| join_room | 5/phút |
| sync_messages | 10/phút |

Nếu vượt rate limit → server gửi error và có thể close connection với code `4002`.
