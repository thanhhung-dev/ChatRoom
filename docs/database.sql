CREATE TABLE
    chatroom_db.users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(30) NOT NULL UNIQUE,
        email VARCHAR(255) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        display_name VARCHAR(50) NOT NULL,
        avatar_url TEXT NOT NULL,
        is_online BOOLEAN DEFAULT false NOT NULL,
        last_seen_at TIMESTAMPTZ DEFAULT NOW (),
        created_at TIMESTAMPTZ DEFAULT NOW () NOT NULL,
        updated_at TIMESTAMPTZ DEFAULT NOW ()
    );

CREATE TABLE
    chatroom_db.rooms (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        description VARCHAR(500),
        invite_code VARCHAR(20) NOT NULL UNIQUE,
        created_by INTEGER NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW (),
        updated_at TIMESTAMPTZ DEFAULT NOW (),
        CONSTRAINT fk_rooms_user FOREIGN KEY (created_by) REFERENCES chatroom_db.users (id) ON DELETE CASCADE
    )
CREATE TABLE
    chatroom_db.room_members (
        id SERIAL PRIMARY KEY,
        room_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        role VARCHAR(10) DEFAULT 'member' NOT NULL,
        unread_count INTEGER DEFAULT 0 NOT NULL,
        last_read_message_id INTEGER,
        joined_at TIMESTAMPTZ DEFAULT NOW (),
        CONSTRAINT fk_room_members_room FOREIGN KEY (room_id) REFERENCES chatroom_db.rooms (id) ON DELETE CASCADE,
        CONSTRAINT fk_room_members_user FOREIGN KEY (user_id) REFERENCES chatroom_db.users (id) ON DELETE CASCADE,
        CONSTRAINT unique_room_user UNIQUE (room_id, user_id)
    );

CREATE TABLE
    chatroom_db.messages (
        id BIGSERIAL PRIMARY KEY,
        room_id INTEGER NOT NULL,
        user_id INTEGER,
        content TEXT NOT NULL,
        message_type VARCHAR(10) DEFAULT 'text' NOT NULL,
        file_url TEXT,
        file_name VARCHAR(255),
        status VARCHAR(15) DEFAULT 'sent' NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW (),
        CONSTRAINT fk_messages_room FOREIGN KEY (room_id) REFERENCES chatroom_db.rooms (id) ON DELETE CASCADE,
        CONSTRAINT fk_messages_user FOREIGN KEY (user_id) REFERENCES chatroom_db.users (id) ON DELETE SET null
    );

CREATE TABLE
    chatroom_db.refresh_tokens (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        token_hash VARCHAR(255) NOT NULL UNIQUE,
        expires_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW (),
        revoked_at TIMESTAMPTZ,
        CONSTRAINT fk_tokens_user FOREIGN KEY (user_id) REFERENCES chatroom_db.users (id) ON DELETE cascade
    );

CREATE INDEX idx_rooms_created_by ON chatroom_db.rooms (created_by);

CREATE INDEX idx_room_members_room_id ON chatroom_db.room_members (room_id);

CREATE INDEX idx_room_members_user_id ON chatroom_db.room_members (user_id);

CREATE INDEX idx_messages_room_id ON chatroom_db.messages (room_id);

CREATE INDEX idx_messages_created_at ON chatroom_db.messages (created_at);

CREATE INDEX idx_messages_room_created ON chatroom_db.messages (room_id, created_at DESC);

CREATE INDEX idx_refresh_tokens_user ON chatroom_db.refresh_tokens (user_id);


INSERT INTO
    chatroom_db.users (
        username,
        email,
        password_hash,
        display_name,
        avatar_url,
        is_online,
        last_seen_at
    )
VALUES
    (
        'thanhhung',
        'thanhhung@gmail.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMaWkalWng1ZOQqSKJZJHJHJHJ',
        'Thành Hưng',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=thanhhung',
        true,
        NOW ()
    ),
    (
        'minhkhoa',
        'minhkhoa@gmail.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMaWkalWng1ZOQqSKJZJHJHJHK',
        'Minh Khoa',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=minhkhoa',
        false,
        NOW () - INTERVAL '2 hours'
    ),
    (
        'thuynguyen',
        'thuynguyen@gmail.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMaWkalWng1ZOQqSKJZJHJHJHL',
        'Thùy Nguyễn',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=thuynguyen',
        true,
        NOW ()
    ),
    (
        'hoanganh',
        'hoanganh@gmail.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMaWkalWng1ZOQqSKJZJHJHJHM',
        'Hoàng Anh',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=hoanganh',
        false,
        NOW () - INTERVAL '1 day'
    ),
    (
        'baolong',
        'baolong@gmail.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMaWkalWng1ZOQqSKJZJHJHJHN',
        'Bảo Long',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=baolong',
        true,
        NOW ()
    ),
    (
        'phuonglinh',
        'phuonglinh@gmail.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMaWkalWng1ZOQqSKJZJHJHJHO',
        'Phương Linh',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=phuonglinh',
        false,
        NOW () - INTERVAL '30 minutes'
    ),
    (
        'ducmanh',
        'ducmanh@gmail.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMaWkalWng1ZOQqSKJZJHJHJHP',
        'Đức Mạnh',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=ducmanh',
        true,
        NOW ()
    ),
    (
        'trangmy',
        'trangmy@gmail.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMaWkalWng1ZOQqSKJZJHJHJHQ',
        'Trang Mỹ',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=trangmy',
        false,
        NOW () - INTERVAL '5 hours'
    );

INSERT INTO
    chatroom_db.rooms (name, description, invite_code, created_by)
VALUES
    (
        'General',
        'Kênh chat chung cho tất cả mọi người',
        'GENERAL001',
        1
    ),
    (
        'Dev Team',
        'Nhóm lập trình viên - thảo luận kỹ thuật',
        'DEVTEAM002',
        1
    ),
    (
        'Thiết kế UI/UX',
        'Chia sẻ mockup, feedback giao diện',
        'DESIGN003',
        3
    ),
    (
        'Random',
        'Chat linh tinh, meme, vui vẻ',
        'RANDOM004',
        2
    ),
    (
        'Thông báo',
        'Chỉ admin mới được gửi tin - thông báo chung',
        'ANNOUNCE005',
        1
    );


INSERT INTO
    chatroom_db.room_members (
        room_id,
        user_id,
        role,
        unread_count,
        last_read_message_id
    )
VALUES
    (1, 1, 'owner', 0, NULL),
    (1, 2, 'member', 2, NULL),
    (1, 3, 'member', 0, NULL),
    (1, 4, 'member', 5, NULL),
    (1, 5, 'admin', 0, NULL),
    (1, 6, 'member', 1, NULL),
    (1, 7, 'member', 0, NULL),
    (1, 8, 'member', 3, NULL);

-- Dev Team (room 2)
INSERT INTO
    chatroom_db.room_members (
        room_id,
        user_id,
        role,
        unread_count,
        last_read_message_id
    )
VALUES
    (2, 1, 'owner', 0, NULL),
    (2, 2, 'admin', 0, NULL),
    (2, 5, 'member', 1, NULL),
    (2, 7, 'member', 4, NULL);

-- Thiết kế UI/UX (room 3)
INSERT INTO
    chatroom_db.room_members (
        room_id,
        user_id,
        role,
        unread_count,
        last_read_message_id
    )
VALUES
    (3, 3, 'owner', 0, NULL),
    (3, 6, 'member', 2, NULL),
    (3, 8, 'member', 0, NULL),
    (3, 1, 'member', 1, NULL);

-- Random (room 4)
INSERT INTO
    chatroom_db.room_members (
        room_id,
        user_id,
        role,
        unread_count,
        last_read_message_id
    )
VALUES
    (4, 2, 'owner', 0, NULL),
    (4, 1, 'member', 0, NULL),
    (4, 3, 'member', 6, NULL),
    (4, 4, 'member', 0, NULL),
    (4, 5, 'member', 2, NULL),
    (4, 7, 'member', 1, NULL);

-- Thông báo (room 5)
INSERT INTO
    chatroom_db.room_members (
        room_id,
        user_id,
        role,
        unread_count,
        last_read_message_id
    )
VALUES
    (5, 1, 'owner', 0, NULL),
    (5, 2, 'member', 1, NULL),
    (5, 3, 'member', 0, NULL),
    (5, 4, 'member', 1, NULL),
    (5, 5, 'member', 0, NULL),
    (5, 6, 'member', 1, NULL),
    (5, 7, 'member', 1, NULL),
    (5, 8, 'member', 1, NULL);

-- MESSAGES
-- Room 1: General
INSERT INTO
    chatroom_db.messages (
        room_id,
        user_id,
        content,
        message_type,
        status,
        created_at
    )
VALUES
    (
        1,
        1,
        'Chào mọi người! Đây là kênh chat chung nhé.',
        'text',
        'read',
        NOW () - INTERVAL '3 days'
    ),
    (
        1,
        3,
        'Chào anh Hưng! Em mới vào nhóm ạ',
        'text',
        'read',
        NOW () - INTERVAL '3 days' + INTERVAL '5 minutes'
    ),
    (
        1,
        2,
        'Welcome Thùy! Nhóm mình đang làm project chatroom này đó.',
        'text',
        'read',
        NOW () - INTERVAL '3 days' + INTERVAL '10 minutes'
    ),
    (
        1,
        5,
        'Hehe mình cũng mới vào. Nhóm vui quá',
        'text',
        'read',
        NOW () - INTERVAL '2 days'
    ),
    (
        1,
        4,
        'Mọi người ơi hôm nay họp lúc mấy giờ vậy?',
        'text',
        'read',
        NOW () - INTERVAL '1 day'
    ),
    (
        1,
        1,
        '3 giờ chiều nha, họp online qua Meet',
        'text',
        'read',
        NOW () - INTERVAL '1 day' + INTERVAL '2 minutes'
    ),
    (
        1,
        7,
        'Ok anh, em nhớ rồi ạ',
        'text',
        'read',
        NOW () - INTERVAL '1 day' + INTERVAL '5 minutes'
    ),
    (
        1,
        8,
        'Cho mình xin link meet với!',
        'text',
        'read',
        NOW () - INTERVAL '1 day' + INTERVAL '7 minutes'
    ),
    (
        1,
        1,
        'https://meet.google.com/abc-defg-hij',
        'text',
        'delivered',
        NOW () - INTERVAL '23 hours'
    ),
    (
        1,
        6,
        'Cảm ơn anh ạ',
        'text',
        'delivered',
        NOW () - INTERVAL '22 hours'
    ),
    (
        1,
        2,
        'Deadline tuần này mọi người nhớ submit đúng hạn nha!',
        'text',
        'sent',
        NOW () - INTERVAL '1 hour'
    ),
    (
        1,
        5,
        'Roger that',
        'text',
        'sent',
        NOW () - INTERVAL '55 minutes'
    );

-- Room 2: Dev Team
INSERT INTO
    chatroom_db.messages (
        room_id,
        user_id,
        content,
        message_type,
        status,
        created_at
    )
VALUES
    (
        2,
        1,
        'Team dev ơi, hôm nay fix bug WebSocket nhé. Tin nhắn bị delay 3-4s.',
        'text',
        'read',
        NOW () - INTERVAL '2 days'
    ),
    (
        2,
        2,
        'Anh ơi em thấy issue rồi, chỗ reconnect logic bị sai. Để em fix.',
        'text',
        'read',
        NOW () - INTERVAL '2 days' + INTERVAL '10 minutes'
    ),
    (
        2,
        7,
        'Anh cho em hỏi cái index này có cần thiết không ạ: idx_messages_room_created',
        'text',
        'read',
        NOW () - INTERVAL '1 day'
    ),
    (
        2,
        1,
        'Cần lắm đó Mạnh! Query tin nhắn theo room + sort created_at DESC, thiếu index là chậm lắm.',
        'text',
        'read',
        NOW () - INTERVAL '1 day' + INTERVAL '5 minutes'
    ),
    (
        2,
        2,
        'Đã push fix lên branch feature/ws-reconnect rồi anh, anh review giúp em nhé.',
        'text',
        'read',
        NOW () - INTERVAL '20 hours'
    ),
    (
        2,
        5,
        'Anh ơi em deploy lên staging được chưa ạ?',
        'text',
        'sent',
        NOW () - INTERVAL '2 hours'
    ),
    (
        2,
        1,
        'Chờ review xong đã Bảo Long ơi',
        'text',
        'sent',
        NOW () - INTERVAL '1 hour 50 minutes'
    );

-- Room 3: Thiết kế UI/UX
INSERT INTO
    chatroom_db.messages (
        room_id,
        user_id,
        content,
        message_type,
        status,
        created_at
    )
VALUES
    (
        3,
        3,
        'Mình vừa xong mockup màn hình chat, mọi người xem thử nha!',
        'text',
        'read',
        NOW () - INTERVAL '1 day'
    ),
    (
        3,
        3,
        'figma.com/file/demo-chatroom-ui',
        'text',
        'read',
        NOW () - INTERVAL '1 day' + INTERVAL '1 minute'
    ),
    (
        3,
        6,
        'Ồ đẹp ghê! Nhưng mình nghĩ phần avatar nên to hơn một chút.',
        'text',
        'read',
        NOW () - INTERVAL '23 hours'
    ),
    (
        3,
        8,
        'Mình đồng ý với Phương Linh. Với lại màu primary nên dùng tông xanh lá không?',
        'text',
        'read',
        NOW () - INTERVAL '22 hours'
    ),
    (
        3,
        3,
        'Ok mình sẽ thử cả hai phương án rồi so sánh nhé',
        'text',
        'sent',
        NOW () - INTERVAL '10 hours'
    ),
    (
        3,
        1,
        'Trông xịn lắm Thùy ơi! Khi nào có bản updated thì share lại nhé.',
        'text',
        'sent',
        NOW () - INTERVAL '30 minutes'
    );

-- Room 4: Random
INSERT INTO
    chatroom_db.messages (
        room_id,
        user_id,
        content,
        message_type,
        status,
        created_at
    )
VALUES
    (
        4,
        2,
        'Haha mọi người thấy cái meme này chưa',
        'text',
        'read',
        NOW () - INTERVAL '2 days'
    ),
    (
        4,
        4,
        'Cái gì vậy Khoa ơi',
        'text',
        'read',
        NOW () - INTERVAL '2 days' + INTERVAL '3 minutes'
    ),
    (
        4,
        2,
        'Lập trình viên vs designer battle',
        'text',
        'read',
        NOW () - INTERVAL '2 days' + INTERVAL '4 minutes'
    ),
    (
        4,
        1,
        'HAHAHA quá đúng luôn',
        'text',
        'read',
        NOW () - INTERVAL '2 days' + INTERVAL '6 minutes'
    ),
    (
        4,
        3,
        'Ủa sao chỉ có designer thua vậy',
        'text',
        'read',
        NOW () - INTERVAL '2 days' + INTERVAL '8 minutes'
    ),
    (
        4,
        5,
        'Vì dev code đẹp hơn design',
        'text',
        'read',
        NOW () - INTERVAL '2 days' + INTERVAL '10 minutes'
    ),
    (
        4,
        3,
        'Bảo Long ơi tôi không còn coi anh là bạn nữa',
        'text',
        'read',
        NOW () - INTERVAL '2 days' + INTERVAL '12 minutes'
    ),
    (
        4,
        7,
        'Trời ơi cãi nhau vui quá',
        'text',
        'sent',
        NOW () - INTERVAL '3 hours'
    ),
    (
        4,
        2,
        'Btw ai đang nghe nhạc gì không? Share playlist đi!',
        'text',
        'sent',
        NOW () - INTERVAL '1 hour'
    );

-- Room 5: Thông báo
INSERT INTO
    chatroom_db.messages (
        room_id,
        user_id,
        content,
        message_type,
        status,
        created_at
    )
VALUES
    (
        5,
        1,
        ' Thông báo: Sprint review sẽ diễn ra vào thứ Sáu tuần này lúc 2PM.',
        'text',
        'delivered',
        NOW () - INTERVAL '1 day'
    ),
    (
        5,
        1,
        ' Reminder: Mọi người update task trên board trước 5PM hôm nay nhé.',
        'text',
        'sent',
        NOW () - INTERVAL '2 hours'
    );

-- REFRESH TOKENS (demo - 2 user đang đăng nhập)
INSERT INTO
    chatroom_db.refresh_tokens (user_id, token_hash, expires_at)
VALUES
    (
        1,
        '$2b$12$refreshhash_user1_active_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        NOW () + INTERVAL '30 days'
    ),
    (
        3,
        '$2b$12$refreshhash_user3_active_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        NOW () + INTERVAL '30 days'
    ),
    (
        5,
        '$2b$12$refreshhash_user5_active_ccccccccccccccccccccccccccccccc',
        NOW () + INTERVAL '30 days'
    ),
    (
        2,
        '$2b$12$refreshhash_user2_revoked_ddddddddddddddddddddddddddddddd',
        NOW () + INTERVAL '30 days'
    );

-- Update last_read_message_id cho một số member
UPDATE chatroom_db.room_members
SET
    last_read_message_id = 9
WHERE
    room_id = 1
    AND user_id = 3;

UPDATE chatroom_db.room_members
SET
    last_read_message_id = 8
WHERE
    room_id = 1
    AND user_id = 7;

UPDATE chatroom_db.room_members
SET
    last_read_message_id = 21
WHERE
    room_id = 2
    AND user_id = 2;

UPDATE chatroom_db.room_members
SET
    last_read_message_id = 27
WHERE
    room_id = 3
    AND user_id = 3;