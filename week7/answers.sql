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
	level TINYINT,

	CONSTRAINT characters_fk_players
		FOREIGN KEY (player_id)
		REFERENCES players (player_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE winners (
	character_id INT UNSIGNED,
	name VARCHAR(30) NOT NULL,

	CONSTRAINT winners_fk_characters
		FOREIGN KEY (character_id)
		REFERENCES characters (character_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE character_stats (
	character_id INT UNSIGNED,
	health TINYINT NOT NULL,
	armor TINYINT NOT NULL,

	CONSTRAINT character_stats_fk_characters
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
	character_id INT UNSIGNED,
  
	CONSTRAINT team_members_fk_teams
		FOREIGN KEY (team_id)
		REFERENCES teams (team_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
  
	CONSTRAINT team_members_fk_characters
		FOREIGN KEY (character_id)
		REFERENCES characters (character_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE items (
	item_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	name VARCHAR(30),
	armor INT UNSIGNED NOT NULL,
	damage INT UNSIGNED NOT NULL
);

CREATE TABLE inventory (
	inventory_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	character_id INT UNSIGNED,
	item_id INT UNSIGNED,
  
	CONSTRAINT inventory_fk_characters
		FOREIGN KEY (character_id)
		REFERENCES characters (character_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
  
	CONSTRAINT inventory_fk_items
		FOREIGN KEY (item_id)
		REFERENCES items (item_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE equipped (
	equipped_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	character_id INT UNSIGNED,
	item_id INT UNSIGNED,
  
	CONSTRAINT equipped_fk_characters
		FOREIGN KEY (character_id)
		REFERENCES characters (character_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
  
	CONSTRAINT equipped_fk_items
		FOREIGN KEY (item_id)
		REFERENCES items (item_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

DELIMITER ;;
CREATE PROCEDURE equip(inventory_id INT UNSIGNED)
BEGIN
	DECLARE find_item_by_id INT UNSIGNED;
	SELECT inventory_id INTO find_item_by_id;

	INSERT INTO equipped
	SELECT 
		inventory.inventory_id,
		inventory.character_id,
		inventory.item_id
	FROM inventory;

	DELETE FROM inventory WHERE inventory.inventory_id = find_item_by_id; 
END;;

CREATE PROCEDURE unequip(equipped_id INT UNSIGNED)
BEGIN
	DECLARE find_item_by_id INT UNSIGNED;
	SELECT equipped_id INTO find_item_by_id;

	INSERT INTO inventory
	SELECT 
		equipped.equipped_id,
		equipped.character_id,
		equipped.item_id
	FROM equipped;

	DELETE FROM equipped WHERE equipped.equipped_id = find_item_by_id;
END;;

CREATE PROCEDURE set_winners(team_id INT UNSIGNED)
BEGIN
	DECLARE find_winner_by_team_id INT UNSIGNED;
	SELECT team_id INTO find_winner_by_team_id;

	DELETE FROM winners;

	INSERT INTO winners
	SELECT 
		characters.character_id,
		characters.name
	FROM teams
		INNER JOIN team_members
			ON teams.team_id = team_members.team_id
		INNER JOIN characters
			ON team_members.character_id = characters.character_id
	WHERE teams.team_id = find_winner_by_team_id;
END;;

CREATE FUNCTION armor_total(character_id INT UNSIGNED)
RETURNS TINYINT
DETERMINISTIC 
BEGIN
	DECLARE find_armor_total_by_character_id INT UNSIGNED;
	DECLARE armor_from_items TINYINT;
	DECLARE natural_armor TINYINT;

	SELECT character_id INTO find_armor_total_by_character_id;

	SELECT 
		SUM(items.armor)
	FROM equipped
		INNER JOIN items
			ON equipped.item_id = items.item_id
	WHERE equipped.character_id = find_armor_total_by_character_id
	INTO armor_from_items;

	SELECT character_stats.armor 
	FROM character_stats 
	WHERE character_stats.character_id = find_armor_total_by_character_id
	INTO natural_armor;

	Return armor_from_items + natural_armor;

Return total_sum_of_armor;
END;;

CREATE PROCEDURE attack(id_of_character_being_attacked INT UNSIGNED, id_of_equipped_item_used_for_attack INT UNSIGNED)
BEGIN
	DECLARE find_dmg_by_item_id INT UNSIGNED;	
	DECLARE character_being_attacked INT UNSIGNED;
    
	DECLARE weapon_dmg TINYINT;
	DECLARE dmg_dealt TINYINT;
	DECLARE character_armor TINYINT;
	DECLARE character_hp TINYINT;

	SELECT id_of_equipped_item_used_for_attack INTO find_dmg_by_item_id;
	SELECT id_of_character_being_attacked INTO character_being_attacked;
    
	SELECT armor_total(character_being_attacked) INTO character_armor;

	SELECT
		items.damage
	FROM items
		INNER JOIN equipped 
		ON items.item_id = equipped.item_id
	WHERE equipped.equipped_id = find_dmg_by_item_id
	INTO weapon_dmg;

	SELECT 
		character_stats.health 
	FROM character_stats 
	WHERE character_id = character_being_attacked
	INTO character_hp;

	SET dmg_dealt = weapon_dmg - character_armor;

	SET character_hp = character_hp - dmg_dealt;

	IF weapon_dmg > character_armor THEN
	    UPDATE character_stats SET health = character_hp WHERE character_id = character_being_attacked;

		IF character_hp <= 0 THEN
			DELETE FROM characters WHERE character_id = character_being_attacked;
		END IF;
   END IF;
END;;
DELIMITER ;

CREATE OR REPLACE VIEW character_items AS
SELECT 
	characters.character_id,
	characters.name AS character_name,
	items.name AS item_name,
	items.armor,
	items.damage
FROM characters
	INNER JOIN equipped
		ON characters.character_id = equipped.character_id
	INNER JOIN items
		ON equipped.item_id = items.item_id
UNION
SELECT 
	characters.character_id,
	characters.name AS character_name,
	items.name AS item_name,
	items.armor,
	items.damage
FROM characters
	INNER JOIN inventory
		ON characters.character_id = inventory.character_id
	INNER JOIN items
		ON inventory.item_id = items.item_id
ORDER BY item_name ASC;


CREATE OR REPLACE VIEW team_items AS
SELECT 
	teams.team_id,
	teams.name AS team_name,
	items.name AS item_name,
	items.armor,
	items.damage
FROM teams
	INNER JOIN team_members
		ON teams.team_id = team_members.team_id
	INNER JOIN characters
		ON team_members.character_id = characters.character_id
	INNER JOIN inventory
		ON characters.character_id = inventory.character_id
	INNER JOIN items
		ON inventory.item_id = items.item_id
    UNION
SELECT 
	teams.team_id,
	teams.name AS team_name,
	items.name AS item_name,
	items.armor,
	items.damage
FROM teams
	INNER JOIN team_members
		ON teams.team_id = team_members.team_id
	INNER JOIN characters
		ON team_members.character_id = characters.character_id
	INNER JOIN equipped
		ON characters.character_id = equipped.character_id
	INNER JOIN items
		ON equipped.item_id = items.item_id
ORDER BY item_name ASC;
