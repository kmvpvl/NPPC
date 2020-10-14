-- phpMyAdmin SQL Dump
-- version 4.6.6deb5
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Oct 14, 2020 at 05:57 PM
-- Server version: 10.3.23-MariaDB-0+deb10u1
-- PHP Version: 7.4.11

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `nppc_ex2`
--
CREATE DATABASE IF NOT EXISTS `nppc_ex2` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `nppc_ex2`;

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `assignRouteToOrder`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `assignRouteToOrder` (IN `_client_id` BIGINT UNSIGNED, IN `_order` VARCHAR(50), IN `_route` INT)  NO SQL
    COMMENT 'sets route to added order'
update routes set route=`_route` where `client_id` = `_client_id` and number like `_order`$$

DROP PROCEDURE IF EXISTS `assignWorkcenterToRoutePart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `assignWorkcenterToRoutePart` (IN `_client_id` BIGINT UNSIGNED, IN `_order_id` BIGINT UNSIGNED, IN `_order_part` VARCHAR(4096), IN `_operation` VARCHAR(250), IN `_wc` VARCHAR(50), IN `_bucket` VARCHAR(10))  NO SQL
insert into assigns  (client_id, order_id, order_part, operation, workcenter_id, bucket, fullset) VALUES(`_client_id`, `_order_id`, `_order_part`, `_operation`, getWorkcenterID(`_client_id`, `_wc`), `_bucket`, 1)$$

DROP PROCEDURE IF EXISTS `deleteOrder`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteOrder` (IN `_client_id` BIGINT UNSIGNED, IN `_order` VARCHAR(50))  NO SQL
begin
set @orid = (select id from orders where client_id=`_client_id` and number like `_order`);
delete from assigns where client_id=`_client_id` and order_id = @orid;
delete from orders where client_id=`_client_id` and number like `_order`;

end$$

DROP PROCEDURE IF EXISTS `getAssignInfo`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignInfo` (IN `_assign_id` INT)  NO SQL
SELECT assigns.order_part, assigns.next_order_part, orders.number, orders.current_route  FROM `assigns` 
left join orders on orders.id = assigns.order_id
WHERE assigns.id = `_assign_id`$$

DROP PROCEDURE IF EXISTS `getAssignsByRoads`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignsByRoads` (IN `_client_id` BIGINT UNSIGNED, IN `_wc_from` VARCHAR(50), IN `_wc_to` VARCHAR(50))  NO SQL
BEGIN
SELECT assigns.*, orders.number FROM assigns 
left join orders on orders.id=assigns.order_id
WHERE bucket like  'OUTCOME' and getWorkcenterID(_client_id, _wc_from) = workcenter_id and getWorkcenterID(`_client_id`, `_wc_to`) = next_workcenter_id;
end$$

DROP PROCEDURE IF EXISTS `getAssignsByWorkcenter`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignsByWorkcenter` (IN `_client_id` BIGINT UNSIGNED, IN `_wc` VARCHAR(50), IN `_buckets` VARCHAR(250))  NO SQL
BEGIN
set @wc_id = getWorkcenterID(_client_id, `_wc`);
select a.*, orders.number, orders.state from (select id, order_id, bucket, order_part, event_time, fullset from assigns where client_id = `_client_id` and workcenter_id = @wc_id and find_in_set(bucket, `_buckets`) > 0) as a left join orders on orders.id = a.order_id;
end$$

DROP PROCEDURE IF EXISTS `getAssignsCount`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignsCount` (IN `_client_id` BIGINT UNSIGNED, IN `_buckets` VARCHAR(250))  NO SQL
BEGIN
select workcenters.name, b.* from (select workcenter_id, operation, count(id) as assings_count from assigns as a where client_id = `_client_id` and find_in_set(bucket, `_buckets`) > 0 group by a.workcenter_id, a.operation) as b left join workcenters on workcenters.id = b.workcenter_id;
end$$

DROP PROCEDURE IF EXISTS `getBuckets`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getBuckets` (IN `_widget` INT)  NO SQL
SELECT bucket from workcenter_bucket where showit =`_widget`  order by orderby$$

DROP PROCEDURE IF EXISTS `getMessages`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getMessages` (IN `in_client_id` BIGINT UNSIGNED, IN `tags` VARCHAR(250), IN `to_user` BIGINT UNSIGNED, IN `have_read` BOOLEAN, IN `types` VARCHAR(50))  NO SQL
BEGIN
if to_user = 0 THEN
	set to_user = null;
end if;
if types = '' THEN
	set types = (select GROUP_CONCAT(message_type) from message_types);
end if;
if have_read THEN
    select messages.id, users.name as user_name, messages.message_time, messages.message_type, messages.body from messages 
    left join users on users.id = messages.message_from
    left JOIN messages_read on messages.id = messages_read.message_id and messages_read.user_id = messages.message_to 
    where messages.client_id = in_client_id and (message_to = to_user or message_to is null) and find_in_set(message_type, types) > 0;
else 
    select messages.id, users.name as user_name, messages.message_time, messages.message_type, messages.body from messages 
    left join users on users.id = messages.message_from
    left JOIN messages_read on messages.id = messages_read.message_id and messages_read.user_id = messages.message_to 
    where messages.client_id = in_client_id and (message_to = to_user or message_to is null)and find_in_set(message_type, types) > 0 and messages_read.id is null;

end if;
end$$

DROP PROCEDURE IF EXISTS `getOrderInfo`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrderInfo` (IN `_client_id` BIGINT UNSIGNED, IN `_order_num` VARCHAR(50))  NO SQL
select * from orders where client_id = `_client_id` and number like `_order_num`$$

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
set @cur_bucket = (select bucket from assigns where id=`_id`);
set @new_bucket = '';
if @cur_bucket = 'INCOME' THEN
set @new_bucket = 'PROCESSING';
end if;
if @cur_bucket = 'PROCESSING' THEN
set @new_bucket = 'OUTCOME';
end if;
if @new_bucket <> '' THEN
UPDATE assigns set bucket = @new_bucket where id=`_id`;
end if;
SELECT orders.number as order_num, orders.current_route as route_num, @new_bucket as next_bucket, assigns.order_part FROM `assigns` left join orders on assigns.order_id = orders.id WHERE assigns.id=`_id`;
end$$

DROP PROCEDURE IF EXISTS `moveAssignToNextWorkcenter`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `moveAssignToNextWorkcenter` (IN `_assign_id` BIGINT UNSIGNED, IN `_set_count` INT)  NO SQL
BEGIN
select client_id, next_workcenter_id, next_order_part, next_operation, order_id
into @client_id, @next_workcenter_id, @next_order_part, @next_operation, @order_id
from assigns
where id=`_assign_id`;
START TRANSACTION;
set @id_next = null;
set @id_next = (select id from assigns where client_id = @client_id and workcenter_id = @next_workcenter_id and order_id = @order_id);
if @id_next is null then
    insert into assigns (client_id, workcenter_id, order_id, order_part, operation, bucket) values(@client_id, @next_workcenter_id, @order_id, @next_order_part, @next_operation, 'INCOME');
    set @id_next = LAST_INSERT_ID();
    set @set_count = 1;
else
    set @set_count = (SELECT count(*)  FROM `assigns` WHERE next_id = @id_next) + 1;
end if;

if @set_count = _set_count THEN
update assigns set fullset=1 where id=@id_next;
end if;

update assigns set bucket = null, next_id = @id_next WHERE id = `_assign_id`;
COMMIT;
end$$

DROP PROCEDURE IF EXISTS `updateAssignOrderPart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateAssignOrderPart` (IN `_id` BIGINT UNSIGNED, IN `_new_order_part` VARCHAR(250), IN `_next_wc` VARCHAR(50), IN `_next_order_part` VARCHAR(4096), IN `_next_operation` VARCHAR(250))  NO SQL
update assigns set order_part = `_new_order_part`, operation = NULL, next_workcenter_id = getWorkcenterID(assigns.client_id, `_next_wc`), next_order_part = `_next_order_part`, next_operation = `_next_operation` where id=`_id`$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `addMessage`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `addMessage` (`_client_id` BIGINT UNSIGNED, `_message_from` BIGINT UNSIGNED, `_message_to` BIGINT UNSIGNED, `_message_type` VARCHAR(9), `_body` VARCHAR(250), `_thread_id` BIGINT UNSIGNED) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'adds new Message'
BEGIN
if `_message_to` = 0 THEN
set `_message_to` = NULL;
end IF;

if `_message_from` = 0 THEN
set `_message_from` = NULL;
end IF;

if `_thread_id` = 0 THEN
set `_thread_id` = NULL;
end IF;

INSERT INTO `messages`(`client_id`, `message_from`, `message_to`, `message_type`, `body`, thread_id) VALUES (`_client_id`, `_message_from`, `_message_to`, `_message_type`, `_body`, `_thread_id`);
return (SELECT LAST_INSERT_ID());

end$$

DROP FUNCTION IF EXISTS `addOrder`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `addOrder` (`_client_id` BIGINT UNSIGNED, `_number` VARCHAR(50), `_state` VARCHAR(10), `_route_id` INT) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'adds new order and returns uniq ID of order in database'
begin
insert into orders (number, client_id, state, current_route) values(`_number`, `_client_id`, `_state`, `_route_id`);
return (SELECT LAST_INSERT_ID());
end$$

DROP FUNCTION IF EXISTS `getClientID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getClientID` (`_factoryName` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'returns client ID by mnemonic name of the factory'
return (select id from clients where name like `_factoryName`)$$

DROP FUNCTION IF EXISTS `getOrderID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getOrderID` (`_client_id` BIGINT UNSIGNED, `_order_num` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED NO SQL
return (select id from orders where orders.number like _order_num and orders.client_id = `_client_id`)$$

DROP FUNCTION IF EXISTS `getUserID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getUserID` (`_client_id` BIGINT UNSIGNED, `_name` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'returns iser''s id by mnemonic id of one'
return (select id from users where client_id = `_client_id` and `name` like `_name`)$$

DROP FUNCTION IF EXISTS `getWorkcenterID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getWorkcenterID` (`_client_id` BIGINT UNSIGNED, `_name` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'returns workcenter''s id by mnemonic id of one'
return (select id from workcenters where client_id = `_client_id` and `name` like `_name`)$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `assigns`
--

DROP TABLE IF EXISTS `assigns`;
CREATE TABLE `assigns` (
  `id` bigint(20) UNSIGNED NOT NULL COMMENT 'Uniq ID',
  `client_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Ref to order ID',
  `order_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Ref to order ID',
  `workcenter_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Ref to workcenter',
  `bucket` varchar(10) DEFAULT NULL COMMENT 'Name of bucket: income, procdssing, outcome, gone',
  `order_part` varchar(4096) NOT NULL COMMENT 'Part of the order which proceed the workcenter',
  `operation` varchar(250) NOT NULL,
  `fullset` tinyint(4) DEFAULT NULL,
  `prodmat` varchar(50) DEFAULT NULL,
  `next_workcenter_id` bigint(20) UNSIGNED DEFAULT NULL,
  `next_order_part` varchar(4096) DEFAULT NULL,
  `next_operation` varchar(250) DEFAULT NULL,
  `event_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Date and time of event',
  `next_id` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `assigns`
--

INSERT INTO `assigns` (`id`, `client_id`, `order_id`, `workcenter_id`, `bucket`, `order_part`, `operation`, `fullset`, `prodmat`, `next_workcenter_id`, `next_order_part`, `next_operation`, `event_time`, `next_id`) VALUES
(1, 1, 1, 1, NULL, '1.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, '1.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 18:49:10', 50),
(2, 1, 1, 5, 'PROCESSING', '1.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 04:44:34', NULL),
(3, 1, 2, 1, NULL, 'ord12.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'ord12.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 18:50:29', 56),
(4, 1, 2, 5, NULL, 'ord12.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'ord12.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:23:31', 13),
(5, 1, 3, 1, NULL, 'ord13.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'ord13.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:47:25', 83),
(6, 1, 3, 5, NULL, 'ord13.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'ord13.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:44:55', 81),
(7, 1, 4, 1, 'INCOME', 'ord14.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-12 19:22:32', NULL),
(8, 1, 4, 5, 'INCOME', 'ord14.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-12 19:22:32', NULL),
(9, 1, 5, 1, NULL, 'ord15.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'ord15.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:42:25', 75),
(10, 1, 5, 5, 'PROCESSING', 'ord15.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-13 19:43:46', NULL),
(11, 1, 6, 1, NULL, '2386.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, '2386.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 18:57:18', 64),
(12, 1, 6, 5, NULL, '2386.1.wheelpair.1.1.wheel', '', 1, NULL, 3, '2386.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:56:21', 59),
(13, 1, 2, 3, NULL, 'ord12.1.wheelpair.1', '', 1, NULL, 2, 'ord12.1.wheelpair.1', 'qualitycheck', '2020-10-13 19:40:16', 70),
(14, 1, 7, 1, NULL, 'o-112.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-112.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 18:51:02', 57),
(15, 1, 7, 5, NULL, 'o-112.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-112.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:52:56', 58),
(16, 1, 8, 1, NULL, 'o-113.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-113.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:42:27', 76),
(17, 1, 8, 5, 'PROCESSING', 'o-113.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-13 18:46:38', NULL),
(18, 1, 9, 1, 'PROCESSING', 'o-114.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-13 18:48:44', NULL),
(19, 1, 9, 5, 'OUTCOME', 'o-114.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-114.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:46:19', NULL),
(20, 1, 10, 1, NULL, 'o-115.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-115.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:45:44', 82),
(21, 1, 10, 5, NULL, 'o-115.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-115.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:44:50', 80),
(22, 1, 11, 1, NULL, 'o-116.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-116.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:42:29', 77),
(23, 1, 11, 5, 'OUTCOME', 'o-116.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-116.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:46:47', NULL),
(24, 1, 12, 1, NULL, 'o-117.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-117.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:42:30', 78),
(25, 1, 12, 5, 'INCOME', 'o-117.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-13 18:45:48', NULL),
(26, 1, 13, 1, NULL, 'o-118.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-118.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 18:49:18', 53),
(27, 1, 13, 5, 'OUTCOME', 'o-118.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-118.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:47:36', NULL),
(28, 1, 14, 1, 'OUTCOME', 'o-119.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-119.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:42:09', NULL),
(29, 1, 14, 5, NULL, 'o-119.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-119.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:02:11', 68),
(30, 1, 15, 1, NULL, 'o-120.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-120.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:02:57', 69),
(31, 1, 15, 5, NULL, 'o-120.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-120.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:56:31', 62),
(32, 1, 16, 1, NULL, 'o-121.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-121.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:40:55', 73),
(33, 1, 16, 5, NULL, 'o-121.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-121.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:57:59', 65),
(34, 1, 17, 1, NULL, 'o-122.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-122.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:47:35', 84),
(35, 1, 17, 5, NULL, 'o-122.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-122.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:56:29', 61),
(36, 1, 18, 1, NULL, 'o-123.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-123.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 18:49:20', 54),
(37, 1, 18, 5, 'OUTCOME', 'o-123.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-123.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:46:49', NULL),
(38, 1, 19, 1, NULL, 'o-124.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-124.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 18:49:15', 52),
(39, 1, 19, 5, NULL, 'o-124.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-124.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:56:26', 60),
(40, 1, 20, 1, NULL, 'o-125.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-125.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:40:57', 74),
(41, 1, 20, 5, NULL, 'o-125.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-125.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:58:05', 66),
(42, 1, 21, 1, NULL, 'o-126.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-126.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 18:49:12', 51),
(43, 1, 21, 5, NULL, 'o-126.1.wheelpair.1.1.wheel', '', 1, NULL, 3, 'o-126.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:02:09', 67),
(44, 1, 22, 1, 'OUTCOME', 'o-127.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-127.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 19:42:10', NULL),
(45, 1, 22, 5, 'INCOME', 'o-127.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-13 18:45:48', NULL),
(46, 1, 23, 1, NULL, 'o-128.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-128.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 18:49:22', 55),
(47, 1, 23, 5, 'INCOME', 'o-128.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-13 18:45:48', NULL),
(48, 1, 24, 1, NULL, 'o-129.1.wheelpair.1.1.shaft.1.1', '', 1, NULL, 4, 'o-129.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-13 18:56:51', 63),
(49, 1, 24, 5, 'INCOME', 'o-129.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-13 18:45:48', NULL),
(50, 1, 1, 4, 'OUTCOME', '1.1.wheelpair.1.1.shaft.1', 'blankprocessing', 1, NULL, NULL, NULL, NULL, '2020-10-14 16:37:57', NULL),
(51, 1, 21, 4, NULL, 'o-126.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-126.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:41:42', 67),
(52, 1, 19, 4, NULL, 'o-124.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-124.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:00:17', 60),
(53, 1, 13, 4, 'OUTCOME', 'o-118.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-118.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:50:10', NULL),
(54, 1, 18, 4, NULL, 'o-123.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-123.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:43:03', 79),
(55, 1, 23, 4, 'INCOME', 'o-128.1.wheelpair.1.1.shaft.1', 'blankprocessing', 1, NULL, NULL, NULL, NULL, '2020-10-13 18:49:22', NULL),
(56, 1, 2, 4, NULL, 'ord12.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'ord12.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:53:47', 13),
(57, 1, 7, 4, NULL, 'o-112.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-112.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 18:51:25', 58),
(58, 1, 7, 3, 'OUTCOME', 'o-112.1.wheelpair.1', '', 1, NULL, 2, 'o-112.1.wheelpair.1', 'qualitycheck', '2020-10-13 19:00:34', NULL),
(59, 1, 6, 3, NULL, '2386.1.wheelpair.1', '', 1, NULL, 2, '2386.1.wheelpair.1', 'qualitycheck', '2020-10-13 19:40:18', 71),
(60, 1, 19, 3, NULL, 'o-124.1.wheelpair.1', '', 1, NULL, 2, 'o-124.1.wheelpair.1', 'qualitycheck', '2020-10-13 19:40:20', 72),
(61, 1, 17, 3, 'PROCESSING', 'o-122.1.wheelpair.1.1', 'wheelpairassemble', 1, NULL, NULL, NULL, NULL, '2020-10-13 19:48:26', NULL),
(62, 1, 15, 3, NULL, 'o-120.1.wheelpair.1', '', 1, NULL, 2, 'o-120.1.wheelpair.1', 'qualitycheck', '2020-10-14 04:37:45', 85),
(63, 1, 24, 4, 'INCOME', 'o-129.1.wheelpair.1.1.shaft.1', 'blankprocessing', 1, NULL, NULL, NULL, NULL, '2020-10-13 18:56:51', NULL),
(64, 1, 6, 4, NULL, '2386.1.wheelpair.1.1.shaft', '', 1, NULL, 3, '2386.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:00:10', 59),
(65, 1, 16, 3, 'PROCESSING', 'o-121.1.wheelpair.1.1', 'wheelpairassemble', 1, NULL, NULL, NULL, NULL, '2020-10-13 19:41:51', NULL),
(66, 1, 20, 3, 'OUTCOME', 'o-125.1.wheelpair.1', '', 1, NULL, 2, 'o-125.1.wheelpair.1', 'qualitycheck', '2020-10-13 19:48:29', NULL),
(67, 1, 21, 3, 'OUTCOME', 'o-126.1.wheelpair.1', '', 1, NULL, 2, 'o-126.1.wheelpair.1', 'qualitycheck', '2020-10-13 19:46:31', NULL),
(68, 1, 14, 3, 'INCOME', 'o-119.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-13 19:02:11', NULL),
(69, 1, 15, 4, NULL, 'o-120.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-120.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:03:18', 62),
(70, 1, 2, 2, 'OUTCOME', 'ord12.1.wheelpair.1', 'qualitycheck', 1, NULL, NULL, NULL, NULL, '2020-10-14 16:38:40', NULL),
(71, 1, 6, 2, 'OUTCOME', '2386.1.wheelpair.1', 'qualitycheck', 1, NULL, NULL, NULL, NULL, '2020-10-14 16:38:38', NULL),
(72, 1, 19, 2, 'INCOME', 'o-124.1.wheelpair.1', 'qualitycheck', 1, NULL, NULL, NULL, NULL, '2020-10-13 19:40:20', NULL),
(73, 1, 16, 4, NULL, 'o-121.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-121.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:41:32', 65),
(74, 1, 20, 4, NULL, 'o-125.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-125.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:41:29', 66),
(75, 1, 5, 4, 'PROCESSING', 'ord15.1.wheelpair.1.1.shaft.1', 'blankprocessing', 1, NULL, NULL, NULL, NULL, '2020-10-13 19:42:39', NULL),
(76, 1, 8, 4, 'PROCESSING', 'o-113.1.wheelpair.1.1.shaft.1', 'blankprocessing', 1, NULL, NULL, NULL, NULL, '2020-10-13 19:42:50', NULL),
(77, 1, 11, 4, 'OUTCOME', 'o-116.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-116.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:46:01', NULL),
(78, 1, 12, 4, 'INCOME', 'o-117.1.wheelpair.1.1.shaft.1', 'blankprocessing', 1, NULL, NULL, NULL, NULL, '2020-10-13 19:42:30', NULL),
(79, 1, 18, 3, 'INCOME', 'o-123.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-13 19:43:03', NULL),
(80, 1, 10, 3, 'OUTCOME', 'o-115.1.wheelpair.1', '', 1, NULL, 2, 'o-115.1.wheelpair.1', 'qualitycheck', '2020-10-13 19:46:28', NULL),
(81, 1, 3, 3, 'OUTCOME', 'ord13.1.wheelpair.1', '', 1, NULL, 2, 'ord13.1.wheelpair.1', 'qualitycheck', '2020-10-13 19:48:20', NULL),
(82, 1, 10, 4, NULL, 'o-115.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-115.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:46:18', 80),
(83, 1, 3, 4, NULL, 'ord13.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'ord13.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:48:04', 81),
(84, 1, 17, 4, NULL, 'o-122.1.wheelpair.1.1.shaft', '', 1, NULL, 3, 'o-122.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-13 19:48:02', 61),
(85, 1, 15, 2, 'INCOME', 'o-120.1.wheelpair.1', 'qualitycheck', 1, NULL, NULL, NULL, NULL, '2020-10-14 04:37:45', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
CREATE TABLE `clients` (
  `id` bigint(20) UNSIGNED NOT NULL COMMENT 'Uniq id',
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Client in one database';

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
CREATE TABLE `messages` (
  `id` bigint(20) UNSIGNED NOT NULL COMMENT 'Uniq id',
  `message_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `message_from` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'from person',
  `message_to` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'to person or broadcast',
  `message_type` varchar(10) NOT NULL COMMENT 'INFO, WARNING, CRITICAL',
  `body` varchar(160) NOT NULL,
  `thread_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Previous message in thread'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Messages of users';

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `message_time`, `client_id`, `message_from`, `message_to`, `message_type`, `body`, `thread_id`) VALUES
(2, '2020-10-13 18:23:06', 1, 1, NULL, 'primary', 'Order \'ord12\' processed as \'ord12.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(3, '2020-10-13 18:23:59', 1, 1, NULL, 'primary', 'Order \'ord13\' processed as \'ord13.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(4, '2020-10-13 18:24:11', 1, 1, NULL, 'primary', 'Order \'ord12\' processed as \'ord12.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(5, '2020-10-13 18:24:23', 1, 1, NULL, 'primary', 'Order \'ord15\' processed as \'ord15.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(6, '2020-10-13 18:46:19', 1, 1, NULL, 'primary', 'Order \'o-114\' processed as \'o-114.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(7, '2020-10-13 18:46:21', 1, 1, NULL, 'primary', 'Order \'o-120\' processed as \'o-120.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(8, '2020-10-13 18:46:22', 1, 1, NULL, 'primary', 'Order \'o-125\' processed as \'o-125.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(9, '2020-10-13 18:46:25', 1, 1, NULL, 'primary', 'Order \'o-126\' processed as \'o-126.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(10, '2020-10-13 18:46:47', 1, 1, NULL, 'primary', 'Order \'o-116\' processed as \'o-116.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(11, '2020-10-13 18:46:49', 1, 1, NULL, 'primary', 'Order \'o-123\' processed as \'o-123.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(12, '2020-10-13 18:47:14', 1, 1, NULL, 'primary', 'Order \'o-123\' processed as \'o-123.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(13, '2020-10-13 18:47:16', 1, 1, NULL, 'primary', 'Order \'o-126\' processed as \'o-126.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(14, '2020-10-13 18:47:18', 1, 1, NULL, 'primary', 'Order \'o-129\' processed as \'o-129.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(15, '2020-10-13 18:47:20', 1, 1, NULL, 'primary', 'Order \'o-124\' processed as \'o-124.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(16, '2020-10-13 18:47:36', 1, 1, NULL, 'primary', 'Order \'o-118\' processed as \'o-118.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(17, '2020-10-13 18:47:38', 1, 1, NULL, 'primary', 'Order \'o-121\' processed as \'o-121.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(18, '2020-10-13 18:47:50', 1, 1, NULL, 'primary', 'Order \'2386\' processed as \'2386.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(19, '2020-10-13 18:48:01', 1, 1, NULL, 'primary', 'Order \'o-124\' processed as \'o-124.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(20, '2020-10-13 18:48:09', 1, 1, NULL, 'primary', 'Order \'o-119\' processed as \'o-119.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(21, '2020-10-13 18:48:26', 1, 1, NULL, 'primary', 'Order \'o-122\' processed as \'o-122.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(22, '2020-10-13 18:48:54', 1, 1, NULL, 'primary', 'Order \'o-118\' processed as \'o-118.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(23, '2020-10-13 18:48:56', 1, 1, NULL, 'primary', 'Order \'o-128\' processed as \'o-128.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(24, '2020-10-13 18:48:58', 1, 1, NULL, 'primary', 'Order \'o-117\' processed as \'o-117.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(25, '2020-10-13 18:49:39', 1, 1, NULL, 'primary', 'Order \'o-126\' processed as \'o-126.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(26, '2020-10-13 18:50:10', 1, 1, NULL, 'primary', 'Order \'o-118\' processed as \'o-118.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(27, '2020-10-13 18:50:22', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(28, '2020-10-13 18:51:15', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(29, '2020-10-13 18:52:41', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(30, '2020-10-13 18:53:39', 1, 1, NULL, 'primary', 'Order \'ord12\' processed as \'ord12.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(31, '2020-10-13 18:57:03', 1, 1, NULL, 'primary', 'Order \'2386\' processed as \'2386.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(32, '2020-10-13 18:58:42', 1, 1, NULL, 'primary', 'Order \'o-115\' processed as \'o-115.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(33, '2020-10-13 18:59:32', 1, 1, NULL, 'primary', 'Order \'2386\' processed as \'2386.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(34, '2020-10-13 18:59:39', 1, 1, NULL, 'primary', 'Order \'o-124\' processed as \'o-124.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(35, '2020-10-13 19:00:34', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1.1\' and ready to next workcenter \'wc2_4\'', NULL),
(36, '2020-10-13 19:01:00', 1, 1, NULL, 'primary', 'Order \'o-123\' processed as \'o-123.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(37, '2020-10-13 19:01:17', 1, 1, NULL, 'primary', 'Order \'o-121\' processed as \'o-121.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(38, '2020-10-13 19:01:25', 1, 1, NULL, 'primary', 'Order \'o-125\' processed as \'o-125.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(39, '2020-10-13 19:01:42', 1, 1, NULL, 'primary', 'Order \'2386\' processed as \'2386.1.wheelpair.1.1\' and ready to next workcenter \'wc2_4\'', NULL),
(40, '2020-10-13 19:01:47', 1, 1, NULL, 'primary', 'Order \'o-124\' processed as \'o-124.1.wheelpair.1.1\' and ready to next workcenter \'wc2_4\'', NULL),
(41, '2020-10-13 19:02:44', 1, 1, NULL, 'primary', 'Order \'o-120\' processed as \'o-120.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(42, '2020-10-13 19:03:08', 1, 1, NULL, 'primary', 'Order \'o-120\' processed as \'o-120.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(43, '2020-10-13 19:03:31', 1, 1, NULL, 'primary', 'Order \'o-120\' processed as \'o-120.1.wheelpair.1.1\' and ready to next workcenter \'wc2_4\'', NULL),
(44, '2020-10-13 19:03:33', 1, 1, NULL, 'primary', 'Order \'ord12\' processed as \'ord12.1.wheelpair.1.1\' and ready to next workcenter \'wc2_4\'', NULL),
(45, '2020-10-13 19:40:37', 1, 1, NULL, 'primary', 'Order \'o-122\' processed as \'o-122.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(46, '2020-10-13 19:40:44', 1, 1, NULL, 'primary', 'Order \'o-113\' processed as \'o-113.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(47, '2020-10-13 19:41:13', 1, 1, NULL, 'primary', 'Order \'o-121\' processed as \'o-121.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(48, '2020-10-13 19:41:16', 1, 1, NULL, 'primary', 'Order \'o-125\' processed as \'o-125.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(49, '2020-10-13 19:42:09', 1, 1, NULL, 'primary', 'Order \'o-119\' processed as \'o-119.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(50, '2020-10-13 19:42:10', 1, 1, NULL, 'primary', 'Order \'o-127\' processed as \'o-127.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(51, '2020-10-13 19:42:12', 1, 1, NULL, 'primary', 'Order \'o-116\' processed as \'o-116.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(52, '2020-10-13 19:43:24', 1, 1, NULL, 'primary', 'Order \'o-115\' processed as \'o-115.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(53, '2020-10-13 19:43:28', 1, 1, NULL, 'primary', 'Order \'ord13\' processed as \'ord13.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(54, '2020-10-13 19:46:01', 1, 1, NULL, 'primary', 'Order \'o-116\' processed as \'o-116.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(55, '2020-10-13 19:46:03', 1, 1, NULL, 'primary', 'Order \'o-115\' processed as \'o-115.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(56, '2020-10-13 19:46:28', 1, 1, NULL, 'primary', 'Order \'o-115\' processed as \'o-115.1.wheelpair.1.1\' and ready to next workcenter \'wc2_4\'', NULL),
(57, '2020-10-13 19:46:31', 1, 1, NULL, 'primary', 'Order \'o-126\' processed as \'o-126.1.wheelpair.1.1\' and ready to next workcenter \'wc2_4\'', NULL),
(58, '2020-10-13 19:47:50', 1, 1, NULL, 'primary', 'Order \'ord13\' processed as \'ord13.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(59, '2020-10-13 19:47:52', 1, 1, NULL, 'primary', 'Order \'o-122\' processed as \'o-122.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(60, '2020-10-13 19:48:20', 1, 1, NULL, 'primary', 'Order \'ord13\' processed as \'ord13.1.wheelpair.1.1\' and ready to next workcenter \'wc2_4\'', NULL),
(61, '2020-10-13 19:48:29', 1, 1, NULL, 'primary', 'Order \'o-125\' processed as \'o-125.1.wheelpair.1.1\' and ready to next workcenter \'wc2_4\'', NULL),
(62, '2020-10-14 16:37:57', 1, 1, NULL, 'primary', 'Order \'1\' processed as \'1.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(63, '2020-10-14 16:38:38', 1, 1, NULL, 'primary', 'Order \'2386\' processed as \'2386.1.wheelpair.1\' and ready to next workcenter \'wc2_4\'', NULL),
(64, '2020-10-14 16:38:40', 1, 1, NULL, 'primary', 'Order \'ord12\' processed as \'ord12.1.wheelpair.1\' and ready to next workcenter \'wc2_4\'', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `messages_read`
--

DROP TABLE IF EXISTS `messages_read`;
CREATE TABLE `messages_read` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `message_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `read_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Info about read events';

-- --------------------------------------------------------

--
-- Table structure for table `message_types`
--

DROP TABLE IF EXISTS `message_types`;
CREATE TABLE `message_types` (
  `message_type` varchar(10) NOT NULL
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
CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `number` varchar(50) NOT NULL,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `state` varchar(10) NOT NULL,
  `current_route` int(11) DEFAULT NULL,
  `deadline` datetime DEFAULT NULL,
  `estimated` datetime DEFAULT NULL,
  `customer` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `number`, `client_id`, `state`, `current_route`, `deadline`, `estimated`, `customer`) VALUES
(1, '1', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(2, 'ord12', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(3, 'ord13', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(4, 'ord14', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(5, 'ord15', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(6, '2386', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(7, 'o-112', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(8, 'o-113', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(9, 'o-114', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(10, 'o-115', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(11, 'o-116', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(12, 'o-117', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(13, 'o-118', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(14, 'o-119', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(15, 'o-120', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(16, 'o-121', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(17, 'o-122', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(18, 'o-123', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(19, 'o-124', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(20, 'o-125', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(21, 'o-126', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(22, 'o-127', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(23, 'o-128', 1, 'ASSIGNED', 1, NULL, NULL, ''),
(24, 'o-129', 1, 'ASSIGNED', 1, NULL, NULL, '');

-- --------------------------------------------------------

--
-- Table structure for table `order_states`
--

DROP TABLE IF EXISTS `order_states`;
CREATE TABLE `order_states` (
  `order_state` varchar(10) NOT NULL
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
CREATE TABLE `roads` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL,
  `from_wc` bigint(20) UNSIGNED NOT NULL,
  `to_wc` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='users table referenced to factory xml';

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
CREATE TABLE `workcenters` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
CREATE TABLE `workcenter_bucket` (
  `bucket` varchar(10) NOT NULL,
  `orderby` int(11) DEFAULT NULL,
  `showit` tinyint(1) DEFAULT NULL
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
-- Indexes for table `assigns`
--
ALTER TABLE `assigns`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`,`order_id`,`workcenter_id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `workcenter_id` (`workcenter_id`),
  ADD KEY `bucket` (`bucket`),
  ADD KEY `operation` (`operation`);

--
-- Indexes for table `clients`
--
ALTER TABLE `clients`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name_index` (`name`) USING HASH;

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `from_index` (`message_from`),
  ADD KEY `message_type` (`message_type`),
  ADD KEY `message_to` (`message_to`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `thread_id` (`thread_id`);
ALTER TABLE `messages` ADD FULLTEXT KEY `body` (`body`);

--
-- Indexes for table `messages_read`
--
ALTER TABLE `messages_read`
  ADD PRIMARY KEY (`id`),
  ADD KEY `message_id` (`message_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `message_types`
--
ALTER TABLE `message_types`
  ADD PRIMARY KEY (`message_type`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `number` (`number`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `state` (`state`) USING BTREE;

--
-- Indexes for table `order_states`
--
ALTER TABLE `order_states`
  ADD PRIMARY KEY (`order_state`);

--
-- Indexes for table `roads`
--
ALTER TABLE `roads`
  ADD PRIMARY KEY (`id`),
  ADD KEY `from_wc` (`from_wc`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `to_wc` (`to_wc`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD KEY `name` (`name`,`client_id`) USING BTREE,
  ADD KEY `client_id` (`client_id`);

--
-- Indexes for table `workcenters`
--
ALTER TABLE `workcenters`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`);

--
-- Indexes for table `workcenter_bucket`
--
ALTER TABLE `workcenter_bucket`
  ADD PRIMARY KEY (`bucket`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `assigns`
--
ALTER TABLE `assigns`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq ID', AUTO_INCREMENT=86;
--
-- AUTO_INCREMENT for table `clients`
--
ALTER TABLE `clients`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq id', AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq id', AUTO_INCREMENT=65;
--
-- AUTO_INCREMENT for table `messages_read`
--
ALTER TABLE `messages_read`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;
--
-- AUTO_INCREMENT for table `roads`
--
ALTER TABLE `roads`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `workcenters`
--
ALTER TABLE `workcenters`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
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

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
