
CREATE DATABASE IF NOT EXISTS bitrixdb1 CHARACTER SET utf8 COLLATE utf8_general_ci;

GRANT ALL PRIVILEGES ON bitrixdb1.* TO bitrixuser1@localhost IDENTIFIED BY "bitrixpassword1" WITH GRANT OPTION;
