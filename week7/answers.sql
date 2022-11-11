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
	FROM inventory
	WHERE inventory.inventory_id = find_item_by_id;
    
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
	FROM equipped
	WHERE equipped.equipped_id = find_item_by_id;
    
	DELETE FROM equipped WHERE equipped.equipped_id = find_item_by_id; 
END;;

CREATE PROCEDURE set_winners(team_id INT UNSIGNED)
BEGIN
	DECLARE find_winners_by_team_id INT UNSIGNED;
    	SELECT team_id INTO find_winners_by_team_id;
    
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
	WHERE teams.team_id = find_winners_by_team_id;
END;;

CREATE FUNCTION armor_total(character_id INT UNSIGNED)
RETURNS TINYINT
DETERMINISTIC 
BEGIN
	DECLARE find_armor_total_by_character_id INT UNSIGNED;
	DECLARE sum_of_character_armor_from_items TINYINT;
	DECLARE sum_of_character_natural_armor TINYINT;
	DECLARE total_sum_of_armor TINYINT;
    
	SELECT character_id INTO find_armor_total_by_character_id;
    
	SELECT 
		SUM(items.armor)
	FROM equipped
		INNER JOIN items
			ON equipped.item_id = items.item_id
	WHERE equipped.character_id = find_armor_total_by_character_id
    	INTO sum_of_character_armor_from_items;
    
	SELECT character_stats.armor 
	FROM character_stats 
	WHERE character_stats.character_id = find_armor_total_by_character_id
	INTO sum_of_character_natural_armor;

	SELECT sum_of_character_armor_from_items + sum_of_character_natural_armor INTO total_sum_of_armor;

Return total_sum_of_armor;
END;;

DELIMITER ;

CREATE OR REPLACE VIEW character_items AS
SELECT 
	characters.name AS username,
	items.name AS item,
	items.armor,
	items.damage
FROM characters
	INNER JOIN inventory
		ON characters.character_id = inventory.character_id
	INNER JOIN items
		ON inventory.item_id = items.item_id
UNION
SELECT 
	characters.name AS username,
	items.name AS item,
	items.armor,
	items.damage
FROM characters
	INNER JOIN equipped
		ON characters.character_id = equipped.character_id
	INNER JOIN items
		ON equipped.item_id = items.item_id;



CREATE OR REPLACE VIEW team_items AS
SELECT 
	teams.team_id,
	teams.name AS name,
	items.name AS item,
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
	teams.name AS team,
	items.name AS item,
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
		ON equipped.item_id = items.item_id;
