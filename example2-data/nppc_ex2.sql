-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Oct 11, 2020 at 07:22 PM
-- Server version: 10.0.28-MariaDB
-- PHP Version: 7.3.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `nppc_ex2`
--

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `assignRouteToOrder`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `assignRouteToOrder` (IN `_client_id` BIGINT UNSIGNED, IN `_order` VARCHAR(50), IN `_route` INT)  NO SQL
    COMMENT 'sets route to added order'
update routes set route=_route where client_id = _client_id and number like _order$$

DROP PROCEDURE IF EXISTS `assignWorkcenterToRoutePart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `assignWorkcenterToRoutePart` (IN `_client_id` BIGINT UNSIGNED, IN `_order_id` BIGINT UNSIGNED, IN `_order_part` VARCHAR(4096), IN `_operation` VARCHAR(250), IN `_wc` VARCHAR(50), IN `_bucket` VARCHAR(10))  NO SQL
insert into assigns  (client_id, order_id, order_part, operation, workcenter_id, bucket) VALUES(_client_id, _order_id, _order_part, _operation, getWorkcenterID(_client_id, _wc), _bucket)$$

DROP PROCEDURE IF EXISTS `deleteOrder`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteOrder` (IN `_client_id` BIGINT UNSIGNED, IN `_order` VARCHAR(50))  NO SQL
begin
set @orid = (select id from orders where client_id=_client_id and number like _order);
delete from assigns where client_id=_client_id and order_id = @orid;
delete from orders where client_id=_client_id and number like _order;

end$$

DROP PROCEDURE IF EXISTS `getAssignsByRoads`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignsByRoads` (IN `_client_id` BIGINT UNSIGNED, IN `_wc_from` VARCHAR(50), IN `_wc_to` VARCHAR(50))  NO SQL
BEGIN
SELECT assigns.*, orders.number FROM assigns 
left join orders on orders.id=assigns.order_id
WHERE bucket like  'OUTCOME' and getWorkcenterID(_client_id, _wc_from) = workcenter_id and getWorkcenterID(_client_id, _wc_to) = next_workcenter_id;
end$$

DROP PROCEDURE IF EXISTS `getAssignsByWorkcenter`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignsByWorkcenter` (IN `_client_id` BIGINT UNSIGNED, IN `_wc` VARCHAR(50), IN `_buckets` VARCHAR(250))  NO SQL
BEGIN
set @wc_id = getWorkcenterID(_client_id, _wc);
select a.*, orders.number, orders.state from (select id, order_id, bucket, order_part, event_time from assigns where client_id = _client_id and workcenter_id = @wc_id and find_in_set(bucket, _buckets) > 0) as a left join orders on orders.id = a.order_id;
end$$

DROP PROCEDURE IF EXISTS `getAssignsCount`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignsCount` (IN `_client_id` BIGINT UNSIGNED, IN `_buckets` VARCHAR(250))  NO SQL
BEGIN
select workcenters.name, b.* from (select workcenter_id, operation, count(id) as assings_count from assigns as a where client_id = _client_id and find_in_set(bucket, _buckets) > 0 group by a.workcenter_id, a.operation) as b left join workcenters on workcenters.id = b.workcenter_id;
end$$

DROP PROCEDURE IF EXISTS `getBuckets`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getBuckets` (IN `_widget` INT)  NO SQL
SELECT bucket from workcenter_bucket where showit =_widget  order by orderby$$

DROP PROCEDURE IF EXISTS `getMessages`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getMessages` (IN `_client_id` BIGINT UNSIGNED, IN `_tags` VARCHAR(250), IN `_to` BIGINT UNSIGNED, IN `_read` BOOLEAN, IN `_types` VARCHAR(50))  NO SQL
BEGIN
if _to = '' THEN
	set _to = null;
end if;
if _types = '' THEN
	set _types = (select GROUP_CONCAT(message_type) from message_types);
end if;
if _read THEN
    select messages.id, users.name as user_name, messages.message_time, messages.message_type, messages.body from messages 
    left join users on users.id = messages.message_from
    left JOIN messages_read on messages.id = messages_read.message_id and messages_read.user_id = messages.message_to 
    where messages.client_id = _client_id and (message_to = _to or message_to is null) and find_in_set(message_type, _types) > 0;
else 
    select messages.id, users.name as user_name, messages.message_time, messages.message_type, messages.body from messages 
    left join users on users.id = messages.message_from
    left JOIN messages_read on messages.id = messages_read.message_id and messages_read.user_id = messages.message_to 
    where messages.client_id = _client_id and (message_to = _to or message_to is null)and find_in_set(message_type, _types) > 0 and messages_read.id is null;

end if;
end$$

DROP PROCEDURE IF EXISTS `getRoadsWorkload`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getRoadsWorkload` (IN `_client_id` INT)  NO SQL
SELECT s.name as src_wc_name, d.name as dst_wc_name, COUNT(assigns.id) as ready_count from assigns 
left join workcenters as s on assigns.workcenter_id = s.id
left join workcenters as d on assigns.next_workcenter_id = d.id
where assigns.client_id = _client_id and bucket like 'OUTCOME'
group by workcenter_id, next_workcenter_id$$

DROP PROCEDURE IF EXISTS `moveAssignToNextBucket`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `moveAssignToNextBucket` (IN `_id` BIGINT UNSIGNED)  NO SQL
    COMMENT 'moves order part forward and returns new bucket'
begin
set @cur_bucket = (select bucket from assigns where id=_id);
set @new_bucket = '';
if @cur_bucket = 'INCOME' THEN
set @new_bucket = 'PROCESSING';
end if;
if @cur_bucket = 'PROCESSING' THEN
set @new_bucket = 'OUTCOME';
end if;
if @new_bucket <> '' THEN
UPDATE assigns set bucket = @new_bucket where id=_id;
end if;
SELECT orders.number as order_num, orders.current_route as route_num, @new_bucket as next_bucket, assigns.order_part FROM `assigns` left join orders on assigns.order_id = orders.id WHERE assigns.id=_id;
end$$

DROP PROCEDURE IF EXISTS `moveAssignToNextWorkcenter`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `moveAssignToNextWorkcenter` (IN `_assign_id` BIGINT UNSIGNED)  NO SQL
BEGIN
select client_id, next_workcenter_id, next_order_part, next_operation, order_id
into @client_id, @next_workcenter_id, @next_order_part, @next_operation, @order_id
from assigns
where id=_assign_id;
START TRANSACTION;
insert into assigns (client_id, workcenter_id, order_id, order_part, operation, bucket) values(@client_id, @next_workcenter_id, @order_id, @next_order_part, @next_operation, 'INCOME');
update assigns set bucket = null, next_id = LAST_INSERT_ID() WHERE id = _assign_id;
COMMIT;
end$$

DROP PROCEDURE IF EXISTS `updateAssignOrderPart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateAssignOrderPart` (IN `_id` BIGINT UNSIGNED, IN `_new_order_part` VARCHAR(250), IN `_next_wc` VARCHAR(50), IN `_next_order_part` VARCHAR(4096), IN `_next_operation` VARCHAR(250))  NO SQL
update assigns set order_part = _new_order_part, operation = NULL, next_workcenter_id = getWorkcenterID(assigns.client_id, _next_wc), next_order_part = _next_order_part, next_operation = _next_operation where id=_id$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `addMessage`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `addMessage` (`_client_id` BIGINT UNSIGNED, `_message_from` BIGINT UNSIGNED, `_message_to` BIGINT UNSIGNED, `_message_type` VARCHAR(9), `_body` VARCHAR(250), `_thread_id` BIGINT UNSIGNED) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'adds new Message'
BEGIN
if _message_to = 0 THEN
	set _message_to = NULL;
end IF;

if _message_from = 0 THEN
	set _message_from = NULL;
end IF;

if _thread_id = 0 THEN
	set _thread_id = NULL;
end IF;

INSERT INTO `messages`(`client_id`, `message_from`, `message_to`, `message_type`, `body`, thread_id) VALUES (_client_id, _message_from, _message_to, _message_type, _body, _thread_id);
return (SELECT LAST_INSERT_ID());

end$$

DROP FUNCTION IF EXISTS `addOrder`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `addOrder` (`_client_id` BIGINT UNSIGNED, `_number` VARCHAR(50), `_state` VARCHAR(10), `_route_id` INT) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'adds new order and returns uniq ID of order in database'
begin
insert into orders (number, client_id, state, current_route) values(_number, _client_id, _state, _route_id);
return (SELECT LAST_INSERT_ID());
end$$

DROP FUNCTION IF EXISTS `getClientID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getClientID` (`_factoryName` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'returns client ID by mnemonic name of the factory'
return (select id from clients where name like _factoryName)$$

DROP FUNCTION IF EXISTS `getUserID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getUserID` (`_client_id` BIGINT UNSIGNED, `_name` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'returns iser''s id by mnemonic id of one'
return (select id from users where client_id = _client_id and `name` like _name)$$

DROP FUNCTION IF EXISTS `getWorkcenterID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getWorkcenterID` (`_client_id` BIGINT UNSIGNED, `_name` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'returns workcenter''s id by mnemonic id of one'
return (select id from workcenters where client_id = _client_id and `name` like _name)$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `assigns`
--

DROP TABLE IF EXISTS `assigns`;
CREATE TABLE IF NOT EXISTS `assigns` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq ID',
  `client_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Ref to order ID',
  `order_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Ref to order ID',
  `workcenter_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Ref to workcenter',
  `bucket` varchar(10) DEFAULT NULL COMMENT 'Name of bucket: income, procdssing, outcome, gone',
  `order_part` varchar(4096) NOT NULL COMMENT 'Part of the order which proceed the workcenter',
  `operation` varchar(250) NOT NULL,
  `prodmat` varchar(50) DEFAULT NULL,
  `next_workcenter_id` bigint(20) UNSIGNED DEFAULT NULL,
  `next_order_part` varchar(4096) DEFAULT NULL,
  `next_operation` varchar(250) DEFAULT NULL,
  `event_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Date and time of event',
  `next_id` bigint(20) UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `client_id` (`client_id`,`order_id`,`workcenter_id`),
  KEY `order_id` (`order_id`),
  KEY `workcenter_id` (`workcenter_id`),
  KEY `bucket` (`bucket`),
  KEY `operation` (`operation`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `assigns`
--

INSERT INTO `assigns` (`id`, `client_id`, `order_id`, `workcenter_id`, `bucket`, `order_part`, `operation`, `prodmat`, `next_workcenter_id`, `next_order_part`, `next_operation`, `event_time`, `next_id`) VALUES
(1, 1, 1, 1, NULL, '1.1.wheelpair.1.1.shaft.1.1', '', NULL, 4, '1.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-11 18:55:48', 13),
(2, 1, 1, 5, 'INCOME', '1.1.wheelpair.1.1.wheel.1', 'supplywheel', NULL, NULL, NULL, NULL, '2020-10-11 18:36:53', NULL),
(3, 1, 2, 1, 'INCOME', 'ord12.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', NULL, NULL, NULL, NULL, '2020-10-11 18:36:53', NULL),
(4, 1, 2, 5, NULL, 'ord12.1.wheelpair.1.1.wheel', '', NULL, 3, 'ord12.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-11 18:57:25', 14),
(5, 1, 3, 1, 'OUTCOME', 'ord13.1.wheelpair.1.1.shaft.1.1', '', NULL, 4, 'ord13.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-11 18:37:05', NULL),
(6, 1, 3, 5, 'INCOME', 'ord13.1.wheelpair.1.1.wheel.1', 'supplywheel', NULL, NULL, NULL, NULL, '2020-10-11 18:36:54', NULL),
(7, 1, 4, 1, 'OUTCOME', 'ord14.1.wheelpair.1.1.shaft.1.1', '', NULL, 4, 'ord14.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-11 19:11:56', NULL),
(8, 1, 4, 5, 'INCOME', 'ord14.1.wheelpair.1.1.wheel.1', 'supplywheel', NULL, NULL, NULL, NULL, '2020-10-11 18:36:54', NULL),
(9, 1, 5, 1, NULL, 'ord15.1.wheelpair.1.1.shaft.1.1', '', NULL, 4, 'ord15.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-11 19:11:40', 15),
(10, 1, 5, 5, 'OUTCOME', 'ord15.1.wheelpair.1.1.wheel', '', NULL, 3, 'ord15.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-11 18:57:38', NULL),
(11, 1, 6, 1, 'OUTCOME', '2386.1.wheelpair.1.1.shaft.1.1', '', NULL, 4, '2386.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-11 19:11:01', NULL),
(12, 1, 6, 5, 'INCOME', '2386.1.wheelpair.1.1.wheel.1', 'supplywheel', NULL, NULL, NULL, NULL, '2020-10-11 18:36:54', NULL),
(13, 1, 1, 4, 'INCOME', '1.1.wheelpair.1.1.shaft.1', 'blankprocessing', NULL, NULL, NULL, NULL, '2020-10-11 18:55:47', NULL),
(14, 1, 2, 3, 'INCOME', 'ord12.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, '2020-10-11 18:57:25', NULL),
(15, 1, 5, 4, 'INCOME', 'ord15.1.wheelpair.1.1.shaft.1', 'blankprocessing', NULL, NULL, NULL, NULL, '2020-10-11 19:11:40', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
CREATE TABLE IF NOT EXISTS `clients` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq id',
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_index` (`name`) USING HASH
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COMMENT='Client in one database';

--
-- Dumping data for table `clients`
--

INSERT INTO `clients` (`id`, `name`) VALUES
(2, 'example1'),
(1, 'example2');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
CREATE TABLE IF NOT EXISTS `messages` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq id',
  `message_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `message_from` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'from person',
  `message_to` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'to person or broadcast',
  `message_type` varchar(10) NOT NULL COMMENT 'INFO, WARNING, CRITICAL',
  `body` varchar(160) NOT NULL,
  `thread_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Previous message in thread',
  PRIMARY KEY (`id`),
  KEY `from_index` (`message_from`),
  KEY `message_type` (`message_type`),
  KEY `message_to` (`message_to`),
  KEY `client_id` (`client_id`),
  KEY `thread_id` (`thread_id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8 COMMENT='Messages of users';

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `message_time`, `client_id`, `message_from`, `message_to`, `message_type`, `body`, `thread_id`) VALUES
(5, '2020-10-02 09:07:54', 1, 1, NULL, 'danger', 'Text', NULL),
(6, '2020-10-11 12:15:15', 1, 1, NULL, 'primary', 'Order \'ord12\' processed as \'ord12.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(7, '2020-10-11 12:21:36', 1, 1, NULL, 'primary', 'Order \'ord14\' processed as \'ord14.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(8, '2020-10-11 12:22:39', 1, 1, NULL, 'primary', 'Order \'1\' processed as \'1.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(9, '2020-10-11 12:29:19', 1, 1, NULL, 'primary', 'Order \'ord12\' processed as \'ord12.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(10, '2020-10-11 12:31:12', 1, 1, NULL, 'primary', 'Order \'2386\' processed as \'2386.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(11, '2020-10-11 16:46:35', 1, 1, NULL, 'primary', 'Order \'1\' processed as \'1.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(12, '2020-10-11 17:05:26', 1, 1, NULL, 'primary', 'Order \'ord12\' processed as \'ord12.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(13, '2020-10-11 18:17:54', 1, 1, NULL, 'primary', 'Order \'ord15\' processed as \'ord15.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(14, '2020-10-11 18:37:06', 1, 1, NULL, 'primary', 'Order \'ord13\' processed as \'ord13.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(15, '2020-10-11 18:53:42', 1, 1, NULL, 'primary', 'Order \'1\' processed as \'1.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(16, '2020-10-11 18:57:16', 1, 1, NULL, 'primary', 'Order \'ord12\' processed as \'ord12.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(17, '2020-10-11 18:57:38', 1, 1, NULL, 'primary', 'Order \'ord15\' processed as \'ord15.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(18, '2020-10-11 19:11:01', 1, 1, NULL, 'primary', 'Order \'2386\' processed as \'2386.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(19, '2020-10-11 19:11:17', 1, 1, NULL, 'primary', 'Order \'ord15\' processed as \'ord15.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(20, '2020-10-11 19:11:56', 1, 1, NULL, 'primary', 'Order \'ord14\' processed as \'ord14.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `messages_read`
--

DROP TABLE IF EXISTS `messages_read`;
CREATE TABLE IF NOT EXISTS `messages_read` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `message_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `read_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `message_id` (`message_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='Info about read events';

-- --------------------------------------------------------

--
-- Table structure for table `message_types`
--

DROP TABLE IF EXISTS `message_types`;
CREATE TABLE IF NOT EXISTS `message_types` (
  `message_type` varchar(10) NOT NULL,
  PRIMARY KEY (`message_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `message_types`
--

INSERT INTO `message_types` (`message_type`) VALUES
('danger'),
('primary'),
('success'),
('warning');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
CREATE TABLE IF NOT EXISTS `orders` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `number` varchar(50) NOT NULL,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `state` varchar(10) NOT NULL,
  `current_route` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `number` (`number`),
  KEY `client_id` (`client_id`),
  KEY `state` (`state`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `number`, `client_id`, `state`, `current_route`) VALUES
(1, '1', 1, 'ASSIGNED', 1),
(2, 'ord12', 1, 'ASSIGNED', 1),
(3, 'ord13', 1, 'ASSIGNED', 1),
(4, 'ord14', 1, 'ASSIGNED', 1),
(5, 'ord15', 1, 'ASSIGNED', 1),
(6, '2386', 1, 'ASSIGNED', 1);

-- --------------------------------------------------------

--
-- Table structure for table `order_states`
--

DROP TABLE IF EXISTS `order_states`;
CREATE TABLE IF NOT EXISTS `order_states` (
  `order_state` varchar(10) NOT NULL,
  PRIMARY KEY (`order_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `order_states`
--

INSERT INTO `order_states` (`order_state`) VALUES
('ABANDONED'),
('ASSIGNED'),
('PAUSED'),
('POSTPONED'),
('STOPPED');

-- --------------------------------------------------------

--
-- Table structure for table `roads`
--

DROP TABLE IF EXISTS `roads`;
CREATE TABLE IF NOT EXISTS `roads` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL,
  `from_wc` bigint(20) UNSIGNED NOT NULL,
  `to_wc` bigint(20) UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `from_wc` (`from_wc`),
  KEY `client_id` (`client_id`),
  KEY `to_wc` (`to_wc`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `roads`
--

INSERT INTO `roads` (`id`, `client_id`, `name`, `from_wc`, `to_wc`) VALUES
(1, 1, 'road1', 1, 4),
(2, 1, 'road3', 4, 3),
(5, 1, 'road4', 5, 3),
(6, 1, 'road7', 3, 2);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`,`client_id`) USING BTREE,
  KEY `client_id` (`client_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='users table referenced to factory xml';

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `client_id`, `name`) VALUES
(1, 1, 'David Rhuxel');

-- --------------------------------------------------------

--
-- Table structure for table `workcenters`
--

DROP TABLE IF EXISTS `workcenters`;
CREATE TABLE IF NOT EXISTS `workcenters` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `client_id` (`client_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `workcenters`
--

INSERT INTO `workcenters` (`id`, `client_id`, `name`) VALUES
(1, 1, 'wc1_1'),
(2, 1, 'wc2_4'),
(3, 1, 'wc2_3'),
(4, 1, 'wc1_3'),
(5, 1, 'wc2_1');

-- --------------------------------------------------------

--
-- Table structure for table `workcenter_bucket`
--

DROP TABLE IF EXISTS `workcenter_bucket`;
CREATE TABLE IF NOT EXISTS `workcenter_bucket` (
  `bucket` varchar(10) NOT NULL,
  `orderby` int(11) DEFAULT NULL,
  `showit` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`bucket`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `workcenter_bucket`
--

INSERT INTO `workcenter_bucket` (`bucket`, `orderby`, `showit`) VALUES
('GONE', 5, 0),
('INCOME', 1, 1),
('OUTCOME', 3, 1),
('PROCESSING', 2, 1),
('REJECT', 4, 2);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `messages`
--
ALTER TABLE `messages` ADD FULLTEXT KEY `body` (`body`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `assigns`
--
ALTER TABLE `assigns`
  ADD CONSTRAINT `assigns_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`),
  ADD CONSTRAINT `assigns_ibfk_2` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
  ADD CONSTRAINT `assigns_ibfk_3` FOREIGN KEY (`workcenter_id`) REFERENCES `workcenters` (`id`),
  ADD CONSTRAINT `assigns_ibfk_4` FOREIGN KEY (`bucket`) REFERENCES `workcenter_bucket` (`bucket`);

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`message_type`) REFERENCES `message_types` (`message_type`),
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`message_to`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `messages_ibfk_3` FOREIGN KEY (`message_from`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `messages_ibfk_4` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`),
  ADD CONSTRAINT `messages_ibfk_5` FOREIGN KEY (`thread_id`) REFERENCES `messages` (`id`);

--
-- Constraints for table `messages_read`
--
ALTER TABLE `messages_read`
  ADD CONSTRAINT `messages_read_ibfk_1` FOREIGN KEY (`message_id`) REFERENCES `messages` (`id`),
  ADD CONSTRAINT `messages_read_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`state`) REFERENCES `order_states` (`order_state`);

--
-- Constraints for table `roads`
--
ALTER TABLE `roads`
  ADD CONSTRAINT `roads_ibfk_1` FOREIGN KEY (`from_wc`) REFERENCES `workcenters` (`id`),
  ADD CONSTRAINT `roads_ibfk_2` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`),
  ADD CONSTRAINT `roads_ibfk_3` FOREIGN KEY (`to_wc`) REFERENCES `workcenters` (`id`);

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`);

--
-- Constraints for table `workcenters`
--
ALTER TABLE `workcenters`
  ADD CONSTRAINT `workcenters_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
