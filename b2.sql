CREATE DATABASE HospitalDB;
USE HospitalDB;

CREATE TABLE Patients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Full_Name VARCHAR(100),
    Phone VARCHAR(20),
    Age INT,
    Address VARCHAR(255)
);

DELIMITER //
CREATE PROCEDURE SeedPatients()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 500000 DO
        INSERT INTO Patients (Full_Name, Phone, Age, Address)
        VALUES (CONCAT('Patient ', i), CONCAT('090', i), FLOOR(RAND()*100), 'Ho Chi Minh City');
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- Gọi để nạp dữ liệu
CALL SeedPatients();

SET profiling = 1;

-- 1. Đo lường trước khi có Index
SELECT * FROM Patients WHERE Phone = '090123456';
SHOW PROFILES; -- Ghi lại thời gian (thường sẽ chậm vì quét toàn bộ bảng)

-- 2. Phân tích bằng EXPLAIN
EXPLAIN SELECT * FROM Patients WHERE Phone = '090123456';
-- Quan sát cột 'type': sẽ là 'ALL' (Full Table Scan - rất chậm)

-- 3. Tạo Index
CREATE INDEX idx_phone ON Patients(Phone);

-- 4. Đo lường sau khi có Index
SELECT * FROM Patients WHERE Phone = '090123456';
SHOW PROFILES; -- Thời gian sẽ giảm đáng kể

-- 5. Phân tích lại bằng EXPLAIN
EXPLAIN SELECT * FROM Patients WHERE Phone = '090123456';
-- Quan sát cột 'type': sẽ đổi thành 'ref' hoặc 'const' (Index Lookup - rất nhanh)



-- Kịch bản 1: Đo tốc độ INSERT 1000 dòng KHI ĐÃ CÓ INDEX
-- (Giả sử bạn đã chạy lệnh CREATE INDEX ở bước trên)
START TRANSACTION;
-- Viết script chèn 1000 dòng hoặc loop tương tự như SeedPatients
-- Kiểm tra thời gian thực thi...
ROLLBACK; -- Hủy thay đổi để reset bảng về trạng thái cũ

-- Kịch bản 2: Đo tốc độ INSERT 1000 dòng KHI KHÔNG CÓ INDEX
DROP INDEX idx_phone ON Patients;
START TRANSACTION;
-- Chạy lại đoạn lệnh chèn 1000 dòng tương tự...
-- So sánh thời gian thực thi với Kịch bản 1
ROLLBACK;


-- select : chậm(ko có index) , cực nhanh(khi có index)
-- nguyên nhân : Index tạo ra một "bản đồ" (B-Tree) giúp tìm kiếm nhanh, không cần quét toàn bộ hàng.

-- INSERT/UPDATE/DELETE :  nhanh(ko có index) , chậm hơn(khi có index)
-- nguyên nhân : Mỗi khi thay đổi dữ liệu, Database phải cập nhật lại cả bảng chính và cấu trúc Index (B-Tree). 

