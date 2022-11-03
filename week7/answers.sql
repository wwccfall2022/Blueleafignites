-- Create your tables, views, functions and procedures here!
CREATE SCHEMA destruction;
USE destruction;

CREATE TABLE players (
  player_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(30) NOT NULL,
  last_name VARCHAR(30) NOT NULL,
  email VARCHAR(50) NOT NULL
);
  
CREATE TABLE characters (
  character_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  player_id INT UNSIGNED,
  name VARCHAR(30) NOT NULL,
  level INT UNSIGNED
  
  FOREIGN KEY (player_id)
  REFERENCES players (player_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE
);

CREATE TABLE winners (
  character_id INT UNSIGNED,
  name VARCHAR(30) NOT NULL
  
  FOREIGN KEY (character_id)
  REFERENCES characters (character_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE
);

CREATE TABLE character_stats (
  character_id INT UNSIGNED,
  health TINYINT NOT NULL,
  armor TINYINT NOT NULL
  
  FOREIGN KEY (character_id)
  REFERENCES characters (character_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE
);

CREATE TABLE teams (
  team_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  name VARCHAR(30)
);

CREATE TABLE team_members (
  team_member_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  team_id INT UNSIGNED,
  character_id INT UNSIGNED
  
  FOREIGN KEY (team_id)
  REFERENCES teams (team_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE,
  
  FOREIGN KEY (character_id)
  REFERENCES characters (character_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE
);

CREATE TABLE items (
  item_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  name VARCHAR(30),
  armor INT UNSIGNED,
  damage INT UNSIGNED
);

CREATE TABLE inventory (
  inventory_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  character_id INT UNSIGNED,
  item_id INT UNSIGNED
  
  FOREIGN KEY (character_id)
  REFERENCES characters (character_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE,
  
  FOREIGN KEY (item_id)
  REFERENCES items (item_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE
);

CREATE TABLE equipped (
  equipped_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  character_id INT UNSIGNED,
  item_id INT UNSIGNED
  
  FOREIGN KEY (character_id)
  REFERENCES characters (character_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE,
  
  FOREIGN KEY (item_id)
  REFERENCES items (item_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE
);
