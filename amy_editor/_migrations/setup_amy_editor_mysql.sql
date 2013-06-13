/*
	Amy Editor - initial SQL script
 		MySQL 5+ version
*/

/* 
	Installation:
	open mysql console: mysql -uroot -p amy_editor
	mysql> charset utf8;
	mysql> DELIMITER $$
	mysql> \. setup_amy_editor_mysql.sql
	mysql> DELIMITER ;
*/
-- phpMyAdmin SQL Dump
-- version 3.5.3
-- http://www.phpmyadmin.net
--
-- Client: localhost
-- Généré le: Jeu 13 Juin 2013 à 14:57
-- Version du serveur: 5.1.66-0+squeeze1
-- Version de PHP: 5.3.3-7+squeeze15

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

--
-- Base de données: `amy_editor`
--
DROP DATABASE IF EXISTS `amy_editor`;
CREATE DATABASE `amy_editor` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `amy_editor`;

DELIMITER $$
--
-- Procédures
--
DROP PROCEDURE IF EXISTS `amy_user_create`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `amy_user_create`(
	_username varchar(64),
	_hashed_password varchar(32),
	_service varchar(12),
	_email varchar(64),
	_nickname varchar(48),
	_picture varchar(255),
	_bio text
)
BEGIN
	DECLARE	_id integer;

	INSERT INTO amy_users(username, hashed_password, service, email, nickname, picture, bio) VALUES (_username, _hashed_password, _service, _email, _nickname, _picture, _bio);
	SET _id = LAST_INSERT_ID();
	-- adding support person into addressbook
	CALL amy_user_create_relation(_id, 2);
	SELECT * FROM amy_users WHERE id=_id;
END$$

DROP PROCEDURE IF EXISTS `amy_user_find_relations`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `amy_user_find_relations`(
	_user_id integer
)
BEGIN
	SELECT ur.related_user_id AS user_id, ur.created_at, u.username, u.service, u.email, u.nickname, u.picture FROM amy_user_relations AS ur INNER JOIN amy_users AS u ON  ur.related_user_id=u.id WHERE ur.user_id=_user_id ORDER BY u.nickname;
	SELECT 0 AS user_id, ucr.created_at, '' AS username, '' AS service, ucr.email, ucr.nickname, '' FROM amy_user_custom_relations AS ucr WHERE ucr.user_id=_user_id ORDER BY  ucr.nickname;
END$$

DROP PROCEDURE IF EXISTS `amy_user_update_relation`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `amy_user_update_relation`(
	_user_id integer,
	_original_email varchar(128),
	_nickname varchar(128),
	_email varchar(128)
)
BEGIN
	DECLARE _rel_id integer;
	DECLARE _ref_user_id integer;

	SELECT id INTO _rel_id FROM amy_user_custom_relations WHERE user_id=_user_id AND email=_original_email;
	
	IF NOT FOUND THEN
		-- checking existing users
		SELECT id INTO _ref_user_id FROM amy_users WHERE email=_email;
		IF FOUND THEN
			SELECT amy_user_create_relation(_user_id, _ref_user_id);
		ELSE
			SELECT amy_user_create_relation(_user_id, _nickname, _email);
		END IF;
	ELSE
		UPDATE amy_user_custom_relations SET nickname=_nickname, email=_email WHERE id=_rel_id;
	END IF;
	CALL amy_user_find_relations(_user_id);
	-- SELECT * FROM CALL amy_user_find_relations(_user_id) WHERE email=_email LIMIT 1;
END$$

--
-- Fonctions
--
DROP FUNCTION IF EXISTS `amy_user_create_relation`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `amy_user_create_relation`(
	_user_id integer,
	_related_user_id integer,
	_nickname varchar(128),
	_email varchar(128)
) RETURNS char(1) CHARSET utf8
BEGIN
	IF _nickname IS NULL THEN
		INSERT INTO amy_user_relations (user_id, related_user_id) VALUES (_user_id, _related_user_id);
	ELSE
		INSERT INTO amy_user_custom_relations (user_id, nickname, email) VALUES (_user_id, _nickname, _email);
	END IF;
	RETURN 't';
END$$

DROP FUNCTION IF EXISTS `amy_user_delete`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `amy_user_delete`(
	_id integer
) RETURNS char(1) CHARSET utf8
BEGIN
	DELETE FROM amy.coll_users WHERE external_ref=_id;
	DELETE FROM amy.user_relations WHERE user_id=_id OR related_user_id=_id;
	DELETE FROM amy.user_custom_relations WHERE user_id=_id;
	DELETE FROM amy.users WHERE id=_id;
	RETURN 't';
END$$

DROP FUNCTION IF EXISTS `amy_user_delete_relation`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `amy_user_delete_relation`(
	_user_id integer,
	_related_user_id integer,
	_email varchar(128)
) RETURNS char(1) CHARSET utf8
BEGIN
	IF _email IS NULL THEN
		DELETE FROM amy_user_relations WHERE user_id=_user_id AND related_user_id=_related_user_id;
	ELSE
		DELETE FROM amy.user_custom_relations WHERE user_id=_user_id AND email=_email;
	END IF;
	RETURN 't';
END$$

DROP FUNCTION IF EXISTS `amy_util_get_random_hash`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `amy_util_get_random_hash`() RETURNS varchar(32) CHARSET utf8
    NO SQL
RETURN md5(concat( cast(4434783*rand() AS CHAR), cast(CURRENT_TIMESTAMP AS CHAR)))$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `amy_user_custom_relations`
--

DROP TABLE IF EXISTS `amy_user_custom_relations`;
CREATE TABLE IF NOT EXISTS `amy_user_custom_relations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `nickname` varchar(64) NOT NULL,
  `email` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_id_email` (`user_id`,`email`),
  KEY `idx_user_custom_relations_user_id` (`user_id`),
  KEY `idx_user_custom_relations_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Structure de la table `amy_user_relations`
--

DROP TABLE IF EXISTS `amy_user_relations`;
CREATE TABLE IF NOT EXISTS `amy_user_relations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `related_user_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_id_related_user_id` (`user_id`,`related_user_id`),
  KEY `idx_user_relations_user_id` (`user_id`),
  KEY `idx_user_relations_related_user_id` (`related_user_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 ;

--
-- Contenu de la table `amy_user_relations`
--

INSERT INTO `amy_user_relations` (`id`, `user_id`, `related_user_id`, `created_at`) VALUES
(1, 3, 2, '2013-06-13 12:48:26');

-- --------------------------------------------------------

--
-- Structure de la table `amy_users`
--

DROP TABLE IF EXISTS `amy_users`;
CREATE TABLE IF NOT EXISTS `amy_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `hashed_password` char(32) NOT NULL,
  `service` varchar(12) NOT NULL DEFAULT 'amy',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_logged_at` timestamp NULL DEFAULT NULL,
  `email` varchar(64) DEFAULT NULL,
  `nickname` varchar(48) DEFAULT NULL,
  `picture` varchar(255) DEFAULT NULL,
  `bio` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_username_service` (`username`,`service`),
  KEY `idx_users_username` (`username`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=5 ;

--
-- Contenu de la table `amy_users`
--

INSERT INTO `amy_users` (`id`, `username`, `hashed_password`, `service`, `created_at`, `last_logged_at`, `email`, `nickname`, `picture`, `bio`) VALUES
(1, 'default', 'c21f969b5f03d33d43e04f8f136e7682', 'amy', '2013-06-13 11:34:23', NULL, 'info@april-child.com', 'Anonymous', 'mm/i/pictures/f.png', ''),
(2, 'support', '434990c8a25d2be94863561ae98bd682', 'amy', '2013-06-13 11:34:23', NULL, 'info@april-child.com', 'Amy Editor Support', 'mm/i/icon-48.png', 'This is the Amy Editor support person trying to help you in case of troubles.'),
(3, 'p', '83878c91171338902e0fe0fb97a8c47a', 'amy', '2013-06-13 11:34:23', NULL, 'petr@krontorad.com', 'Petr Krontorád', 'mm/i/pictures/l.png', 'Author of the editor.'),
(4, 'aprilchild', '83878c91171338902e0fe0fb97a8c47a', 'amy', '2013-06-13 11:34:23', NULL, 'p@april-child.com', 'Petr @ AprilChild', 'mm/i/pictures/m.png', 'Author of the editor.');
