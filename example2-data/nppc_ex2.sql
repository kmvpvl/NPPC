-- phpMyAdmin SQL Dump
-- version 4.6.6deb5
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Oct 24, 2020 at 11:15 AM
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
    left JOIN messages_read on messages.id = messages_read.message_id and (messages_read.user_id = messages.message_to or to_user is null) 
    where messages.client_id = in_client_id and (message_to = to_user or message_to is null)and find_in_set(message_type, types) > 0 and messages_read.id is null;

end if;
end$$

DROP PROCEDURE IF EXISTS `getOrderHistory`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrderHistory` (IN `_order_id` BIGINT UNSIGNED)  NO SQL
select assigns.*, workcenters.name as workcenter_name
from assigns
left join workcenters on workcenters.id=assigns.workcenter_id
where assigns.order_id = `_order_id`
order by assigns.event_time desc, assigns.id desc$$

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

DROP PROCEDURE IF EXISTS `makeMessageRead`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `makeMessageRead` (IN `_message_id` BIGINT UNSIGNED, IN `_user_id` BIGINT UNSIGNED)  NO SQL
insert into messages_read set `message_id`=`_message_id`, user_id = `_user_id`$$

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
  `operation` varchar(250) DEFAULT NULL,
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
(1, 1, 1, 1, NULL, 'o-112.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-112.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-14 18:13:54', 157),
(2, 1, 1, 5, NULL, 'o-112.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-112.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-14 18:14:01', 158),
(3, 1, 2, 1, NULL, 'o-113.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-113.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:23:14', 177),
(4, 1, 2, 5, NULL, 'o-113.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-113.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:21:37', 174),
(5, 1, 3, 1, NULL, 'o-114.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-114.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-14 22:22:51', 165),
(6, 1, 3, 5, NULL, 'o-114.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-114.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-14 22:23:47', 166),
(7, 1, 4, 1, NULL, 'o-115.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-115.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:23:15', 178),
(8, 1, 4, 5, NULL, 'o-115.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-115.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:21:38', 175),
(9, 1, 5, 1, NULL, 'o-116.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-116.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:23:16', 179),
(10, 1, 5, 5, NULL, 'o-116.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-116.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:33:57', 189),
(11, 1, 6, 1, NULL, 'o-117.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-117.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-14 20:44:39', 162),
(12, 1, 6, 5, NULL, 'o-117.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-117.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-14 20:43:49', 160),
(13, 1, 7, 1, NULL, 'o-118.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-118.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:23:17', 180),
(14, 1, 7, 5, NULL, 'o-118.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-118.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:03:26', 183),
(15, 1, 8, 1, NULL, 'o-119.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-119.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-14 20:44:41', 163),
(16, 1, 8, 5, NULL, 'o-119.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-119.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-14 20:43:51', 161),
(17, 1, 9, 1, NULL, 'o-120.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-120.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 21:35:36', 204),
(18, 1, 9, 5, NULL, 'o-120.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-120.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 21:32:49', 198),
(19, 1, 10, 1, NULL, 'o-121.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-121.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 01:29:27', 195),
(20, 1, 10, 5, NULL, 'o-121.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-121.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:03:27', 184),
(21, 1, 11, 1, NULL, 'o-122.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-122.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-18 16:15:33', 212),
(22, 1, 11, 5, NULL, 'o-122.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-122.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:03:28', 185),
(23, 1, 12, 1, NULL, 'o-123.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-123.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 01:27:42', 194),
(24, 1, 12, 5, NULL, 'o-123.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-123.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:03:29', 186),
(25, 1, 13, 1, NULL, 'o-124.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-124.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 01:04:26', 190),
(26, 1, 13, 5, NULL, 'o-124.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-124.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:21:39', 176),
(27, 1, 14, 1, NULL, 'o-125.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-125.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:23:18', 181),
(28, 1, 14, 5, NULL, 'o-125.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-125.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:03:30', 187),
(29, 1, 15, 1, 'OUTCOME', 'o-126.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-126.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-18 16:34:43', NULL),
(30, 1, 15, 5, NULL, 'o-126.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-126.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 21:32:50', 199),
(31, 1, 16, 1, NULL, 'o-127.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-127.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:23:19', 182),
(32, 1, 16, 5, NULL, 'o-127.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-127.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:28:01', 215),
(33, 1, 17, 1, NULL, 'o-128.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-128.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:19:44', 167),
(34, 1, 17, 5, NULL, 'o-128.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-128.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:28:02', 188),
(35, 1, 18, 1, NULL, 'o-129.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-129.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 01:04:28', 191),
(36, 1, 18, 5, NULL, 'o-129.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-129.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:28:23', 216),
(37, 1, 19, 1, 'OUTCOME', 'o-130.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-130.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-18 16:49:47', NULL),
(38, 1, 19, 5, NULL, 'o-130.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-130.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:28:24', 217),
(39, 1, 20, 1, 'OUTCOME', 'o-131.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-131.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-18 16:49:49', NULL),
(40, 1, 20, 5, NULL, 'o-131.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-131.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:28:24', 218),
(41, 1, 21, 1, NULL, 'o-132.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-132.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:19:46', 168),
(42, 1, 21, 5, NULL, 'o-132.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-132.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:37:43', 197),
(43, 1, 22, 1, 'OUTCOME', 'o-133.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-133.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-14 23:59:41', NULL),
(44, 1, 22, 5, NULL, 'o-133.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-133.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:28:25', 219),
(45, 1, 23, 1, NULL, 'o-134.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-134.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:19:48', 169),
(46, 1, 23, 5, NULL, 'o-134.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-134.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:28:28', 220),
(47, 1, 24, 1, 'OUTCOME', 'o-135.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-135.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-14 23:59:43', NULL),
(48, 1, 24, 5, 'PROCESSING', 'o-135.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 22:09:33', NULL),
(49, 1, 25, 1, NULL, 'o-136.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-136.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:19:50', 170),
(50, 1, 25, 5, NULL, 'o-136.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-136.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 08:13:42', 211),
(51, 1, 26, 1, 'OUTCOME', 'o-137.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-137.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-18 16:49:50', NULL),
(52, 1, 26, 5, 'PROCESSING', 'o-137.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 22:09:34', NULL),
(53, 1, 27, 1, 'OUTCOME', 'o-138.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-138.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-18 16:49:51', NULL),
(54, 1, 27, 5, 'PROCESSING', 'o-138.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 22:09:35', NULL),
(55, 1, 28, 1, 'OUTCOME', 'o-139.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-139.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-18 16:49:53', NULL),
(56, 1, 28, 5, 'PROCESSING', 'o-139.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-18 16:27:15', NULL),
(57, 1, 29, 1, 'OUTCOME', 'o-140.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-140.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-18 16:49:54', NULL),
(58, 1, 29, 5, 'OUTCOME', 'o-140.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-140.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:27:24', NULL),
(59, 1, 30, 1, 'OUTCOME', 'o-141.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-141.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-14 22:21:07', NULL),
(60, 1, 30, 5, 'OUTCOME', 'o-141.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-141.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:27:25', NULL),
(61, 1, 31, 1, 'PROCESSING', 'o-142.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:18', NULL),
(62, 1, 31, 5, 'OUTCOME', 'o-142.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-142.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:27:26', NULL),
(63, 1, 32, 1, 'PROCESSING', 'o-143.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:19', NULL),
(64, 1, 32, 5, 'OUTCOME', 'o-143.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-143.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:27:26', NULL),
(65, 1, 33, 1, 'PROCESSING', 'o-144.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:20', NULL),
(66, 1, 33, 5, 'OUTCOME', 'o-144.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-144.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:27:27', NULL),
(67, 1, 34, 1, 'OUTCOME', 'o-145.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-145.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-14 20:43:27', NULL),
(68, 1, 34, 5, 'OUTCOME', 'o-145.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-145.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:27:27', NULL),
(69, 1, 35, 1, 'PROCESSING', 'o-146.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:20', NULL),
(70, 1, 35, 5, 'INCOME', 'o-146.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:04', NULL),
(71, 1, 36, 1, NULL, 'o-147.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-147.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:21:07', 171),
(72, 1, 36, 5, 'INCOME', 'o-147.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:04', NULL),
(73, 1, 37, 1, 'PROCESSING', 'o-148.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:21', NULL),
(74, 1, 37, 5, 'INCOME', 'o-148.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:04', NULL),
(75, 1, 38, 1, 'PROCESSING', 'o-149.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:22', NULL),
(76, 1, 38, 5, 'INCOME', 'o-149.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:04', NULL),
(77, 1, 39, 1, 'PROCESSING', 'o-150.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:23', NULL),
(78, 1, 39, 5, 'INCOME', 'o-150.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(79, 1, 40, 1, 'PROCESSING', 'o-151.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:23', NULL),
(80, 1, 40, 5, 'INCOME', 'o-151.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(81, 1, 41, 1, 'PROCESSING', 'o-152.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:24', NULL),
(82, 1, 41, 5, 'OUTCOME', 'o-152.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-152.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 22:09:21', NULL),
(83, 1, 42, 1, 'PROCESSING', 'o-153.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:25', NULL),
(84, 1, 42, 5, 'OUTCOME', 'o-153.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-153.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 22:09:29', NULL),
(85, 1, 43, 1, 'PROCESSING', 'o-154.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:26', NULL),
(86, 1, 43, 5, 'OUTCOME', 'o-154.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-154.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 22:09:29', NULL),
(87, 1, 44, 1, 'PROCESSING', 'o-155.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:27', NULL),
(88, 1, 44, 5, 'OUTCOME', 'o-155.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-155.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 22:09:30', NULL),
(89, 1, 45, 1, 'PROCESSING', 'o-156.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:28', NULL),
(90, 1, 45, 5, 'OUTCOME', 'o-156.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-156.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 22:09:31', NULL),
(91, 1, 46, 1, 'PROCESSING', 'o-157.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:28', NULL),
(92, 1, 46, 5, 'OUTCOME', 'o-157.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-157.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:27:28', NULL),
(93, 1, 47, 1, 'PROCESSING', 'o-158.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:29', NULL),
(94, 1, 47, 5, 'OUTCOME', 'o-158.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-158.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:27:29', NULL),
(95, 1, 48, 1, 'PROCESSING', 'o-159.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:30', NULL),
(96, 1, 48, 5, 'OUTCOME', 'o-159.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-159.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:58:42', NULL),
(97, 1, 49, 1, 'PROCESSING', 'o-160.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:31', NULL),
(98, 1, 49, 5, 'OUTCOME', 'o-160.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-160.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:58:43', NULL),
(99, 1, 50, 1, 'PROCESSING', 'o-161.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:31', NULL),
(100, 1, 50, 5, 'OUTCOME', 'o-161.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-161.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:58:43', NULL),
(101, 1, 51, 1, 'PROCESSING', 'o-162.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:32', NULL),
(102, 1, 51, 5, NULL, 'o-162.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-162.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 21:33:04', 200),
(103, 1, 52, 1, 'PROCESSING', 'o-163.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:33', NULL),
(104, 1, 52, 5, 'PROCESSING', 'o-163.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:58:27', NULL),
(105, 1, 53, 1, 'PROCESSING', 'o-164.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:34', NULL),
(106, 1, 53, 5, 'PROCESSING', 'o-164.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:58:28', NULL),
(107, 1, 54, 1, 'PROCESSING', 'o-165.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 23:59:35', NULL),
(108, 1, 54, 5, NULL, 'o-165.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-165.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 21:33:06', 201),
(109, 1, 55, 1, NULL, 'o-166.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-166.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 22:25:42', 210),
(110, 1, 55, 5, NULL, 'o-166.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-166.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 21:33:07', 202),
(111, 1, 56, 1, 'PROCESSING', 'o-167.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-18 16:49:40', NULL),
(112, 1, 56, 5, NULL, 'o-167.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-167.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 21:33:08', 203),
(113, 1, 57, 1, 'INCOME', 'o-168.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(114, 1, 57, 5, 'OUTCOME', 'o-168.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-168.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:58:59', NULL),
(115, 1, 58, 1, 'INCOME', 'o-169.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(116, 1, 58, 5, 'OUTCOME', 'o-169.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-169.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:59:00', NULL),
(117, 1, 59, 1, 'INCOME', 'o-170.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(118, 1, 59, 5, 'OUTCOME', 'o-170.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-170.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:59:01', NULL),
(119, 1, 60, 1, 'INCOME', 'o-171.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(120, 1, 60, 5, 'OUTCOME', 'o-171.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-171.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:59:02', NULL),
(121, 1, 61, 1, 'INCOME', 'o-172.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(122, 1, 61, 5, 'PROCESSING', 'o-172.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:58:49', NULL),
(123, 1, 62, 1, NULL, 'o-173.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-173.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:21:08', 172),
(124, 1, 62, 5, 'PROCESSING', 'o-173.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:58:50', NULL),
(125, 1, 63, 1, NULL, 'o-174.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-174.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:21:09', 173),
(126, 1, 63, 5, 'OUTCOME', 'o-174.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-174.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 21:27:44', NULL),
(127, 1, 64, 1, 'INCOME', 'o-175.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(128, 1, 64, 5, 'PROCESSING', 'o-175.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:58:52', NULL),
(129, 1, 65, 1, 'INCOME', 'o-176.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(130, 1, 65, 5, 'PROCESSING', 'o-176.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:58:53', NULL),
(131, 1, 66, 1, 'INCOME', 'o-177.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(132, 1, 66, 5, 'INCOME', 'o-177.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(133, 1, 67, 1, 'INCOME', 'o-178.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(134, 1, 67, 5, 'INCOME', 'o-178.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:05', NULL),
(135, 1, 68, 1, 'INCOME', 'o-179.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(136, 1, 68, 5, 'INCOME', 'o-179.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(137, 1, 69, 1, 'INCOME', 'o-180.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(138, 1, 69, 5, 'INCOME', 'o-180.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(139, 1, 70, 1, 'INCOME', 'o-181.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(140, 1, 70, 5, 'INCOME', 'o-181.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(141, 1, 71, 1, 'INCOME', 'o-182.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(142, 1, 71, 5, 'PROCESSING', 'o-182.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:59:04', NULL),
(143, 1, 72, 1, 'INCOME', 'o-183.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(144, 1, 72, 5, 'PROCESSING', 'o-183.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:59:05', NULL),
(145, 1, 73, 1, 'INCOME', 'o-184.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(146, 1, 73, 5, 'PROCESSING', 'o-184.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:59:06', NULL),
(147, 1, 74, 1, 'INCOME', 'o-185.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(148, 1, 74, 5, 'PROCESSING', 'o-185.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:59:07', NULL),
(149, 1, 75, 1, 'OUTCOME', 'o-186.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-186.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:19:22', NULL),
(150, 1, 75, 5, 'PROCESSING', 'o-186.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:59:08', NULL),
(151, 1, 76, 1, 'OUTCOME', 'o-187.1.wheelpair.1.1.shaft.1.1', NULL, 1, NULL, 4, 'o-187.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-10-15 00:19:24', NULL),
(152, 1, 76, 5, 'OUTCOME', 'o-187.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-187.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 16:03:53', NULL),
(153, 1, 77, 1, 'INCOME', 'o-188.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(154, 1, 77, 5, 'INCOME', 'o-188.1.wheelpair.1.1.wheel.1', 'supplywheel', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(155, 1, 78, 1, 'INCOME', 'o-189.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 1, NULL, NULL, NULL, NULL, '2020-10-14 17:46:06', NULL),
(156, 1, 78, 5, 'OUTCOME', 'o-189.1.wheelpair.1.1.wheel', NULL, 1, NULL, 3, 'o-189.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 22:36:28', NULL),
(157, 1, 1, 4, NULL, 'o-112.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-112.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-14 18:14:29', 158),
(158, 1, 1, 3, NULL, 'o-112.1.wheelpair.1', NULL, 1, NULL, 2, 'o-112.1.wheelpair.1', 'qualitycheck', '2020-10-14 18:14:46', 159),
(159, 1, 1, 2, 'OUTCOME', 'o-112.1.wheelpair', NULL, 1, NULL, 2, '', '', '2020-10-14 18:14:56', NULL),
(160, 1, 6, 3, NULL, 'o-117.1.wheelpair.1', NULL, 1, NULL, 2, 'o-117.1.wheelpair.1', 'qualitycheck', '2020-10-14 20:46:27', 164),
(161, 1, 8, 3, NULL, 'o-119.1.wheelpair.1', NULL, 1, NULL, 2, 'o-119.1.wheelpair.1', 'qualitycheck', '2020-10-15 21:59:24', 205),
(162, 1, 6, 4, NULL, 'o-117.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-117.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-14 20:45:50', 160),
(163, 1, 8, 4, NULL, 'o-119.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-119.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:23:53', 161),
(164, 1, 6, 2, 'OUTCOME', 'o-117.1.wheelpair', NULL, 1, NULL, 2, '', '', '2020-10-15 01:07:04', NULL),
(165, 1, 3, 4, NULL, 'o-114.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-114.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-14 22:23:41', 166),
(166, 1, 3, 3, NULL, 'o-114.1.wheelpair.1', NULL, 1, NULL, 2, 'o-114.1.wheelpair.1', 'qualitycheck', '2020-10-15 01:06:41', 192),
(167, 1, 17, 4, NULL, 'o-128.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-128.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:03:54', 188),
(168, 1, 21, 4, NULL, 'o-132.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-132.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:37:35', 197),
(169, 1, 23, 4, 'PROCESSING', 'o-134.1.wheelpair.1.1.shaft.1', 'blankprocessing', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:21:19', NULL),
(170, 1, 25, 4, NULL, 'o-136.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-136.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 08:14:08', 211),
(171, 1, 36, 4, 'INCOME', 'o-147.1.wheelpair.1.1.shaft.1', 'blankprocessing', 1, NULL, NULL, NULL, NULL, '2020-10-15 00:21:07', NULL),
(172, 1, 62, 4, 'PROCESSING', 'o-173.1.wheelpair.1.1.shaft.1', 'blankprocessing', 1, NULL, NULL, NULL, NULL, '2020-10-15 01:06:00', NULL),
(173, 1, 63, 4, 'OUTCOME', 'o-174.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-174.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:06:05', NULL),
(174, 1, 2, 3, NULL, 'o-113.1.wheelpair.1', NULL, 1, NULL, 2, 'o-113.1.wheelpair.1', 'qualitycheck', '2020-10-15 21:59:25', 206),
(175, 1, 4, 3, NULL, 'o-115.1.wheelpair.1', NULL, 1, NULL, 2, 'o-115.1.wheelpair.1', 'qualitycheck', '2020-10-15 01:06:51', 193),
(176, 1, 13, 3, NULL, 'o-124.1.wheelpair.1', NULL, 1, NULL, 2, 'o-124.1.wheelpair.1', 'qualitycheck', '2020-10-15 21:59:26', 207),
(177, 1, 2, 4, NULL, 'o-113.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-113.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:23:55', 174),
(178, 1, 4, 4, NULL, 'o-115.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-115.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 00:23:57', 175),
(179, 1, 5, 4, NULL, 'o-116.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-116.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:03:58', 189),
(180, 1, 7, 4, NULL, 'o-118.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-118.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:03:47', 183),
(181, 1, 14, 4, NULL, 'o-125.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-125.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:05:11', 187),
(182, 1, 16, 4, 'OUTCOME', 'o-127.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-127.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:06:06', NULL),
(183, 1, 7, 3, NULL, 'o-118.1.wheelpair.1', NULL, 1, NULL, 2, 'o-118.1.wheelpair.1', 'qualitycheck', '2020-10-15 21:59:27', 208),
(184, 1, 10, 3, NULL, 'o-121.1.wheelpair.1', NULL, 1, NULL, 2, 'o-121.1.wheelpair.1', 'qualitycheck', '2020-10-15 21:59:29', 209),
(185, 1, 11, 3, 'PROCESSING', 'o-122.1.wheelpair.1.1', 'wheelpairassemble', 1, NULL, NULL, NULL, NULL, '2020-10-18 16:16:16', NULL),
(186, 1, 12, 3, NULL, 'o-123.1.wheelpair.1', NULL, 1, NULL, 2, 'o-123.1.wheelpair.1', 'qualitycheck', '2020-10-18 16:17:12', 213),
(187, 1, 14, 3, NULL, 'o-125.1.wheelpair.1', NULL, 1, NULL, 2, 'o-125.1.wheelpair.1', 'qualitycheck', '2020-10-18 16:17:13', 214),
(188, 1, 17, 3, 'PROCESSING', 'o-128.1.wheelpair.1.1', 'wheelpairassemble', 1, NULL, NULL, NULL, NULL, '2020-10-18 16:34:55', NULL),
(189, 1, 5, 3, NULL, 'o-116.1.wheelpair.1', NULL, 1, NULL, 2, 'o-116.1.wheelpair.1', 'qualitycheck', '2020-10-15 01:35:45', 196),
(190, 1, 13, 4, NULL, 'o-124.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-124.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:05:06', 176),
(191, 1, 18, 4, 'INCOME', 'o-129.1.wheelpair.1.1.shaft.1', 'blankprocessing', 1, NULL, NULL, NULL, NULL, '2020-10-15 01:04:28', NULL),
(192, 1, 3, 2, 'OUTCOME', 'o-114.1.wheelpair', NULL, 1, NULL, 2, '', '', '2020-10-15 21:59:42', NULL),
(193, 1, 4, 2, 'OUTCOME', 'o-115.1.wheelpair', NULL, 1, NULL, 2, '', '', '2020-10-15 21:59:43', NULL),
(194, 1, 12, 4, NULL, 'o-123.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-123.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:28:07', 186),
(195, 1, 10, 4, NULL, 'o-121.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-121.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 01:29:42', 184),
(196, 1, 5, 2, 'OUTCOME', 'o-116.1.wheelpair', NULL, 1, NULL, 2, '', '', '2020-10-15 21:59:44', NULL),
(197, 1, 21, 3, 'OUTCOME', 'o-132.1.wheelpair.1', NULL, 1, NULL, 2, 'o-132.1.wheelpair.1', 'qualitycheck', '2020-10-15 01:37:52', NULL),
(198, 1, 9, 3, 'OUTCOME', 'o-120.1.wheelpair.1', NULL, 1, NULL, 2, 'o-120.1.wheelpair.1', 'qualitycheck', '2020-10-15 21:36:27', NULL),
(199, 1, 15, 3, 'INCOME', 'o-126.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-15 21:32:50', NULL),
(200, 1, 51, 3, 'INCOME', 'o-162.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-15 21:33:04', NULL),
(201, 1, 54, 3, 'INCOME', 'o-165.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-15 21:33:06', NULL),
(202, 1, 55, 3, 'PROCESSING', 'o-166.1.wheelpair.1.1', 'wheelpairassemble', 1, NULL, NULL, NULL, NULL, '2020-10-15 22:29:02', NULL),
(203, 1, 56, 3, 'INCOME', 'o-167.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-15 21:33:08', NULL),
(204, 1, 9, 4, NULL, 'o-120.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-120.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 21:36:15', 198),
(205, 1, 8, 2, 'PROCESSING', 'o-119.1.wheelpair.1', 'qualitycheck', 1, NULL, NULL, NULL, NULL, '2020-10-15 21:59:40', NULL),
(206, 1, 2, 2, 'OUTCOME', 'o-113.1.wheelpair', NULL, 1, NULL, 2, '', '', '2020-10-15 21:59:57', NULL),
(207, 1, 13, 2, 'OUTCOME', 'o-124.1.wheelpair', NULL, 1, NULL, 2, '', '', '2020-10-15 21:59:58', NULL),
(208, 1, 7, 2, 'OUTCOME', 'o-118.1.wheelpair', NULL, 1, NULL, 2, '', '', '2020-10-15 22:00:09', NULL),
(209, 1, 10, 2, 'OUTCOME', 'o-121.1.wheelpair', NULL, 1, NULL, 2, '', '', '2020-10-15 22:00:10', NULL),
(210, 1, 55, 4, NULL, 'o-166.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-166.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-15 22:28:53', 202),
(211, 1, 25, 3, 'OUTCOME', 'o-136.1.wheelpair.1', NULL, 1, NULL, 2, 'o-136.1.wheelpair.1', 'qualitycheck', '2020-10-18 08:14:19', NULL),
(212, 1, 11, 4, NULL, 'o-122.1.wheelpair.1.1.shaft', NULL, 1, NULL, 3, 'o-122.1.wheelpair.1.1', 'wheelpairassemble', '2020-10-18 16:16:03', 185),
(213, 1, 12, 2, 'INCOME', 'o-123.1.wheelpair.1', 'qualitycheck', 1, NULL, NULL, NULL, NULL, '2020-10-18 16:17:12', NULL),
(214, 1, 14, 2, 'INCOME', 'o-125.1.wheelpair.1', 'qualitycheck', 1, NULL, NULL, NULL, NULL, '2020-10-18 16:17:13', NULL),
(215, 1, 16, 3, 'INCOME', 'o-127.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-18 16:28:01', NULL),
(216, 1, 18, 3, 'INCOME', 'o-129.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-18 16:28:23', NULL),
(217, 1, 19, 3, 'INCOME', 'o-130.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-18 16:28:24', NULL),
(218, 1, 20, 3, 'INCOME', 'o-131.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-18 16:28:24', NULL),
(219, 1, 22, 3, 'INCOME', 'o-133.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-18 16:28:25', NULL),
(220, 1, 23, 3, 'INCOME', 'o-134.1.wheelpair.1.1', 'wheelpairassemble', NULL, NULL, NULL, NULL, NULL, '2020-10-18 16:28:28', NULL);

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
(1, '2020-10-14 17:48:00', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(2, '2020-10-14 17:57:53', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(3, '2020-10-14 18:06:02', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1.1.shaft.1.1.1\' and ready to next workcenter \'wc1_3\'', NULL),
(4, '2020-10-14 18:13:40', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1.1.wheel.1\' and ready to next workcenter \'wc2_3\'', NULL),
(5, '2020-10-14 18:14:17', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1.1.shaft.1\' and ready to next workcenter \'wc2_3\'', NULL),
(6, '2020-10-14 18:14:39', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1.1\' and ready to next workcenter \'wc2_4\'', NULL),
(7, '2020-10-14 18:14:56', 1, 1, NULL, 'primary', 'Order \'o-112\' processed as \'o-112.1.wheelpair.1\' and ready to next workcenter \'wc2_4\'', NULL),
(8, '2020-10-14 19:15:25', 1, 1, NULL, 'primary', 'Order \'o-125\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(9, '2020-10-14 19:17:16', 1, 1, NULL, 'primary', 'Order \'o-117\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(10, '2020-10-14 20:42:29', 1, 1, NULL, 'primary', 'Order \'o-136\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(11, '2020-10-14 20:43:27', 1, 1, NULL, 'primary', 'Order \'o-145\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(12, '2020-10-14 20:43:30', 1, 1, NULL, 'primary', 'Order \'o-147\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(13, '2020-10-14 20:43:42', 1, 1, NULL, 'primary', 'Order \'o-119\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(14, '2020-10-14 20:44:29', 1, 1, NULL, 'primary', 'Order \'o-117\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(15, '2020-10-14 20:44:31', 1, 1, NULL, 'primary', 'Order \'o-119\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(16, '2020-10-14 20:45:42', 1, 1, NULL, 'primary', 'Order \'o-117\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(17, '2020-10-14 20:46:01', 1, 1, NULL, 'primary', 'Order \'o-117\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(18, '2020-10-14 20:46:16', 1, 1, NULL, 'primary', 'Order \'o-113\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(19, '2020-10-14 22:20:15', 1, 1, NULL, 'primary', 'Order \'o-114\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(20, '2020-10-14 22:20:17', 1, 1, NULL, 'primary', 'Order \'o-115\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(21, '2020-10-14 22:21:07', 1, 1, NULL, 'primary', 'Order \'o-141\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(22, '2020-10-14 22:21:09', 1, 1, NULL, 'primary', 'Order \'o-128\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(23, '2020-10-14 22:21:44', 1, 1, NULL, 'primary', 'Order \'o-114\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(24, '2020-10-14 22:23:24', 1, 1, NULL, 'primary', 'Order \'o-114\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(25, '2020-10-14 23:59:39', 1, 1, NULL, 'primary', 'Order \'o-132\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(26, '2020-10-14 23:59:41', 1, 1, NULL, 'primary', 'Order \'o-133\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(27, '2020-10-14 23:59:42', 1, 1, NULL, 'primary', 'Order \'o-134\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(28, '2020-10-14 23:59:43', 1, 1, NULL, 'primary', 'Order \'o-135\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(29, '2020-10-15 00:19:20', 1, 1, NULL, 'primary', 'Order \'o-173\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(30, '2020-10-15 00:19:21', 1, 1, NULL, 'primary', 'Order \'o-174\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(31, '2020-10-15 00:19:22', 1, 1, NULL, 'primary', 'Order \'o-186\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(32, '2020-10-15 00:19:24', 1, 1, NULL, 'primary', 'Order \'o-187\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(33, '2020-10-15 00:20:34', 1, 1, NULL, 'primary', 'Order \'o-132\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(34, '2020-10-15 00:20:36', 1, 1, NULL, 'primary', 'Order \'o-124\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(35, '2020-10-15 00:20:37', 1, 1, NULL, 'primary', 'Order \'o-125\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(36, '2020-10-15 00:20:38', 1, 1, NULL, 'primary', 'Order \'o-126\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(37, '2020-10-15 00:21:22', 1, 1, NULL, 'primary', 'Order \'o-119\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(38, '2020-10-15 00:21:23', 1, 1, NULL, 'primary', 'Order \'o-128\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(39, '2020-10-15 00:22:57', 1, 1, NULL, 'primary', 'Order \'o-113\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(40, '2020-10-15 00:22:58', 1, 1, NULL, 'primary', 'Order \'o-115\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(41, '2020-10-15 00:22:59', 1, 1, NULL, 'primary', 'Order \'o-116\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(42, '2020-10-15 00:23:00', 1, 1, NULL, 'primary', 'Order \'o-118\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(43, '2020-10-15 00:23:02', 1, 1, NULL, 'primary', 'Order \'o-127\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(44, '2020-10-15 00:23:03', 1, 1, NULL, 'primary', 'Order \'o-129\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(45, '2020-10-15 00:23:39', 1, 1, NULL, 'primary', 'Order \'o-113\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(46, '2020-10-15 00:23:40', 1, 1, NULL, 'primary', 'Order \'o-115\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(47, '2020-10-15 00:23:41', 1, 1, NULL, 'primary', 'Order \'o-116\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(48, '2020-10-15 00:23:42', 1, 1, NULL, 'primary', 'Order \'o-118\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(49, '2020-10-15 00:24:13', 1, 1, NULL, 'primary', 'Order \'o-114\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(50, '2020-10-15 00:24:15', 1, 1, NULL, 'primary', 'Order \'o-113\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(51, '2020-10-15 00:58:33', 1, 1, NULL, 'primary', 'Order \'o-121\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(52, '2020-10-15 00:58:34', 1, 1, NULL, 'primary', 'Order \'o-122\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(53, '2020-10-15 00:58:35', 1, 1, NULL, 'primary', 'Order \'o-123\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(54, '2020-10-15 00:58:36', 1, 1, NULL, 'primary', 'Order \'o-127\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(55, '2020-10-15 00:58:37', 1, 1, NULL, 'primary', 'Order \'o-128\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(56, '2020-10-15 00:58:39', 1, 1, NULL, 'primary', 'Order \'o-118\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(57, '2020-10-15 00:58:42', 1, 1, NULL, 'primary', 'Order \'o-159\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(58, '2020-10-15 00:58:43', 1, 1, NULL, 'primary', 'Order \'o-160\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(59, '2020-10-15 00:58:43', 1, 1, NULL, 'primary', 'Order \'o-161\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(60, '2020-10-15 00:58:44', 1, 1, NULL, 'primary', 'Order \'o-162\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(61, '2020-10-15 00:58:56', 1, 1, NULL, 'primary', 'Order \'o-165\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(62, '2020-10-15 00:58:57', 1, 1, NULL, 'primary', 'Order \'o-166\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(63, '2020-10-15 00:58:58', 1, 1, NULL, 'primary', 'Order \'o-167\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(64, '2020-10-15 00:58:59', 1, 1, NULL, 'primary', 'Order \'o-168\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(65, '2020-10-15 00:59:00', 1, 1, NULL, 'primary', 'Order \'o-169\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(66, '2020-10-15 00:59:01', 1, 1, NULL, 'primary', 'Order \'o-170\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(67, '2020-10-15 00:59:02', 1, 1, NULL, 'primary', 'Order \'o-171\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(68, '2020-10-15 01:04:18', 1, 1, NULL, 'primary', 'Order \'o-124\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(69, '2020-10-15 01:04:52', 1, 1, NULL, 'primary', 'Order \'o-124\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(70, '2020-10-15 01:04:54', 1, 1, NULL, 'primary', 'Order \'o-125\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(71, '2020-10-15 01:04:57', 1, 1, NULL, 'primary', 'Order \'o-132\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(72, '2020-10-15 01:05:39', 1, 1, NULL, 'primary', 'Order \'o-119\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(73, '2020-10-15 01:05:41', 1, 1, NULL, 'primary', 'Order \'o-124\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(74, '2020-10-15 01:05:44', 1, 1, NULL, 'primary', 'Order \'o-115\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(75, '2020-10-15 01:06:05', 1, 1, NULL, 'primary', 'Order \'o-174\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(76, '2020-10-15 01:06:06', 1, 1, NULL, 'primary', 'Order \'o-127\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(77, '2020-10-15 01:07:04', 1, 1, NULL, 'primary', 'Order \'o-117\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(78, '2020-10-15 01:27:27', 1, 1, NULL, 'primary', 'Order \'o-123\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(79, '2020-10-15 01:27:55', 1, 1, NULL, 'primary', 'Order \'o-123\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(80, '2020-10-15 01:29:00', 1, 1, NULL, 'primary', 'Order \'o-120\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(81, '2020-10-15 01:29:18', 1, 1, NULL, 'primary', 'Order \'o-121\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(82, '2020-10-15 01:29:36', 1, 1, NULL, 'primary', 'Order \'o-121\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(83, '2020-10-15 01:32:30', 1, 1, NULL, 'primary', 'Order \'o-116\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(84, '2020-10-15 01:34:54', 1, 1, NULL, 'primary', 'Order \'o-116\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(85, '2020-10-15 01:35:57', 1, 1, NULL, 'primary', 'Order \'o-125\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(86, '2020-10-15 01:36:04', 1, 1, NULL, 'primary', 'Order \'o-123\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(87, '2020-10-15 01:36:14', 1, 1, NULL, 'primary', 'Order \'o-118\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(88, '2020-10-15 01:36:16', 1, 1, NULL, 'primary', 'Order \'o-121\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(89, '2020-10-15 01:37:52', 1, 1, NULL, 'primary', 'Order \'o-132\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(90, '2020-10-15 16:03:53', 1, 1, NULL, 'primary', 'Order \'o-187\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(91, '2020-10-15 21:27:44', 1, 1, NULL, 'primary', 'Order \'o-174\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(92, '2020-10-15 21:32:31', 1, 1, NULL, 'primary', 'Order \'o-129\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(93, '2020-10-15 21:34:02', 1, 1, NULL, 'primary', 'Order \'o-120\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(94, '2020-10-15 21:36:08', 1, 1, NULL, 'primary', 'Order \'o-120\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(95, '2020-10-15 21:36:27', 1, 1, NULL, 'primary', 'Order \'o-120\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(96, '2020-10-15 21:59:42', 1, 1, NULL, 'primary', 'Order \'o-114\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(97, '2020-10-15 21:59:43', 1, 1, NULL, 'primary', 'Order \'o-115\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(98, '2020-10-15 21:59:44', 1, 1, NULL, 'primary', 'Order \'o-116\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(99, '2020-10-15 21:59:57', 1, 1, NULL, 'primary', 'Order \'o-113\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(100, '2020-10-15 21:59:58', 1, 1, NULL, 'primary', 'Order \'o-124\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(101, '2020-10-15 22:00:09', 1, 1, NULL, 'primary', 'Order \'o-118\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(102, '2020-10-15 22:00:10', 1, 1, NULL, 'primary', 'Order \'o-121\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(103, '2020-10-15 22:09:17', 1, 1, NULL, 'primary', 'Order \'o-130\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(104, '2020-10-15 22:09:18', 1, 1, NULL, 'primary', 'Order \'o-131\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(105, '2020-10-15 22:09:18', 1, 1, NULL, 'primary', 'Order \'o-133\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(106, '2020-10-15 22:09:19', 1, 1, NULL, 'primary', 'Order \'o-134\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(107, '2020-10-15 22:09:21', 1, 1, NULL, 'primary', 'Order \'o-152\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(108, '2020-10-15 22:09:29', 1, 1, NULL, 'primary', 'Order \'o-153\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(109, '2020-10-15 22:09:30', 1, 1, NULL, 'primary', 'Order \'o-154\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(110, '2020-10-15 22:09:30', 1, 1, NULL, 'primary', 'Order \'o-155\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(111, '2020-10-15 22:09:31', 1, 1, NULL, 'primary', 'Order \'o-156\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(112, '2020-10-15 22:25:07', 1, 1, NULL, 'primary', 'Order \'o-166\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(113, '2020-10-15 22:28:30', 1, 1, NULL, 'primary', 'Order \'o-166\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(114, '2020-10-15 22:36:28', 1, 1, NULL, 'primary', 'Order \'o-189\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(115, '2020-10-18 08:12:24', 1, 1, NULL, 'primary', 'Order \'o-136\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(116, '2020-10-18 08:12:37', 1, 1, NULL, 'primary', 'Order \'o-136\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(117, '2020-10-18 08:14:19', 1, 1, NULL, 'primary', 'Order \'o-136\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(118, '2020-10-18 16:14:40', 1, 1, NULL, 'primary', 'Order \'o-122\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(119, '2020-10-18 16:15:47', 1, 1, NULL, 'primary', 'Order \'o-122\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(120, '2020-10-18 16:27:24', 1, 1, NULL, 'primary', 'Order \'o-140\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(121, '2020-10-18 16:27:25', 1, 1, NULL, 'primary', 'Order \'o-141\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(122, '2020-10-18 16:27:26', 1, 1, NULL, 'primary', 'Order \'o-142\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(123, '2020-10-18 16:27:26', 1, 1, NULL, 'primary', 'Order \'o-143\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(124, '2020-10-18 16:27:27', 1, 1, NULL, 'primary', 'Order \'o-144\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(125, '2020-10-18 16:27:27', 1, 1, NULL, 'primary', 'Order \'o-145\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(126, '2020-10-18 16:27:28', 1, 1, NULL, 'primary', 'Order \'o-157\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(127, '2020-10-18 16:27:29', 1, 1, NULL, 'primary', 'Order \'o-158\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(128, '2020-10-18 16:34:43', 1, 1, NULL, 'primary', 'Order \'o-126\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(129, '2020-10-18 16:49:47', 1, 1, NULL, 'primary', 'Order \'o-130\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(130, '2020-10-18 16:49:49', 1, 1, NULL, 'primary', 'Order \'o-131\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(131, '2020-10-18 16:49:50', 1, 1, NULL, 'primary', 'Order \'o-137\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(132, '2020-10-18 16:49:51', 1, 1, NULL, 'primary', 'Order \'o-138\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(133, '2020-10-18 16:49:53', 1, 1, NULL, 'primary', 'Order \'o-139\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(134, '2020-10-18 16:49:54', 1, 1, NULL, 'primary', 'Order \'o-140\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL);

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

--
-- Dumping data for table `messages_read`
--

INSERT INTO `messages_read` (`id`, `message_id`, `user_id`, `read_time`) VALUES
(1, 1, 1, '2020-10-15 19:49:44'),
(2, 1, 1, '2020-10-15 19:50:02'),
(3, 2, 1, '2020-10-15 19:50:03'),
(4, 3, 1, '2020-10-15 19:50:04'),
(5, 4, 1, '2020-10-15 19:50:30'),
(6, 5, 1, '2020-10-15 19:50:31'),
(7, 6, 1, '2020-10-15 19:50:32'),
(8, 7, 1, '2020-10-15 19:50:32'),
(9, 8, 1, '2020-10-15 19:50:33'),
(10, 9, 1, '2020-10-15 19:50:34'),
(11, 10, 1, '2020-10-15 19:50:34'),
(12, 11, 1, '2020-10-15 19:50:35'),
(13, 12, 1, '2020-10-15 19:50:35'),
(14, 13, 1, '2020-10-15 19:50:36'),
(15, 14, 1, '2020-10-15 19:50:36'),
(16, 15, 1, '2020-10-15 19:50:37'),
(17, 16, 1, '2020-10-15 19:50:37'),
(18, 17, 1, '2020-10-15 19:50:38'),
(19, 18, 1, '2020-10-15 19:50:38'),
(20, 19, 1, '2020-10-15 19:50:39'),
(21, 20, 1, '2020-10-15 19:50:39'),
(22, 21, 1, '2020-10-15 19:50:39'),
(23, 22, 1, '2020-10-15 19:50:40'),
(24, 23, 1, '2020-10-15 19:50:40'),
(25, 24, 1, '2020-10-15 19:50:41'),
(26, 25, 1, '2020-10-15 19:50:41'),
(27, 26, 1, '2020-10-15 19:50:42'),
(28, 27, 1, '2020-10-15 19:50:42'),
(29, 28, 1, '2020-10-15 19:50:42'),
(30, 29, 1, '2020-10-15 19:50:43'),
(31, 30, 1, '2020-10-15 19:50:43'),
(32, 31, 1, '2020-10-15 19:50:44'),
(33, 32, 1, '2020-10-15 19:50:44'),
(34, 33, 1, '2020-10-15 19:50:44'),
(35, 34, 1, '2020-10-15 19:50:45'),
(36, 35, 1, '2020-10-15 19:50:45'),
(37, 36, 1, '2020-10-15 19:50:46'),
(38, 37, 1, '2020-10-15 19:50:46'),
(39, 38, 1, '2020-10-15 19:50:46'),
(40, 39, 1, '2020-10-15 19:50:47'),
(41, 40, 1, '2020-10-15 19:50:47'),
(42, 41, 1, '2020-10-15 19:50:47'),
(43, 42, 1, '2020-10-15 19:50:48'),
(44, 43, 1, '2020-10-15 19:50:48'),
(45, 44, 1, '2020-10-15 19:50:48'),
(46, 45, 1, '2020-10-15 19:50:49'),
(47, 46, 1, '2020-10-15 19:50:49'),
(48, 47, 1, '2020-10-15 19:50:49'),
(49, 48, 1, '2020-10-15 19:50:49'),
(50, 49, 1, '2020-10-15 19:50:50'),
(51, 50, 1, '2020-10-15 19:50:50'),
(52, 51, 1, '2020-10-15 19:50:50'),
(53, 52, 1, '2020-10-15 19:50:51'),
(54, 53, 1, '2020-10-15 19:50:51'),
(55, 54, 1, '2020-10-15 19:50:51'),
(56, 55, 1, '2020-10-15 19:50:52'),
(57, 56, 1, '2020-10-15 19:50:52'),
(58, 57, 1, '2020-10-15 19:50:52'),
(59, 58, 1, '2020-10-15 19:50:53'),
(60, 59, 1, '2020-10-15 19:50:53'),
(61, 1, 1, '2020-10-15 19:57:24'),
(62, 60, 1, '2020-10-15 21:27:22'),
(63, 61, 1, '2020-10-15 21:27:23'),
(64, 62, 1, '2020-10-15 21:27:23'),
(65, 63, 1, '2020-10-15 21:27:23'),
(66, 64, 1, '2020-10-15 21:27:24'),
(67, 65, 1, '2020-10-15 21:27:24'),
(68, 66, 1, '2020-10-15 21:27:25'),
(69, 67, 1, '2020-10-15 21:27:25'),
(70, 68, 1, '2020-10-15 21:27:25'),
(71, 69, 1, '2020-10-15 21:27:25'),
(72, 70, 1, '2020-10-15 21:27:26'),
(73, 71, 1, '2020-10-15 21:27:26'),
(74, 72, 1, '2020-10-15 21:27:26'),
(75, 73, 1, '2020-10-15 21:27:27'),
(76, 74, 1, '2020-10-15 21:27:27'),
(77, 75, 1, '2020-10-15 21:27:27'),
(78, 76, 1, '2020-10-15 21:27:28'),
(79, 77, 1, '2020-10-15 21:27:28'),
(80, 78, 1, '2020-10-15 21:27:28'),
(81, 79, 1, '2020-10-15 21:27:29'),
(82, 80, 1, '2020-10-15 21:27:29'),
(83, 81, 1, '2020-10-15 21:27:30'),
(84, 82, 1, '2020-10-15 21:27:30'),
(85, 83, 1, '2020-10-15 21:27:31'),
(86, 84, 1, '2020-10-15 21:27:31'),
(87, 85, 1, '2020-10-15 21:27:32'),
(88, 86, 1, '2020-10-15 21:27:32'),
(89, 87, 1, '2020-10-15 21:27:33'),
(90, 88, 1, '2020-10-15 21:27:33'),
(91, 89, 1, '2020-10-15 21:27:34'),
(92, 90, 1, '2020-10-15 21:27:34'),
(93, 91, 1, '2020-10-15 21:32:11'),
(94, 92, 1, '2020-10-15 22:00:27'),
(95, 93, 1, '2020-10-15 22:00:27'),
(96, 94, 1, '2020-10-15 22:00:28'),
(97, 95, 1, '2020-10-15 22:00:28'),
(98, 96, 1, '2020-10-15 22:00:29'),
(99, 97, 1, '2020-10-15 22:00:29'),
(100, 98, 1, '2020-10-15 22:00:30'),
(101, 99, 1, '2020-10-15 22:00:30'),
(102, 100, 1, '2020-10-15 22:00:31'),
(103, 101, 1, '2020-10-15 22:00:32'),
(104, 102, 1, '2020-10-15 22:00:33'),
(105, 103, 1, '2020-10-15 22:32:38'),
(106, 104, 1, '2020-10-15 22:32:39'),
(107, 105, 1, '2020-10-15 22:32:39'),
(108, 106, 1, '2020-10-15 22:32:40'),
(109, 107, 1, '2020-10-15 22:32:40'),
(110, 108, 1, '2020-10-15 22:32:41'),
(111, 109, 1, '2020-10-15 22:32:41'),
(112, 110, 1, '2020-10-15 22:32:41'),
(113, 111, 1, '2020-10-15 22:32:44'),
(114, 112, 1, '2020-10-15 22:32:45'),
(115, 113, 1, '2020-10-15 22:32:45'),
(116, 114, 1, '2020-10-18 16:27:39'),
(117, 115, 1, '2020-10-18 16:27:39'),
(118, 116, 1, '2020-10-18 16:27:40'),
(119, 117, 1, '2020-10-18 16:27:40'),
(120, 118, 1, '2020-10-18 16:27:41'),
(121, 119, 1, '2020-10-18 16:27:41'),
(122, 120, 1, '2020-10-18 16:27:42'),
(123, 121, 1, '2020-10-18 16:27:42'),
(124, 122, 1, '2020-10-18 16:27:43'),
(125, 123, 1, '2020-10-18 16:27:43'),
(126, 124, 1, '2020-10-18 16:27:43');

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
  `customer` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `number`, `client_id`, `state`, `current_route`, `deadline`, `estimated`, `customer`) VALUES
(1, 'o-112', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(2, 'o-113', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(3, 'o-114', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(4, 'o-115', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(5, 'o-116', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(6, 'o-117', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(7, 'o-118', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(8, 'o-119', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(9, 'o-120', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(10, 'o-121', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(11, 'o-122', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(12, 'o-123', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(13, 'o-124', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(14, 'o-125', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(15, 'o-126', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(16, 'o-127', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(17, 'o-128', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(18, 'o-129', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(19, 'o-130', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(20, 'o-131', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(21, 'o-132', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(22, 'o-133', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(23, 'o-134', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(24, 'o-135', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(25, 'o-136', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(26, 'o-137', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(27, 'o-138', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(28, 'o-139', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(29, 'o-140', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(30, 'o-141', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(31, 'o-142', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(32, 'o-143', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(33, 'o-144', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(34, 'o-145', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(35, 'o-146', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(36, 'o-147', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(37, 'o-148', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(38, 'o-149', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(39, 'o-150', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(40, 'o-151', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(41, 'o-152', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(42, 'o-153', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(43, 'o-154', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(44, 'o-155', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(45, 'o-156', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(46, 'o-157', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(47, 'o-158', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(48, 'o-159', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(49, 'o-160', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(50, 'o-161', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(51, 'o-162', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(52, 'o-163', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(53, 'o-164', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(54, 'o-165', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(55, 'o-166', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(56, 'o-167', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(57, 'o-168', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(58, 'o-169', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(59, 'o-170', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(60, 'o-171', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(61, 'o-172', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(62, 'o-173', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(63, 'o-174', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(64, 'o-175', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(65, 'o-176', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(66, 'o-177', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(67, 'o-178', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(68, 'o-179', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(69, 'o-180', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(70, 'o-181', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(71, 'o-182', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(72, 'o-183', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(73, 'o-184', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(74, 'o-185', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(75, 'o-186', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(76, 'o-187', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(77, 'o-188', 1, 'ASSIGNED', 1, NULL, NULL, NULL),
(78, 'o-189', 1, 'ASSIGNED', 1, NULL, NULL, NULL);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq ID', AUTO_INCREMENT=221;
--
-- AUTO_INCREMENT for table `clients`
--
ALTER TABLE `clients`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq id', AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq id', AUTO_INCREMENT=135;
--
-- AUTO_INCREMENT for table `messages_read`
--
ALTER TABLE `messages_read`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=127;
--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=79;
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
