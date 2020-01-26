
USE mysql;
UPDATE user SET plugin = 'mysql_native_password' WHERE User = 'root';
FLUSH PRIVILEGES;
