-- Create your tables, views, functions and procedures here!
CREATE SCHEMA social;
USE social;

CREATE TABLE users (
	user_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	first_name VARCHAR(30) NOT NULL,
	last_name VARCHAR(30) NOT NULL,
	email VARCHAR(50) NOT NULL,
	created_on TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE sessions (
	session_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	user_id INT UNSIGNED NOT NULL,
	created_on TIMESTAMP NOT NULL DEFAULT NOW(),
	updated_on TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW(),

	CONSTRAINT sessions_fk_users
		FOREIGN KEY (user_id)
		REFERENCES users (user_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE friends (
	user_friend_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	user_id INT UNSIGNED NOT NULL,
	friend_id INT UNSIGNED NOT NULL,

	CONSTRAINT friends_fk_users
		FOREIGN KEY (user_id)
		REFERENCES users (user_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,

	CONSTRAINT friends_fk_users_friend
		FOREIGN KEY (friend_id)
		REFERENCES users (user_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE posts (
	post_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	user_id INT UNSIGNED NOT NULL,
	created_on TIMESTAMP NOT NULL DEFAULT NOW(),	
	updated_on TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW(),
	content VARCHAR(128) NOT NULL,

	CONSTRAINT posts_fk_users
		FOREIGN KEY (user_id)
		REFERENCES users (user_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE notifications (
	notification_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	user_id INT UNSIGNED NOT NULL,
	post_id INT UNSIGNED NOT NULL,

	CONSTRAINT notifications_fk_users
		FOREIGN KEY (user_id)
		REFERENCES users (user_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,

	CONSTRAINT notifications_fk_posts
		FOREIGN KEY (post_id)
		REFERENCES posts (post_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);


DELIMITER ;;
CREATE TRIGGER new_user
	AFTER INSERT ON users
	FOR EACH ROW
BEGIN
	DECLARE new_user_id INT UNSIGNED;
	DECLARE id_of_post INT UNSIGNED;
	DECLARE row_not_found INT DEFAULT FALSE;

	DECLARE user_cursor CURSOR FOR 
	SELECT 
		users.user_id 
	FROM users 
	WHERE user_id != NEW.user_id;

	DECLARE CONTINUE HANDLER FOR NOT FOUND
	SET row_not_found = TRUE;

	INSERT INTO posts
		(user_id, content)
	VALUES
		(NEW.user_id, CONCAT(NEW.first_name, " ", NEW.last_name, " just joined!"));

	SELECT LAST_INSERT_ID() INTO id_of_post;

	OPEN user_cursor;
	user_loop : LOOP

		FETCH user_cursor INTO new_user_id;
		IF row_not_found THEN
			LEAVE user_loop;
		END IF;

		INSERT INTO notifications (user_id, post_id) VALUES (new_user_id, id_of_post);

	END LOOP user_loop;
	CLOSE user_cursor;
END;;

CREATE PROCEDURE add_post(id_of_user INT UNSIGNED, content_of_post VARCHAR(128))
BEGIN
	DECLARE id_of_friend INT UNSIGNED;
	DECLARE id_of_post INT UNSIGNED;
	DECLARE row_not_found INT DEFAULT FALSE;

	DECLARE user_friends_cursor CURSOR FOR
	SELECT 
		friends.friend_id
	FROM friends
	WHERE friends.user_id = id_of_user;

	DECLARE CONTINUE HANDLER FOR NOT FOUND
	SET row_not_found = TRUE;

	INSERT INTO posts (user_id, content) VALUES (id_of_user, content_of_post);

	SELECT LAST_INSERT_ID() INTO id_of_post;

	OPEN user_friends_cursor;
	friend_loop : LOOP

		FETCH user_friends_cursor INTO id_of_friend;
		IF row_not_found THEN
			LEAVE friend_loop;
		END IF;

		INSERT INTO notifications (user_id, post_id) VALUES (id_of_friend, id_of_post);

	END LOOP;
	CLOSE user_friends_cursor;
END;;

CREATE EVENT expired_session
	ON SCHEDULE EVERY 10 SECOND
DO
BEGIN
	DELETE FROM sessions WHERE updated_on < DATE_SUB(NOW(), INTERVAL 2 HOUR);
END;;
DELIMITER ;


CREATE OR REPLACE VIEW notification_posts AS 
SELECT 
	notifications.user_id,
	users.first_name,
	users.last_name,
	posts.post_id,
	posts.content
FROM users
	LEFT OUTER JOIN posts
		ON users.user_id = posts.user_id
	LEFT OUTER JOIN notifications
		ON posts.post_id = notifications.post_id;
