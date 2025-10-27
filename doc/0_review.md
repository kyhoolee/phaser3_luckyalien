# Lucky Alien – Code Review

## Kiến trúc tổng quan
- Game được xây dựng bằng Phaser 3, chạy trực tiếp trên `index.html` và tải world data từ các file `data/*.js`. Mỗi level là một scene con kế thừa `Scene` tùy biến (`scenes/Levels.js`).
- Vòng đời scene tuân theo chuẩn Phaser: `Scene.prototype.preload` nạp asset, `Scene.prototype.create` dựng toàn bộ thực thể (player, vật cản, enemy, UI), còn `Scene.prototype.update` xử lý logic lặp.
- Trạng thái toàn cục (player stats, checkpoint, abilities, âm thanh, v.v.) được gom vào object `game` trong `script.js`. Các group vật thể (ví dụ carrots, swords) cũng được nhét vào `game.abilities.*`, khiến nơi lưu trữ trộn lẫn giữa boolean và nhóm sprite.
- Dữ liệu level (`world[...]`) mô tả hình học cảnh (blocks, boxes, spikes, doors, v.v.) và được `create` đọc để sinh collider và enemy theo cấu hình.

## Các phát hiện chính (ưu tiên cao ➜ thấp)
1. `main/create.js:297` – gọi `game.abilities.doubleJumpPowerup.create(...)` trong lúc group thật sự được khai báo là `game.doubleJumpPowerup = this.physics.add.group()`. Ở runtime, khi người chơi bật một hộp chứa double-jump, game sẽ ném lỗi “Cannot read property 'create' of undefined” và dừng hẳn.
2. `main/create.js:803` – khi nhặt double-jump, code đặt `game.abilities.doubleJumpPowerup = true` thay vì `game.abilities.doubleJumps = true`. Ngay cả khi lỗi (1) được sửa, người chơi vẫn không bao giờ kích hoạt được khả năng nhảy đôi.
3. `main/create.js:278` – điều kiện sinh `mushroomPowerup` đang kiểm tra `!game.abilities.mushroom` trong khi biến thực sự lưu trạng thái là `game.abilities.bounceMagic`. Hệ quả: hộp luôn spawn lại powerup (vì check luôn đúng) dù người chơi đã mở khóa bounce.
4. `main/Controls.js:63` & `main/Controls.js:65` – biến `game.jumpsMade` chỉ tăng mà không reset khi chạm đất. Điều kiện nhảy đôi `game.jumpsMade % 2 === 0` sẽ chỉ đúng ở frame đầu tiên (giá trị 0), nên dù có năng lực double-jump, logic hiện tại vẫn không bao giờ cho phép thực hiện lần nhảy thứ hai.

## Khuyến nghị
- Chuẩn hóa lại nơi lưu trạng thái abilities: tách rõ boolean (ví dụ `game.abilitiesFlags`) và Phaser groups (`game.projectiles`, `game.powerups`) để tránh nhầm lẫn kiểu (bug 1 & 2).
- Thêm cơ chế reset `game.jumpsMade` khi `player.body.blocked.down` hoặc khi vận tốc rơi chuyển sang chạm đất.
- Rà soát thêm các powerup khác bảo đảm điều kiện spawn gắn đúng flag (ví dụ `bounceMagic`).
- Xem xét tách nhỏ `Scene.prototype.create` (>1.1k dòng) thành các helper như `createEnemies`, `setupPowerups`, `setupUI` để dễ bảo trì và test.

## Câu hỏi mở / cần xác nhận
- Có dự kiến đưa game chạy song song nhiều scene (multiplayer menu, v.v.) không? Nếu có, mô hình state toàn cục cần refactor mạnh tay để tránh đụng độ.
- Phần setup hiện sử dụng asset local + CDN Phaser. Có cần kịch bản build/offline (webpack/parcel) để deploy nội bộ không?
