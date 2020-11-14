-- phpMyAdmin SQL Dump
-- version 4.6.6deb5
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 14, 2020 at 02:04 PM
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `assignWorkcenterToRoutePart` (IN `_client_id` BIGINT UNSIGNED, IN `_order_id` BIGINT UNSIGNED, IN `_order_part` VARCHAR(4096), IN `_operation` VARCHAR(250), IN `_wc` VARCHAR(50), IN `_bucket` VARCHAR(10), IN `_consumption_plan` DOUBLE)  NO SQL
insert into assigns  (client_id, order_id, order_part, operation, workcenter_id, bucket, fullset, consumption_plan) VALUES(`_client_id`, `_order_id`, `_order_part`, `_operation`, getWorkcenterID(`_client_id`, `_wc`), `_bucket`, 1, `_consumption_plan`)$$

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
SELECT assigns.*, orders.number, orders.state, orders.estimated, orders.deadline, orders.baseline FROM assigns 
left join orders on orders.id=assigns.order_id
WHERE bucket like  'OUTCOME' and getWorkcenterID(`_client_id`, `_wc_from`) = workcenter_id and getWorkcenterID(`_client_id`, `_wc_to`) = next_workcenter_id order by orders.priority desc, orders.deadline asc;
end$$

DROP PROCEDURE IF EXISTS `getAssignsByWorkcenter`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignsByWorkcenter` (IN `_client_id` BIGINT UNSIGNED, IN `_wc` VARCHAR(50), IN `_buckets` VARCHAR(250))  NO SQL
BEGIN
set @wc_id = getWorkcenterID(`_client_id`, `_wc`);
call getAssignsByWorkcenterID(`_client_id`, @wc_id, `_buckets`);
end$$

DROP PROCEDURE IF EXISTS `getAssignsByWorkcenterID`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignsByWorkcenterID` (IN `_client_id` BIGINT UNSIGNED, IN `_workcenter_id` BIGINT UNSIGNED, IN `_buckets` VARCHAR(250))  NO SQL
BEGIN
select a.*, orders.number, orders.state, orders.estimated, orders.deadline, orders.baseline from (select id, order_id, bucket, order_part, event_time, fullset from assigns where client_id = `_client_id` and workcenter_id = `_workcenter_id` and find_in_set(bucket, `_buckets`) > 0 order by assigns.priority desc, assigns.id asc) as a left join orders on orders.id = a.order_id order by orders.priority desc, orders.deadline asc;
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
select assigns.*, workcenters.name as workcenter_name, roads.id as road_id, roads.name as road_name
from assigns
left join workcenters on workcenters.id=assigns.workcenter_id
left join roads on roads.from_wc = assigns.workcenter_id and roads.to_wc = assigns.next_workcenter_id 
where assigns.order_id = `_order_id`
order by assigns.event_time desc, assigns.id desc$$

DROP PROCEDURE IF EXISTS `getOrderInfo`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrderInfo` (IN `_client_id` BIGINT UNSIGNED, IN `_order_num` VARCHAR(50))  NO SQL
select * from orders where client_id = `_client_id` and number like `_order_num`$$

DROP PROCEDURE IF EXISTS `getOrders`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrders` (IN `_client_id` BIGINT UNSIGNED ZEROFILL)  NO SQL
select * from orders where client_id = `_client_id` order by orders.priority desc, orders.deadline asc$$

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
SELECT orders.number as order_num, orders.id as order_id, orders.current_route as route_num, @new_bucket as next_bucket, assigns.order_part FROM `assigns` left join orders on assigns.order_id = orders.id WHERE assigns.id=`_id`;
end$$

DROP PROCEDURE IF EXISTS `moveAssignToNextWorkcenter`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `moveAssignToNextWorkcenter` (IN `_assign_id` BIGINT UNSIGNED, IN `_set_count` INT)  NO SQL
BEGIN
select client_id, next_workcenter_id, next_order_part, next_operation, order_id, next_consumption
into @client_id, @next_workcenter_id, @next_order_part, @next_operation, @order_id, @consumption
from assigns
where id=`_assign_id`;
select priority into @order_priority from orders where id=@order_id;
START TRANSACTION;
set @id_next = null;
set @id_next = (select id from assigns where client_id = @client_id and workcenter_id = @next_workcenter_id and order_id = @order_id);
if @id_next is null then
    insert into assigns (client_id, workcenter_id, order_id, order_part, operation, bucket, consumption_plan, priority) values(@client_id, @next_workcenter_id, @order_id, @next_order_part, @next_operation, 'INCOME', @consumption, @order_priority);
    set @id_next = LAST_INSERT_ID();
    set @set_count = 1;
else
    set @set_count = (SELECT count(*)  FROM `assigns` WHERE next_id = @id_next) + 1;
end if;

if @set_count = `_set_count` THEN
update assigns set fullset=1 where id=@id_next;
end if;

update assigns set bucket = null, next_id = @id_next WHERE id = `_assign_id`;
COMMIT;
end$$

DROP PROCEDURE IF EXISTS `updateAssignOrderPart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateAssignOrderPart` (IN `_id` BIGINT UNSIGNED, IN `_new_order_part` VARCHAR(250), IN `_next_wc` VARCHAR(50), IN `_next_order_part` VARCHAR(4096), IN `_next_operation` VARCHAR(250), IN `_next_consumption` DOUBLE)  NO SQL
update assigns set order_part = `_new_order_part`, next_workcenter_id = getWorkcenterID(assigns.client_id, `_next_wc`), next_order_part = `_next_order_part`, next_operation = `_next_operation`, next_consumption= `_next_consumption` where id=`_id`$$

DROP PROCEDURE IF EXISTS `updateBaseline`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateBaseline` (IN `_order_id` BIGINT UNSIGNED, IN `_time` DATETIME)  NO SQL
update orders set baseline=`_time`, estimated=`_time` where id = `_order_id`$$

DROP PROCEDURE IF EXISTS `updateEstimatedTime`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEstimatedTime` (IN `_order_id` BIGINT UNSIGNED, IN `_time` DATETIME)  NO SQL
update orders set estimated=`_time` where id = `_order_id`$$

DROP PROCEDURE IF EXISTS `updateRoadDesc`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateRoadDesc` (IN `_client_id` BIGINT UNSIGNED, IN `_road_name` VARCHAR(50), IN `_desc` VARCHAR(250))  NO SQL
update roads set `description`=`_desc` where client_id=`_client_id` and `name` like `_road_name`$$

DROP PROCEDURE IF EXISTS `updateWorkcenterDesc`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateWorkcenterDesc` (IN `_client_id` BIGINT UNSIGNED, IN `_wc_name` VARCHAR(50), IN `_desc` VARCHAR(250))  NO SQL
update workcenters set `description`=`_desc` where client_id=`_client_id` and `name` like `_wc_name`$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `addMessage`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `addMessage` (`_client_id` BIGINT UNSIGNED, `_order_id` BIGINT UNSIGNED, `_message_from` BIGINT UNSIGNED, `_message_to` BIGINT UNSIGNED, `_message_type` VARCHAR(9), `_body` VARCHAR(250), `_thread_id` BIGINT UNSIGNED) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'adds new Message'
BEGIN
if `_order_id` = 0 THEN
set `_order_id` = NULL;
end IF;

if `_message_to` = 0 THEN
set `_message_to` = NULL;
end IF;


if `_message_from` = 0 THEN
set `_message_from` = NULL;
end IF;

if `_thread_id` = 0 THEN
set `_thread_id` = NULL;
end IF;

INSERT INTO `messages`(`client_id`, `order_id`, `message_from`, `message_to`, `message_type`, `body`, thread_id) VALUES (`_client_id`, `_order_id`, `_message_from`, `_message_to`, `_message_type`, `_body`, `_thread_id`);
return (SELECT LAST_INSERT_ID());

end$$

DROP FUNCTION IF EXISTS `addOrder`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `addOrder` (`_client_id` BIGINT UNSIGNED, `_number` VARCHAR(50), `_state` VARCHAR(10), `_route_id` INT, `_deadline` DATETIME) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'adds new order and returns uniq ID of order in database'
begin
insert into orders (number, client_id, state, current_route, deadline) values(`_number`, `_client_id`, `_state`, `_route_id`, `_deadline`);
return (SELECT LAST_INSERT_ID());
end$$

DROP FUNCTION IF EXISTS `getAssignConsumptionInWorkcenter`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getAssignConsumptionInWorkcenter` (`_assign_id` BIGINT UNSIGNED) RETURNS DOUBLE NO SQL
BEGIN
select workcenter_id, priority into @wc_id, @pr
from assigns where id = `_assign_id`;
set @r = (select sum(consumption_plan) from assigns where id <= `_assign_id` and priority >= @pr and workcenter_id=@wc_id and (bucket LIKE 'INCOME' or bucket like 'PROCESSING'));
return @r;
end$$

DROP FUNCTION IF EXISTS `getClientID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getClientID` (`_factoryName` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'returns client ID by mnemonic name of the factory'
return (select id from clients where name like `_factoryName`)$$

DROP FUNCTION IF EXISTS `getOrderConsumptionInWorkcenter`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getOrderConsumptionInWorkcenter` (`_order_id` BIGINT UNSIGNED, `_workcenter` VARCHAR(50)) RETURNS DOUBLE NO SQL
BEGIN
select client_id, priority into @client_id, @pr from orders where id=`_order_id`;
set @r = (select sum(consumption_plan) from assigns where workcenter_id = getWorkcenterID(@client_id, `_workcenter`) and (bucket like 'INCOME' or bucket like 'PROCESSING') and priority >= @pr);
RETURN @r;
END$$

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
  `consumption_plan` double NOT NULL,
  `consumption_fact` double DEFAULT NULL,
  `fullset` tinyint(4) DEFAULT NULL,
  `prodmat` varchar(50) DEFAULT NULL,
  `next_workcenter_id` bigint(20) UNSIGNED DEFAULT NULL,
  `next_order_part` varchar(4096) DEFAULT NULL,
  `next_operation` varchar(250) DEFAULT NULL,
  `event_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Date and time of event',
  `next_consumption` double DEFAULT NULL,
  `next_id` bigint(20) UNSIGNED DEFAULT NULL,
  `priority` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `assigns`
--

INSERT INTO `assigns` (`id`, `client_id`, `order_id`, `workcenter_id`, `bucket`, `order_part`, `operation`, `consumption_plan`, `consumption_fact`, `fullset`, `prodmat`, `next_workcenter_id`, `next_order_part`, `next_operation`, `event_time`, `next_consumption`, `next_id`, `priority`) VALUES
(1, 1, 1, 1, NULL, 'o-212.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-212.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-13 04:59:39', 480, 77, 0),
(2, 1, 1, 5, NULL, 'o-212.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-212.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 04:53:08', 45, 75, 0),
(3, 1, 3, 1, NULL, 'o-213.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-213.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:43:36', 480, 63, 0),
(4, 1, 3, 5, 'PROCESSING', 'o-213.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-12 18:43:49', NULL, NULL, 0),
(5, 1, 4, 1, 'PROCESSING', 'o-214.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-11 15:38:03', NULL, NULL, 0),
(6, 1, 4, 5, 'PROCESSING', 'o-214.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-12 18:43:51', NULL, NULL, 0),
(7, 1, 5, 1, 'INCOME', 'o-215.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 19:40:03', NULL, NULL, 0),
(8, 1, 5, 5, 'PROCESSING', 'o-215.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-12 18:43:53', NULL, NULL, 0),
(9, 1, 6, 1, NULL, 'o-216.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-216.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:46:33', 480, 72, 0),
(10, 1, 6, 5, NULL, 'o-216.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-216.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:44:20', 45, 65, 0),
(11, 1, 7, 1, 'INCOME', 'o-217.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 19:40:16', NULL, NULL, 0),
(12, 1, 7, 5, 'PROCESSING', 'o-217.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:57:59', NULL, NULL, 0),
(13, 1, 8, 1, 'PROCESSING', 'o-218.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-11 15:37:50', NULL, NULL, 0),
(14, 1, 8, 5, 'PROCESSING', 'o-218.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:58:01', NULL, NULL, 0),
(15, 1, 9, 1, 'PROCESSING', 'o-219.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:58:37', NULL, NULL, 0),
(16, 1, 9, 5, 'PROCESSING', 'o-219.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-12 18:43:54', NULL, NULL, 0),
(17, 1, 10, 1, 'PROCESSING', 'o-220.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:58:41', NULL, NULL, 0),
(18, 1, 10, 5, 'PROCESSING', 'o-220.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:58:04', NULL, NULL, 0),
(19, 1, 11, 1, NULL, 'o-221.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-221.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-13 04:59:00', 480, 76, 0),
(20, 1, 11, 5, 'PROCESSING', 'o-221.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-12 18:43:56', NULL, NULL, 0),
(21, 1, 12, 1, 'PROCESSING', 'o-222.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 09:45:21', NULL, NULL, 0),
(22, 1, 12, 5, 'PROCESSING', 'o-222.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 20:23:18', NULL, NULL, 0),
(23, 1, 13, 1, NULL, 'o-223.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-223.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 19:00:18', 480, 74, 0),
(24, 1, 13, 5, NULL, 'o-223.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-223.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:59:33', 45, 73, 0),
(25, 1, 14, 1, NULL, 'o-224.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-224.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:43:38', 480, 64, 0),
(26, 1, 14, 5, NULL, 'o-224.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-224.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:44:23', 45, 66, 0),
(27, 1, 15, 1, 'PROCESSING', 'o-10.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-11 19:51:25', NULL, NULL, 0),
(28, 1, 15, 5, 'OUTCOME', 'o-10.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-10.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:44:03', 45, NULL, 0),
(29, 1, 16, 1, 'PROCESSING', 'o-11.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-11 19:51:27', NULL, NULL, 0),
(30, 1, 16, 5, 'OUTCOME', 'o-11.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-11.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:44:05', 45, NULL, 0),
(31, 1, 17, 1, 'PROCESSING', 'o-12.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-11 19:51:29', NULL, NULL, 0),
(32, 1, 17, 5, 'INCOME', 'o-12.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 19:49:16', NULL, NULL, 0),
(33, 1, 18, 1, 'OUTCOME', 'o-13.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-13.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:43:28', 480, NULL, 0),
(34, 1, 18, 5, NULL, 'o-13.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-13.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 08:24:20', 45, 79, 0),
(35, 1, 19, 1, NULL, 'o-225.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-225.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:44:51', 480, 70, 0),
(36, 1, 19, 5, NULL, 'o-225.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-225.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:44:31', 45, 67, 0),
(37, 1, 20, 1, NULL, 'o-230.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-230.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:44:45', 480, 69, 0),
(38, 1, 20, 5, NULL, 'o-230.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-230.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 09:32:50', 45, 88, 0),
(39, 1, 21, 1, NULL, 'o-236.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-236.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-14 09:23:07', 480, 106, 0),
(40, 1, 21, 5, NULL, 'o-236.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-236.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:44:35', 45, 68, 0),
(41, 1, 22, 1, 'OUTCOME', 'o-240.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-240.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:43:24', 480, NULL, 0),
(42, 1, 22, 5, 'INCOME', 'o-240.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 19:51:54', NULL, NULL, 0),
(43, 1, 23, 1, NULL, 'o-247.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-247.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:44:54', 480, 71, 0),
(44, 1, 23, 5, 'INCOME', 'o-247.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 19:52:08', NULL, NULL, 0),
(45, 1, 24, 1, 'INCOME', 'o-244.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 19:52:32', NULL, NULL, 0),
(46, 1, 24, 5, 'PROCESSING', 'o-244.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 09:43:46', NULL, NULL, 0),
(47, 1, 25, 1, 'PROCESSING', 'o-250.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-12 18:43:16', NULL, NULL, 0),
(48, 1, 25, 5, 'OUTCOME', 'o-250.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-250.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:26:22', 45, NULL, 0),
(49, 1, 26, 1, 'INCOME', 'o-237.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 19:55:14', NULL, NULL, 0),
(50, 1, 26, 5, 'INCOME', 'o-237.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 19:55:14', NULL, NULL, 0),
(51, 1, 27, 1, 'INCOME', 'o-239.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 03:24:47', NULL, NULL, 0),
(52, 1, 27, 5, 'PROCESSING', 'o-239.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 09:43:31', NULL, NULL, 0),
(53, 1, 28, 1, 'INCOME', 'o-235.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:41:28', NULL, NULL, 0),
(54, 1, 28, 5, 'INCOME', 'o-235.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:41:28', NULL, NULL, 0),
(55, 1, 29, 1, 'INCOME', 'o-249.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:41:46', NULL, NULL, 0),
(56, 1, 29, 5, 'INCOME', 'o-249.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:41:46', NULL, NULL, 0),
(57, 1, 30, 1, NULL, 'o-246.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-246.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-14 09:13:08', 480, 105, 0),
(58, 1, 30, 5, NULL, 'o-246.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-246.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:50:54', 45, 95, 0),
(59, 1, 31, 1, 'INCOME', 'o-254.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:42:21', NULL, NULL, 0),
(60, 1, 31, 5, 'INCOME', 'o-254.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:42:21', NULL, NULL, 0),
(61, 1, 32, 1, 'INCOME', 'o-258.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:42:43', NULL, NULL, 0),
(62, 1, 32, 5, 'INCOME', 'o-258.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:42:44', NULL, NULL, 0),
(63, 1, 3, 4, NULL, 'o-213.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-213.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 08:23:09', 45, 78, 0),
(64, 1, 14, 4, NULL, 'o-224.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-224.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 04:39:00', 45, 66, 0),
(65, 1, 6, 3, NULL, 'o-216.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-216.1.wheelpair.1', 'qualitycheck', '2020-11-13 08:24:33', 240, 80, 0),
(66, 1, 14, 3, NULL, 'o-224.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-224.1.wheelpair.1', 'qualitycheck', '2020-11-14 09:08:54', 240, 104, 0),
(67, 1, 19, 3, 'OUTCOME', 'o-225.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-225.1.wheelpair.1', 'qualitycheck', '2020-11-13 08:23:28', 240, NULL, 0),
(68, 1, 21, 3, 'PROCESSING', 'o-236.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-14 09:23:53', NULL, NULL, 0),
(69, 1, 20, 4, NULL, 'o-230.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-230.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 09:04:49', 45, 88, 0),
(70, 1, 19, 4, NULL, 'o-225.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-225.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 03:26:03', 45, 67, 0),
(71, 1, 23, 4, 'INCOME', 'o-247.1.wheelpair.1.1.shaft.1', 'blankprocessing', 480, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-12 18:44:54', NULL, NULL, 0),
(72, 1, 6, 4, NULL, 'o-216.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-216.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:47:29', 45, 65, 0),
(73, 1, 13, 3, 'PROCESSING', 'o-223.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 03:26:23', NULL, NULL, 0),
(74, 1, 13, 4, NULL, 'o-223.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-223.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 19:00:32', 45, 73, 0),
(75, 1, 1, 3, NULL, 'o-212.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-212.1.wheelpair.1', 'qualitycheck', '2020-11-13 08:37:36', 240, 81, 0),
(76, 1, 11, 4, 'OUTCOME', 'o-221.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-221.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 08:36:42', 45, NULL, 0),
(77, 1, 1, 4, NULL, 'o-212.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-212.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 08:23:57', 45, 75, 0),
(78, 1, 3, 3, 'INCOME', 'o-213.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-13 08:23:09', NULL, NULL, 0),
(79, 1, 18, 3, 'INCOME', 'o-13.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-13 08:24:20', NULL, NULL, 0),
(80, 1, 6, 2, 'PROCESSING', 'o-216.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 08:39:15', NULL, NULL, 0),
(81, 1, 1, 2, 'INCOME', 'o-212.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 08:37:36', NULL, NULL, 0),
(82, 1, 33, 1, 'PROCESSING', 'o-226.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 08:44:23', NULL, NULL, 0),
(83, 1, 33, 5, 'INCOME', 'o-226.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 08:38:25', NULL, NULL, 0),
(84, 1, 34, 1, NULL, 'o-259.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-259.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-13 10:53:16', 480, 97, 0),
(85, 1, 34, 5, NULL, 'o-259.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-259.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:53:28', 45, 99, 0),
(86, 1, 35, 1, 'INCOME', 'o-261.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 08:46:45', NULL, NULL, 0),
(87, 1, 35, 5, 'INCOME', 'o-261.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 08:46:45', NULL, NULL, 0),
(88, 1, 20, 3, 'PROCESSING', 'o-230.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 09:33:01', NULL, NULL, 0),
(89, 1, 36, 1, NULL, 'o-273.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-273.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-13 10:53:14', 480, 96, 0),
(90, 1, 36, 5, NULL, 'o-273.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-273.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:53:27', 45, 98, 0),
(91, 1, 37, 1, 'INCOME', 'o-282.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 10:44:22', NULL, NULL, 0),
(92, 1, 37, 5, 'PROCESSING', 'o-282.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 10:51:30', NULL, NULL, 0),
(93, 1, 38, 1, 'PROCESSING', 'o-252.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 11:29:51', NULL, NULL, 0),
(94, 1, 38, 5, 'INCOME', 'o-252.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 10:48:52', NULL, NULL, 0),
(95, 1, 30, 3, 'INCOME', 'o-246.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-14 09:13:38', NULL, NULL, 0),
(96, 1, 36, 4, NULL, 'o-273.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-273.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:54:22', 45, 98, 0),
(97, 1, 34, 4, NULL, 'o-259.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-259.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:54:18', 45, 99, 0),
(98, 1, 36, 3, 'INCOME', 'o-273.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 10:54:22', NULL, NULL, 0),
(99, 1, 34, 3, 'INCOME', 'o-259.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 10:54:18', NULL, NULL, 0),
(100, 1, 39, 1, 'INCOME', 'o-241.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 11:19:18', NULL, NULL, 0),
(101, 1, 39, 5, 'INCOME', 'o-241.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 11:19:18', NULL, NULL, 0),
(102, 1, 40, 1, 'INCOME', 'o-266.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 11:19:18', NULL, NULL, 0),
(103, 1, 40, 5, 'INCOME', 'o-266.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-13 11:19:18', NULL, NULL, 0),
(104, 1, 14, 2, 'INCOME', 'o-224.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-14 09:08:54', NULL, NULL, 0),
(105, 1, 30, 4, NULL, 'o-246.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-246.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-14 09:13:38', 45, 95, 0),
(106, 1, 21, 4, NULL, 'o-236.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-236.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-14 09:23:41', 45, 68, 0),
(107, 1, 41, 1, 'INCOME', 'o-232.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-14 13:43:39', NULL, NULL, 0),
(108, 1, 41, 5, 'INCOME', 'o-232.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-14 13:43:39', NULL, NULL, 0);

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
  `order_id` bigint(20) UNSIGNED DEFAULT NULL,
  `message_from` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'from person',
  `message_to` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'to person or broadcast',
  `message_type` varchar(10) NOT NULL COMMENT 'INFO, WARNING, CRITICAL',
  `body` varchar(160) NOT NULL,
  `thread_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Previous message in thread'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Messages of users';

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `message_time`, `client_id`, `order_id`, `message_from`, `message_to`, `message_type`, `body`, `thread_id`) VALUES
(1, '2020-11-10 08:59:14', 1, NULL, 1, NULL, 'primary', 'Order \'o-224\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(2, '2020-11-10 09:45:59', 1, NULL, 1, NULL, 'primary', 'Order \'o-216\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(3, '2020-11-11 17:44:43', 1, NULL, 1, NULL, 'primary', 'Order \'o-213\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(4, '2020-11-12 18:43:18', 1, NULL, 1, NULL, 'primary', 'Order \'o-230\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(5, '2020-11-12 18:43:20', 1, NULL, 1, NULL, 'primary', 'Order \'o-225\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(6, '2020-11-12 18:43:22', 1, NULL, 1, NULL, 'primary', 'Order \'o-236\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(7, '2020-11-12 18:43:24', 1, NULL, 1, NULL, 'primary', 'Order \'o-240\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(8, '2020-11-12 18:43:26', 1, NULL, 1, NULL, 'primary', 'Order \'o-247\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(9, '2020-11-12 18:43:28', 1, NULL, 1, NULL, 'primary', 'Order \'o-13\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(10, '2020-11-12 18:44:00', 1, NULL, 1, NULL, 'primary', 'Order \'o-223\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(11, '2020-11-12 18:44:02', 1, NULL, 1, NULL, 'primary', 'Order \'o-224\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(12, '2020-11-12 18:44:03', 1, NULL, 1, NULL, 'primary', 'Order \'o-10\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(13, '2020-11-12 18:44:05', 1, NULL, 1, NULL, 'primary', 'Order \'o-11\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(14, '2020-11-12 18:44:07', 1, NULL, 1, NULL, 'primary', 'Order \'o-13\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(15, '2020-11-12 18:44:09', 1, NULL, 1, NULL, 'primary', 'Order \'o-225\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(16, '2020-11-12 18:44:11', 1, NULL, 1, NULL, 'primary', 'Order \'o-236\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(17, '2020-11-12 18:45:07', 1, NULL, 1, NULL, 'primary', 'Order \'o-213\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(18, '2020-11-12 18:45:08', 1, NULL, 1, NULL, 'primary', 'Order \'o-224\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(19, '2020-11-12 18:45:10', 1, NULL, 1, NULL, 'primary', 'Order \'o-230\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(20, '2020-11-12 18:45:50', 1, NULL, 1, NULL, 'primary', 'Order \'o-216\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(21, '2020-11-12 18:47:09', 1, NULL, 1, NULL, 'primary', 'Order \'o-216\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(22, '2020-11-12 18:47:39', 1, NULL, 1, NULL, 'primary', 'Order \'o-216\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(23, '2020-11-12 19:00:10', 1, NULL, 1, NULL, 'primary', 'Order \'o-223\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(24, '2020-11-12 19:00:26', 1, NULL, 1, NULL, 'primary', 'Order \'o-223\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(25, '2020-11-13 03:25:48', 1, NULL, 1, NULL, 'primary', 'Order \'o-225\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(26, '2020-11-13 04:52:10', 1, NULL, 1, NULL, 'primary', 'Order \'o-212\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(27, '2020-11-13 04:52:46', 1, NULL, 1, NULL, 'primary', 'Order \'o-212\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(28, '2020-11-13 04:58:14', 1, NULL, 1, NULL, 'primary', 'Order \'o-221\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(29, '2020-11-13 08:23:26', 1, NULL, 1, NULL, 'primary', 'Order \'o-224\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(30, '2020-11-13 08:23:28', 1, NULL, 1, NULL, 'primary', 'Order \'o-225\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(31, '2020-11-13 08:23:49', 1, NULL, 1, NULL, 'primary', 'Order \'o-212\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(32, '2020-11-13 08:36:42', 1, NULL, 1, NULL, 'primary', 'Order \'o-221\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(33, '2020-11-13 08:37:23', 1, NULL, 1, NULL, 'primary', 'Order \'o-212\' processed \'\' and ready to next workcenter \'wc2_4\'', NULL),
(34, '2020-11-13 09:32:38', 1, NULL, 1, NULL, 'primary', 'Order \'o-230\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(35, '2020-11-13 10:26:22', 1, 25, 1, NULL, 'primary', 'Order \'o-250\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(36, '2020-11-13 10:51:33', 1, 34, 1, NULL, 'primary', 'Order \'o-259\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(37, '2020-11-13 10:52:37', 1, 36, 1, NULL, 'primary', 'Order \'o-273\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(38, '2020-11-13 10:52:54', 1, 34, 1, NULL, 'primary', 'Order \'o-259\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(39, '2020-11-13 10:52:56', 1, 36, 1, NULL, 'primary', 'Order \'o-273\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(40, '2020-11-13 10:54:02', 1, 36, 1, NULL, 'primary', 'Order \'o-273\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(41, '2020-11-13 10:54:03', 1, 34, 1, NULL, 'primary', 'Order \'o-259\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(42, '2020-11-14 09:12:47', 1, 30, 1, NULL, 'primary', 'Order \'o-246\' processed \'\' and ready to next workcenter \'wc1_3\'', NULL),
(43, '2020-11-14 09:13:25', 1, 30, 1, NULL, 'primary', 'Order \'o-246\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(44, '2020-11-14 09:23:24', 1, 21, 1, NULL, 'primary', 'Order \'o-236\' processed \'\' and ready to next workcenter \'wc2_3\'', NULL),
(45, '2020-11-14 13:43:39', 1, 41, 1, NULL, 'primary', 'test', NULL);

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
(1, 1, 1, '2020-11-12 18:57:45'),
(2, 2, 1, '2020-11-12 18:57:45'),
(3, 3, 1, '2020-11-12 18:57:46'),
(4, 4, 1, '2020-11-12 18:57:46'),
(5, 5, 1, '2020-11-12 18:57:46'),
(6, 6, 1, '2020-11-12 18:57:47'),
(7, 7, 1, '2020-11-12 18:57:47'),
(8, 8, 1, '2020-11-12 18:57:47'),
(9, 9, 1, '2020-11-12 18:57:48'),
(10, 10, 1, '2020-11-12 18:57:48'),
(11, 11, 1, '2020-11-12 18:57:48'),
(12, 12, 1, '2020-11-12 18:57:49'),
(13, 13, 1, '2020-11-12 18:57:49'),
(14, 14, 1, '2020-11-12 18:57:49'),
(15, 15, 1, '2020-11-12 18:57:50'),
(16, 16, 1, '2020-11-12 18:57:50'),
(17, 17, 1, '2020-11-12 18:57:51'),
(18, 18, 1, '2020-11-12 18:57:51'),
(19, 19, 1, '2020-11-12 18:57:52'),
(20, 20, 1, '2020-11-12 18:57:52'),
(21, 21, 1, '2020-11-12 18:57:52'),
(22, 22, 1, '2020-11-12 18:57:53'),
(23, 23, 1, '2020-11-13 05:00:01'),
(24, 24, 1, '2020-11-13 05:00:02'),
(25, 25, 1, '2020-11-13 05:00:02'),
(26, 26, 1, '2020-11-13 05:00:03'),
(27, 27, 1, '2020-11-13 05:00:03'),
(28, 28, 1, '2020-11-13 05:00:05'),
(29, 29, 1, '2020-11-13 09:43:04'),
(30, 30, 1, '2020-11-13 09:43:05'),
(31, 31, 1, '2020-11-13 09:43:06'),
(32, 32, 1, '2020-11-13 09:43:08'),
(33, 33, 1, '2020-11-14 13:56:23'),
(34, 34, 1, '2020-11-14 13:56:24'),
(35, 35, 1, '2020-11-14 13:56:25'),
(36, 36, 1, '2020-11-14 13:56:25'),
(37, 37, 1, '2020-11-14 13:56:25'),
(38, 38, 1, '2020-11-14 13:56:25'),
(39, 39, 1, '2020-11-14 13:56:26'),
(40, 40, 1, '2020-11-14 13:56:26'),
(41, 41, 1, '2020-11-14 13:56:26'),
(42, 42, 1, '2020-11-14 13:56:27');

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
  `baseline` datetime DEFAULT NULL,
  `estimated` datetime DEFAULT NULL,
  `customer` varchar(50) DEFAULT NULL,
  `comment` varchar(1024) DEFAULT NULL,
  `change_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `import_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `priority` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `number`, `client_id`, `state`, `current_route`, `deadline`, `baseline`, `estimated`, `customer`, `comment`, `change_time`, `import_time`, `priority`) VALUES
(1, 'o-212', 1, 'ASSIGNED', 1, '2021-03-30 11:16:42', '2020-11-10 13:53:46', '2020-11-15 08:18:01', NULL, NULL, '2020-11-14 09:18:01', '2020-11-09 19:38:46', 0),
(3, 'o-213', 1, 'ASSIGNED', 1, '2021-05-21 11:16:42', '2020-11-10 16:24:24', '2020-11-15 18:33:01', NULL, NULL, '2020-11-14 09:18:01', '2020-11-09 19:39:24', 0),
(4, 'o-214', 1, 'ASSIGNED', 1, '2021-06-08 11:16:42', '2020-11-10 18:54:51', '2020-11-16 17:33:02', NULL, NULL, '2020-11-14 09:18:02', '2020-11-09 19:39:51', 0),
(5, 'o-215', 1, 'ASSIGNED', 1, '2021-05-18 11:16:42', '2020-11-10 21:25:03', '2020-11-16 20:03:01', NULL, NULL, '2020-11-14 09:18:01', '2020-11-09 19:40:03', 0),
(6, 'o-216', 1, 'ASSIGNED', 1, '2021-06-03 11:16:42', '2020-11-10 23:55:11', '2020-11-15 04:18:02', NULL, NULL, '2020-11-14 09:18:02', '2020-11-09 19:40:11', 0),
(7, 'o-217', 1, 'ASSIGNED', 1, '2021-04-01 11:16:42', '2020-11-11 02:25:16', '2020-11-16 22:33:01', NULL, NULL, '2020-11-14 09:18:01', '2020-11-09 19:40:16', 0),
(8, 'o-218', 1, 'ASSIGNED', 1, '2021-04-24 11:16:42', '2020-11-11 04:55:21', '2020-11-17 01:03:01', NULL, NULL, '2020-11-14 09:18:01', '2020-11-09 19:40:21', 0),
(9, 'o-219', 1, 'ASSIGNED', 1, '2021-04-09 11:16:42', '2020-11-11 07:25:26', '2020-11-17 03:33:01', NULL, NULL, '2020-11-14 09:18:01', '2020-11-09 19:40:26', 0),
(10, 'o-220', 1, 'ASSIGNED', 1, '2021-06-23 11:16:42', '2020-11-11 09:55:35', '2020-11-17 06:03:02', NULL, NULL, '2020-11-14 09:18:02', '2020-11-09 19:40:35', 0),
(11, 'o-221', 1, 'ASSIGNED', 1, '2021-05-17 11:16:42', '2020-11-11 12:25:39', '2020-11-19 05:33:01', NULL, NULL, '2020-11-14 09:18:01', '2020-11-09 19:40:39', 0),
(12, 'o-222', 1, 'ASSIGNED', 1, '2021-06-12 11:16:42', '2020-11-11 14:55:45', '2020-11-17 08:33:02', NULL, NULL, '2020-11-14 09:18:02', '2020-11-09 19:40:45', 0),
(13, 'o-223', 1, 'ASSIGNED', 1, '2021-03-18 11:16:42', '2020-11-11 17:25:55', '2020-11-15 17:48:01', NULL, NULL, '2020-11-14 09:18:01', '2020-11-09 19:40:54', 0),
(14, 'o-224', 1, 'ASSIGNED', 1, '2021-06-08 11:16:42', '2020-11-11 19:56:50', '2020-11-15 12:18:02', NULL, NULL, '2020-11-14 09:18:02', '2020-11-09 19:41:50', 0),
(15, 'o-10', 1, 'ASSIGNED', 1, '2021-03-21 19:47:03', '2020-11-11 22:33:40', '2020-11-18 16:03:01', NULL, NULL, '2020-11-14 09:18:01', '2020-11-09 19:48:39', 0),
(16, 'o-11', 1, 'ASSIGNED', 1, '2021-05-21 19:47:03', '2020-11-12 01:03:54', '2020-11-18 16:03:01', NULL, NULL, '2020-11-14 09:18:01', '2020-11-09 19:48:54', 0),
(17, 'o-12', 1, 'ASSIGNED', 1, '2021-03-12 19:47:03', '2020-11-12 03:34:16', '2020-11-17 16:03:00', NULL, NULL, '2020-11-14 09:18:00', '2020-11-09 19:49:16', 0),
(18, 'o-13', 1, 'ASSIGNED', 1, '2021-03-10 19:47:03', '2020-11-12 06:04:34', '2020-11-15 19:18:00', NULL, NULL, '2020-11-14 09:18:00', '2020-11-09 19:49:34', 0),
(19, 'o-225', 1, 'ASSIGNED', 1, '2020-11-27 19:48:21', '2020-11-12 08:35:56', '2020-11-15 00:17:59', NULL, NULL, '2020-11-14 09:17:59', '2020-11-09 19:50:56', 0),
(20, 'o-230', 1, 'ASSIGNED', 1, '2020-11-27 19:48:21', '2020-11-12 11:06:15', '2020-11-15 20:02:59', NULL, NULL, '2020-11-14 09:17:59', '2020-11-09 19:51:15', 0),
(21, 'o-236', 1, 'ASSIGNED', 1, '2020-12-14 19:48:21', '2020-11-12 13:36:28', '2020-11-15 17:08:44', NULL, NULL, '2020-11-14 09:23:44', '2020-11-09 19:51:28', 0),
(22, 'o-240', 1, 'ASSIGNED', 1, '2020-12-24 19:48:21', '2020-11-12 16:06:54', '2020-11-19 05:33:00', NULL, NULL, '2020-11-14 09:18:00', '2020-11-09 19:51:54', 0),
(23, 'o-247', 1, 'ASSIGNED', 1, '2020-12-05 19:48:21', '2020-11-12 18:37:08', '2020-11-17 05:03:00', NULL, NULL, '2020-11-14 09:18:00', '2020-11-09 19:52:08', 0),
(24, 'o-244', 1, 'ASSIGNED', 1, '2020-11-27 19:48:21', '2020-11-12 21:07:32', '2020-11-17 18:32:59', NULL, NULL, '2020-11-14 09:17:59', '2020-11-09 19:52:32', 0),
(25, 'o-250', 1, 'ASSIGNED', 1, '2020-12-23 19:48:21', '2020-11-12 23:38:23', '2020-11-18 16:03:00', NULL, NULL, '2020-11-14 09:18:00', '2020-11-09 19:53:23', 0),
(26, 'o-237', 1, 'ASSIGNED', 1, '2020-12-04 19:48:21', '2020-11-13 02:10:14', '2020-11-17 23:32:59', NULL, NULL, '2020-11-14 09:17:59', '2020-11-09 19:55:14', 0),
(27, 'o-239', 1, 'ASSIGNED', 1, '2020-11-22 19:48:21', '2020-11-13 12:09:47', '2020-11-18 02:02:58', NULL, NULL, '2020-11-14 09:17:58', '2020-11-10 03:24:47', 0),
(28, 'o-235', 1, 'ASSIGNED', 1, '2020-12-03 19:48:21', '2020-11-13 19:56:28', '2020-11-18 04:32:59', NULL, NULL, '2020-11-14 09:17:59', '2020-11-10 08:41:28', 0),
(29, 'o-249', 1, 'ASSIGNED', 1, '2020-12-05 19:48:21', '2020-11-13 22:26:46', '2020-11-18 07:03:00', NULL, NULL, '2020-11-14 09:18:00', '2020-11-10 08:41:46', 0),
(30, 'o-246', 1, 'ASSIGNED', 1, '2020-11-23 19:48:21', '2020-11-14 00:57:00', '2020-11-15 20:47:58', NULL, NULL, '2020-11-14 09:17:58', '2020-11-10 08:42:00', 0),
(31, 'o-254', 1, 'ASSIGNED', 1, '2020-12-22 19:48:21', '2020-11-14 03:27:21', '2020-11-18 09:33:00', NULL, NULL, '2020-11-14 09:18:00', '2020-11-10 08:42:21', 0),
(32, 'o-258', 1, 'ASSIGNED', 1, '2020-11-29 19:48:21', '2020-11-14 05:57:44', '2020-11-18 12:02:59', NULL, NULL, '2020-11-14 09:17:59', '2020-11-10 08:42:43', 0),
(33, 'o-226', 1, 'ASSIGNED', 1, '2020-11-29 19:48:21', '2020-11-17 05:23:25', '2020-11-18 14:32:59', NULL, NULL, '2020-11-14 09:17:59', '2020-11-13 08:38:25', 0),
(34, 'o-259', 1, 'ASSIGNED', 1, '2020-11-21 19:48:21', '2020-11-17 08:01:18', '2020-11-15 22:25:19', NULL, NULL, '2020-11-14 09:25:19', '2020-11-13 08:46:18', 0),
(35, 'o-261', 1, 'ASSIGNED', 1, '2020-12-18 19:48:21', '2020-11-17 10:31:46', '2020-11-18 17:03:00', NULL, NULL, '2020-11-14 09:18:00', '2020-11-13 08:46:45', 0),
(36, 'o-273', 1, 'ASSIGNED', 1, '2020-11-21 19:48:21', '2020-11-17 15:43:59', '2020-11-16 02:10:59', NULL, NULL, '2020-11-14 13:55:59', '2020-11-13 10:43:59', 0),
(37, 'o-282', 1, 'ASSIGNED', 1, '2020-11-21 19:48:21', '2020-11-17 18:14:22', '2020-11-18 19:32:58', NULL, NULL, '2020-11-14 09:17:58', '2020-11-13 10:44:22', 0),
(38, 'o-252', 1, 'ASSIGNED', 1, '2020-11-23 19:48:21', '2020-11-17 20:48:52', '2020-11-18 22:02:59', NULL, NULL, '2020-11-14 09:17:59', '2020-11-13 10:48:52', 0),
(39, 'o-241', 1, 'ASSIGNED', 1, '2020-11-24 19:48:21', '2020-11-17 21:04:18', '2020-11-19 00:32:59', NULL, NULL, '2020-11-14 09:17:59', '2020-11-13 11:19:18', 0),
(40, 'o-266', 1, 'ASSIGNED', 1, '2020-11-24 19:48:21', '2020-11-17 23:34:18', '2020-11-19 03:02:59', NULL, NULL, '2020-11-14 09:17:59', '2020-11-13 11:19:18', 0),
(41, 'o-232', 1, 'ASSIGNED', 1, '2020-11-24 19:48:21', '2020-11-19 09:58:39', '2020-11-19 09:58:39', NULL, NULL, '2020-11-14 13:43:39', '2020-11-14 13:43:39', 0);

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
  `to_wc` bigint(20) UNSIGNED DEFAULT NULL,
  `description` varchar(250) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `roads`
--

INSERT INTO `roads` (`id`, `client_id`, `name`, `from_wc`, `to_wc`, `description`) VALUES
(1, 1, 'road1', 1, 4, NULL),
(2, 1, 'road3', 4, 3, NULL),
(5, 1, 'road4', 5, 3, NULL),
(6, 1, 'road7', 3, 2, NULL);

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
  `name` varchar(50) NOT NULL,
  `description` varchar(250) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `workcenters`
--

INSERT INTO `workcenters` (`id`, `client_id`, `name`, `description`) VALUES
(1, 1, 'wc1_1', NULL),
(2, 1, 'wc2_4', NULL),
(3, 1, 'wc2_3', NULL),
(4, 1, 'wc1_3', NULL),
(5, 1, 'wc2_1', NULL);

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
  ADD UNIQUE KEY `client_id_2` (`client_id`,`number`),
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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq ID', AUTO_INCREMENT=109;
--
-- AUTO_INCREMENT for table `clients`
--
ALTER TABLE `clients`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq id', AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq id', AUTO_INCREMENT=46;
--
-- AUTO_INCREMENT for table `messages_read`
--
ALTER TABLE `messages_read`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;
--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;
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
