-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Apr 24, 2021 at 04:17 PM
-- Server version: 10.5.8-MariaDB
-- PHP Version: 7.4.15

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
CREATE DATABASE IF NOT EXISTS `nppc_ex2` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `nppc_ex2`;

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `addMessage`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `addMessage` (IN `_factory` VARCHAR(50), IN `_message_from` VARCHAR(50), IN `_message_type` VARCHAR(9), IN `_body` VARCHAR(250), IN `_tags` VARCHAR(1024), IN `_thread_id` BIGINT UNSIGNED)  MODIFIES SQL DATA
    SQL SECURITY INVOKER
    COMMENT 'adds new Message'
BEGIN
set @client_id = getClientID(`_factory`);
set @from = getUserID(@client_id, `_message_from`);
INSERT INTO `messages`
(`client_id`, `message_from`, `message_type`, `body`, `tags`, thread_id) 
VALUES (@client_id, @from, `_message_type`, `_body`, `_tags`, `_thread_id`);
set @m_id = (SELECT LAST_INSERT_ID());
select * from `messages` where `messages`.`id` = @m_id;
end$$

DROP PROCEDURE IF EXISTS `assignRouteToOrder`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `assignRouteToOrder` (IN `_client_id` BIGINT UNSIGNED, IN `_order` VARCHAR(50), IN `_route` INT)  MODIFIES SQL DATA
    SQL SECURITY INVOKER
    COMMENT 'sets route to added order'
update routes set route=`_route` where `client_id` = `_client_id` and number like `_order`$$

DROP PROCEDURE IF EXISTS `assignWorkcenterToRoutePart`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `assignWorkcenterToRoutePart` (IN `_factory` VARCHAR(50), IN `_order_id` BIGINT UNSIGNED, IN `_order_part` VARCHAR(4096), IN `_operation` VARCHAR(250), IN `_wc` VARCHAR(50), IN `_bucket` VARCHAR(10), IN `_consumption_plan` DOUBLE)  MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
set @client_id = getClientID(`_factory`);
set @priority = (select `orders`.`priority` from `orders` where `orders`.`id` = `_order_id`);
insert into assigns  (client_id, order_id, order_part, operation, workcenter_id, bucket, fullset, consumption_plan, priority) VALUES(@client_id, `_order_id`, `_order_part`, `_operation`, getWorkcenterID(@client_id, `_wc`), `_bucket`, 1, `_consumption_plan`, @priority);
END$$

DROP PROCEDURE IF EXISTS `deleteOrder`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `deleteOrder` (IN `_client_id` BIGINT UNSIGNED, IN `_order` VARCHAR(50))  MODIFIES SQL DATA
    SQL SECURITY INVOKER
begin
set @orid = (select id from orders where client_id=`_client_id` and number like `_order`);
delete from assigns where client_id=`_client_id` and order_id = @orid;
delete from orders where client_id=`_client_id` and number like `_order`;

end$$

DROP PROCEDURE IF EXISTS `flagMessage`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `flagMessage` (IN `_id` BIGINT UNSIGNED, IN `_flag` BOOLEAN)  MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
update `messages`
set `messages`.`flagged` = `_flag`
where `messages`.`id` = `_id`;
END$$

DROP PROCEDURE IF EXISTS `getAllTags`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getAllTags` ()  MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
-- SELECT GROUP_CONCAT(`tags` SEPARATOR ';') AS data FROM `messages`;
drop TEMPORARY table if EXISTS temp;
CREATE TEMPORARY TABLE temp ( `tag` CHAR(255));
SET @S1 = CONCAT("INSERT INTO temp (`tag`) VALUES ('",REPLACE((SELECT GROUP_CONCAT(  `tags` SEPARATOR ';') AS data FROM `messages`), ";", "'),('"),"');");
-- select @S1;
PREPARE stmt1 FROM @s1;
EXECUTE stmt1;
SELECT `tag`, count(`tag`) as c FROM `temp` group by `tag` order by c desc;
END$$

DROP PROCEDURE IF EXISTS `getAssignInfo`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getAssignInfo` (IN `_assign_id` INT UNSIGNED)  READS SQL DATA
    SQL SECURITY INVOKER
SELECT assigns.order_part, assigns.next_order_part, orders.number, orders.current_route  FROM `assigns` 
left join orders on orders.id = assigns.order_id
WHERE assigns.id = `_assign_id`$$

DROP PROCEDURE IF EXISTS `getAssignsByRoads`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getAssignsByRoads` (IN `_factory` VARCHAR(50), IN `_wc_from` VARCHAR(50), IN `_wc_to` VARCHAR(50))  READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
set @client_id = getClientID(`_factory`);
SELECT assigns.*, orders.number, orders.state, orders.estimated, orders.deadline, orders.baseline FROM assigns 
left join orders on orders.id=assigns.order_id
WHERE bucket like  'OUTCOME' and getWorkcenterID(@client_id, `_wc_from`) = workcenter_id and getWorkcenterID(@client_id, `_wc_to`) = next_workcenter_id order by orders.priority desc, orders.deadline asc;
end$$

DROP PROCEDURE IF EXISTS `getAssignsByWorkcenter`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getAssignsByWorkcenter` (IN `_factory` VARCHAR(50), IN `_wc` VARCHAR(50), IN `_buckets` VARCHAR(250))  READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
set @client_id = getClientID(`_factory`);
set @wc_id = getWorkcenterID(@client_id, `_wc`);
call getAssignsByWorkcenterID(@client_id, @wc_id, `_buckets`);
end$$

DROP PROCEDURE IF EXISTS `getAssignsByWorkcenterID`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getAssignsByWorkcenterID` (IN `_client_id` BIGINT UNSIGNED, IN `_workcenter_id` BIGINT UNSIGNED, IN `_buckets` VARCHAR(250))  READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
select a.*, orders.number, orders.state, orders.estimated, orders.deadline, orders.baseline from (select id, order_id, bucket, order_part, event_time, fullset from assigns where client_id = `_client_id` and workcenter_id = `_workcenter_id` and find_in_set(bucket, `_buckets`) > 0 order by assigns.priority desc, assigns.id asc) as a left join orders on orders.id = a.order_id order by orders.priority desc, orders.deadline asc;
end$$

DROP PROCEDURE IF EXISTS `getAssignsCount`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getAssignsCount` (IN `_client_id` BIGINT UNSIGNED, IN `_buckets` VARCHAR(250))  READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
select workcenters.name, b.* from (select workcenter_id, operation, count(id) as assings_count from assigns as a where client_id = `_client_id` and find_in_set(bucket, `_buckets`) > 0 group by a.workcenter_id, a.operation) as b left join workcenters on workcenters.id = b.workcenter_id;
end$$

DROP PROCEDURE IF EXISTS `getMessages`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getMessages` (IN `_factory` VARCHAR(50), IN `_user` VARCHAR(50), IN `_tags` VARCHAR(250), IN `_types` VARCHAR(50))  READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
set @client_id = getClientID(`_factory`);
set @user_id = getUserID(@client_id, `_user`);
if `_types` = '' THEN
	set `_types` = (select GROUP_CONCAT(`message_types`.`message_type`) from `message_types`);
end if; 
select `messages`.`id`, `messages`.`message_time`
, `users`.`name` as `from`, `messages`.`message_type`
, `messages`.`body`, `messages`.`tags`, `messages`.`thread_id`, `messages`.`flagged`
, `messages_read`.`read_time`
from `messages`
left join `messages_read` on `messages`.`id` = `messages_read`.`message_id`
left join `users` on `users`.`id`=`messages`.`message_from`
where  
(`messages`.`client_id` = @client_id
-- and (`messages_read`.`user_id` = @user_id or `messages_read`.`user_id` is null)
and find_in_set(`messages`.`message_type`, `_types`) > 0
and MATCH(`messages`.`tags`) against (concat('+("@', `_user`, '"', `_tags`, ')')IN BOOLEAN MODE))
-- and if (`messages_read`.`read_time` is not null or `_read`, 1, 0) = `_read`
or `messages`.`message_from` = @user_id
order by `messages`.`message_time` DESC
;

end$$

DROP PROCEDURE IF EXISTS `getOrder`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getOrder` (IN `_factory` VARCHAR(50), IN `_order_num` VARCHAR(50))  READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
set @client_id = getClientID(`_factory`);
select * from orders where client_id = @client_id and number like `_order_num`;

END$$

DROP PROCEDURE IF EXISTS `getOrderHistory`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getOrderHistory` (IN `_order_id` BIGINT UNSIGNED)  READS SQL DATA
    SQL SECURITY INVOKER
select assigns.*, workcenters.name as workcenter_name, workcenters.description as workcenter_desc, roads.id as road_id, roads.name as road_name, roads.description as road_desc
from assigns
left join workcenters on workcenters.id=assigns.workcenter_id
left join roads on roads.from_wc = assigns.workcenter_id and roads.to_wc = assigns.next_workcenter_id 
where assigns.order_id = `_order_id`
order by assigns.event_time desc, assigns.id desc$$

DROP PROCEDURE IF EXISTS `getOrderInfo`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getOrderInfo` (IN `_client_id` BIGINT UNSIGNED, IN `_order_num` VARCHAR(50))  READS SQL DATA
    SQL SECURITY INVOKER
select * from orders where client_id = `_client_id` and number like `_order_num`$$

DROP PROCEDURE IF EXISTS `getOrders`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getOrders` (IN `_client_id` BIGINT UNSIGNED ZEROFILL)  READS SQL DATA
    SQL SECURITY INVOKER
select * from orders where client_id = `_client_id` order by orders.priority desc, orders.deadline asc$$

DROP PROCEDURE IF EXISTS `getOutcomeRoad`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getOutcomeRoad` (IN `_assign_id` BIGINT UNSIGNED)  READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
DECLARE CUSTOM_EXCEPTION CONDITION FOR SQLSTATE '45000';
select `assigns`.`workcenter_id`, `assigns`.`next_workcenter_id`
INTO @from_wc_id, @to_wc_id
from `assigns`
where `assigns`.`id` = `_assign_id`;
if @from_wc_id is null OR @to_wc_id is null THEN
	SIGNAL CUSTOM_EXCEPTION
    SET MESSAGE_TEXT = 'Assign has no OUTCOME road';
end if;

select * 
from `roads`
where `roads`.`from_wc`= @from_wc_id and @to_wc_id;
END$$

DROP PROCEDURE IF EXISTS `getRoadByAssignID`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getRoadByAssignID` (IN `_assign_id` BIGINT UNSIGNED)  NO SQL
    SQL SECURITY INVOKER
BEGIN
select `assigns`.`workcenter_id`, `assigns`.`next_workcenter_id` into @wc, @nwc from `assigns` where `assigns`.`id`=`_assign_id`;
select * 
from `roads`
where `roads`.`from_wc`=@wc and `roads`.`to_wc`=@nwc;
END$$

DROP PROCEDURE IF EXISTS `getRoadsWorkload`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getRoadsWorkload` (IN `_factory` VARCHAR(50))  READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
set @client_id = getClientID(`_factory`);
select `roads`.`name`, count(`assigns`.id) as delivery_count
from `roads`
left join `workcenters` on `workcenters`.`id`=`roads`.`from_wc`
left JOIN `assigns` on `assigns`.`workcenter_id`=`workcenters`.`id`
where `roads`.`client_id`=@client_id and find_in_set(`assigns`.`bucket`, 'OUTCOME')
group by `roads`.`id`;
END$$

DROP PROCEDURE IF EXISTS `getUser`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getUser` (IN `_factory` VARCHAR(50), IN `_user` VARCHAR(50), IN `_hash` VARCHAR(36))  READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
set @client_id = getClientID(`_factory`);
if (`_hash` IS NOT NULL) THEN
set @hash = (select `users`.`hash` from `users` where  `users`.`client_id` = @client_id and `users`.`name` like `_user`);
if (@hash IS NULL) THEN
	update `users` set `users`.`hash`=`_hash` WHERE `users`.`client_id` = @client_id and `users`.`name` like `_user`;
end if;
end if;
select * from `users` WHERE `users`.`client_id` = @client_id and `users`.`name` like `_user`;
END$$

DROP PROCEDURE IF EXISTS `getUsersList`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getUsersList` (IN `_factory` VARCHAR(50))  READS SQL DATA
    SQL SECURITY INVOKER
select * 
from `users`$$

DROP PROCEDURE IF EXISTS `getWorkcenterByAssignID`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getWorkcenterByAssignID` (IN `_assign_id` BIGINT UNSIGNED)  NO SQL
    SQL SECURITY INVOKER
BEGIN
set @wc_id = (select `assigns`.`workcenter_id` from `assigns` where `assigns`.`id` = `_assign_id`);
select `workcenters`.*
from `workcenters`
where `workcenters`.`id` = @wc_id;
END$$

DROP PROCEDURE IF EXISTS `getWorkcentersWorkload`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `getWorkcentersWorkload` (IN `_factory` VARCHAR(50))  READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
set @client_id = getClientID(`_factory`);
select `workcenters`.`name`, `workcenters`.`description`, `assigns`.`operation`
 , count(`assigns`.`id`) as `operation_count`
from `workcenters`
left JOIN `assigns` on `assigns`.`workcenter_id`=`workcenters`.`id`
where `workcenters`.`client_id`=@client_id and find_in_set(`assigns`.`bucket`, 'INCOME,PROCESSING')
 group by `workcenters`.`id`, `assigns`.`operation`;
END$$

DROP PROCEDURE IF EXISTS `incOrderPriority`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `incOrderPriority` (IN `_order_id` BIGINT UNSIGNED, IN `_delta` INT)  NO SQL
BEGIN
update `orders` set `orders`.`priority` = `orders`.`priority` + `_delta`
where `orders`.`id` = `_order_id`;
update `assigns` set `assigns`.`priority` = `assigns`.`priority` + `_delta`
where `assigns`.`order_id` = `_order_id` and `assigns`.`bucket` is NOT null;
END$$

DROP PROCEDURE IF EXISTS `makeMessageRead`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `makeMessageRead` (IN `_message_id` BIGINT UNSIGNED, IN `_user` VARCHAR(50))  MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
DECLARE CUSTOM_EXCEPTION CONDITION FOR SQLSTATE '45000';
set @client_id = (select `messages`.`client_id` from `messages` where `messages`.`id`= `_message_id`);
if @client_id is null THEN
	SIGNAL CUSTOM_EXCEPTION
    SET MESSAGE_TEXT = 'Message id is wrong!';
end if;
set @user_id = getUserID(@client_id, `_user`);

set @mread = (select `messages_read`.`id` from `messages_read` where `messages_read`.`message_id`=`_message_id` and `messages_read`.`user_id` = @user_id);
IF @mread is null THEN
	insert into `messages_read` set `messages_read`.`message_id`=`_message_id`, `messages_read`.`user_id` = @user_id;
end if;
select `messages`.`id`, `messages`.`message_time`
, `users`.`name` as `from`, `messages`.`message_type`
, `messages`.`body`, `messages`.`tags`, `messages`.`thread_id`
, `messages_read`.`read_time`
from `messages`
left join `messages_read` on `messages`.`id` = `messages_read`.`message_id`
left join `users` on `users`.`id`=`messages`.`message_from`
where `messages`.`id` = `_message_id`;
END$$

DROP PROCEDURE IF EXISTS `moveAssignToNextBucket`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `moveAssignToNextBucket` (IN `_id` BIGINT UNSIGNED)  MODIFIES SQL DATA
    SQL SECURITY INVOKER
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
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `moveAssignToNextWorkcenter` (IN `_assign_id` BIGINT UNSIGNED, IN `_set_count` INT)  MODIFIES SQL DATA
    SQL SECURITY INVOKER
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

DROP PROCEDURE IF EXISTS `saveUser`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `saveUser` (IN `_id` BIGINT UNSIGNED, IN `_factory` VARCHAR(50), IN `_name` VARCHAR(50), IN `_ban` BOOLEAN, IN `_roles` VARCHAR(2048), IN `_subscriptions` VARCHAR(4096))  NO SQL
    SQL SECURITY INVOKER
BEGIN
set @id =`_id`;
if (`_id` IS NOT NULL) THEN
update `users` 
set `users`.`ban` = IFNULL(`_ban`, `users`.`ban`) 
, `users`.`roles` = IFNULL(`_roles`, `users`.`roles`)
, `users`.`subscriptions` = IFNULL(`_subscriptions`, `users`.`subscriptions`)
where `users`.`id`=`_id`;
ELSE
set @client_id = getClientID(`_factory`);
insert into `users` (`client_id`, `name`, `roles`, `subscriptions`) values(@client_id, `_name`, IFNULL(`_roles`,''), IFNULL(`_subscriptions`,'') );
set @id = LAST_INSERT_ID();
end IF;
select * from `users` where `users`.`id`=@id;
END$$

DROP PROCEDURE IF EXISTS `updateAssignOrderPart`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `updateAssignOrderPart` (IN `_id` BIGINT UNSIGNED, IN `_new_order_part` VARCHAR(250), IN `_next_wc` VARCHAR(50), IN `_next_order_part` VARCHAR(4096), IN `_next_operation` VARCHAR(250), IN `_next_consumption` DOUBLE)  MODIFIES SQL DATA
    SQL SECURITY INVOKER
update assigns set order_part = `_new_order_part`, next_workcenter_id = getWorkcenterID(assigns.client_id, `_next_wc`), next_order_part = `_next_order_part`, next_operation = `_next_operation`, next_consumption= `_next_consumption` where id=`_id`$$

DROP PROCEDURE IF EXISTS `updateBaseline`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `updateBaseline` (IN `_order_id` BIGINT UNSIGNED, IN `_time` DATETIME)  MODIFIES SQL DATA
    SQL SECURITY INVOKER
update orders set baseline=`_time`, estimated=`_time` where id = `_order_id`$$

DROP PROCEDURE IF EXISTS `updateEstimatedTime`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `updateEstimatedTime` (IN `_order_id` BIGINT UNSIGNED, IN `_time` DATETIME)  MODIFIES SQL DATA
    SQL SECURITY INVOKER
update orders set estimated=`_time` where id = `_order_id`$$

DROP PROCEDURE IF EXISTS `updateRoadDesc`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `updateRoadDesc` (IN `_client_id` BIGINT UNSIGNED, IN `_road_name` VARCHAR(50), IN `_desc` VARCHAR(250))  MODIFIES SQL DATA
    SQL SECURITY INVOKER
update roads set `description`=`_desc` where client_id=`_client_id` and `name` like `_road_name`$$

DROP PROCEDURE IF EXISTS `updateSubscriptions`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `updateSubscriptions` (IN `_factory` VARCHAR(50), IN `_user` VARCHAR(50), IN `_tags` VARCHAR(2048))  MODIFIES SQL DATA
    SQL SECURITY INVOKER
update `users`
set `users`.`subscriptions`=`_tags`
WHERE `users`.`client_id` = getClientID(`_factory`) and `users`.`name` like `_user`$$

DROP PROCEDURE IF EXISTS `updateWorkcenterDesc`$$
CREATE DEFINER=`nppc`@`localhost` PROCEDURE `updateWorkcenterDesc` (IN `_client_id` BIGINT UNSIGNED, IN `_wc_name` VARCHAR(50), IN `_desc` VARCHAR(250))  MODIFIES SQL DATA
    SQL SECURITY INVOKER
update workcenters set `description`=`_desc` where client_id=`_client_id` and `name` like `_wc_name`$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `addOrder`$$
CREATE DEFINER=`nppc`@`localhost` FUNCTION `addOrder` (`_factory` VARCHAR(50), `_number` VARCHAR(50), `_state` VARCHAR(10), `_route_id` INT, `_deadline` DATETIME) RETURNS BIGINT(20) UNSIGNED MODIFIES SQL DATA
    SQL SECURITY INVOKER
    COMMENT 'adds new order and returns uniq ID of order in database'
begin
set @client_id = getClientID(`_factory`);
insert into orders (number, client_id, state, current_route, deadline) values(`_number`, @client_id, `_state`, `_route_id`, `_deadline`);
return (SELECT LAST_INSERT_ID());
end$$

DROP FUNCTION IF EXISTS `getAssignConsumptionInWorkcenter`$$
CREATE DEFINER=`nppc`@`localhost` FUNCTION `getAssignConsumptionInWorkcenter` (`_assign_id` BIGINT UNSIGNED) RETURNS DOUBLE READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
select workcenter_id, priority into @wc_id, @pr
from assigns where id = `_assign_id`;
set @r = (select sum(consumption_plan) from assigns where id <= `_assign_id` and priority >= @pr and workcenter_id=@wc_id and (bucket LIKE 'INCOME' or bucket like 'PROCESSING'));
return @r;
end$$

DROP FUNCTION IF EXISTS `getBuckets`$$
CREATE DEFINER=`nppc`@`localhost` FUNCTION `getBuckets` (`_widget` INT) RETURNS VARCHAR(1024) CHARSET utf8 READS SQL DATA
    SQL SECURITY INVOKER
return (SELECT GROUP_CONCAT(bucket order by orderby SEPARATOR ',') from workcenter_bucket where showit =`_widget`)$$

DROP FUNCTION IF EXISTS `getClientID`$$
CREATE DEFINER=`nppc`@`localhost` FUNCTION `getClientID` (`_factoryName` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED READS SQL DATA
    SQL SECURITY INVOKER
    COMMENT 'returns client ID by mnemonic name of the factory'
BEGIN
DECLARE CUSTOM_EXCEPTION CONDITION FOR SQLSTATE '45000';
set @client_id = (select id from clients where name like `_factoryName`);
if @client_id is null THEN
	SIGNAL CUSTOM_EXCEPTION
    SET MESSAGE_TEXT = 'Factory name is wrong!';
end if;
return @client_id;
END$$

DROP FUNCTION IF EXISTS `getOrderConsumptionInWorkcenter`$$
CREATE DEFINER=`nppc`@`localhost` FUNCTION `getOrderConsumptionInWorkcenter` (`_order_id` BIGINT UNSIGNED, `_workcenter` VARCHAR(50)) RETURNS DOUBLE READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
select client_id, priority into @client_id, @pr from orders where id=`_order_id`;
set @r = (select sum(consumption_plan) from assigns where workcenter_id = getWorkcenterID(@client_id, `_workcenter`) and (bucket like 'INCOME' or bucket like 'PROCESSING') and priority >= @pr);
RETURN @r;
END$$

DROP FUNCTION IF EXISTS `getUserID`$$
CREATE DEFINER=`nppc`@`localhost` FUNCTION `getUserID` (`_client_id` BIGINT UNSIGNED, `_name` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED READS SQL DATA
    SQL SECURITY INVOKER
    COMMENT 'returns iser''s id by mnemonic id of one'
BEGIN
DECLARE CUSTOM_EXCEPTION CONDITION FOR SQLSTATE '45000';
set @user_id = (select id from users where client_id = `_client_id` and `name` like `_name`);
if @user_id is null THEN
	SIGNAL CUSTOM_EXCEPTION
    SET MESSAGE_TEXT = 'User name is wrong!';
end if;
return @user_id;
END$$

DROP FUNCTION IF EXISTS `getWorkcenterID`$$
CREATE DEFINER=`nppc`@`localhost` FUNCTION `getWorkcenterID` (`_client_id` BIGINT UNSIGNED, `_name` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED READS SQL DATA
    SQL SECURITY INVOKER
    COMMENT 'returns workcenter''s id by mnemonic id of one'
return (select id from workcenters where client_id = `_client_id` and `name` like `_name`)$$

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
  `priority` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `client_id` (`client_id`,`order_id`,`workcenter_id`),
  KEY `order_id` (`order_id`),
  KEY `workcenter_id` (`workcenter_id`),
  KEY `bucket` (`bucket`),
  KEY `operation` (`operation`)
) ENGINE=InnoDB AUTO_INCREMENT=250 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `assigns`
--

INSERT INTO `assigns` (`id`, `client_id`, `order_id`, `workcenter_id`, `bucket`, `order_part`, `operation`, `consumption_plan`, `consumption_fact`, `fullset`, `prodmat`, `next_workcenter_id`, `next_order_part`, `next_operation`, `event_time`, `next_consumption`, `next_id`, `priority`) VALUES
(1, 1, 1, 1, NULL, 'o-212.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-212.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-13 04:59:39', 480, 77, 0),
(2, 1, 1, 5, NULL, 'o-212.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-212.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 04:53:08', 45, 75, 0),
(3, 1, 3, 1, NULL, 'o-213.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-213.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:43:36', 480, 63, 0),
(4, 1, 3, 5, NULL, 'o-213.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-213.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-27 10:47:45', 45, 78, 0),
(5, 1, 4, 1, 'OUTCOME', 'o-214.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-214.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-30 12:16:39', 480, NULL, 0),
(6, 1, 4, 5, 'PROCESSING', 'o-214.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-12 18:43:51', NULL, NULL, 0),
(7, 1, 5, 1, 'INCOME', 'o-215.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 19:40:03', NULL, NULL, 0),
(8, 1, 5, 5, 'OUTCOME', 'o-215.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-215.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-03 18:48:58', 45, NULL, 0),
(9, 1, 6, 1, NULL, 'o-216.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-216.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:46:33', 480, 72, 0),
(10, 1, 6, 5, NULL, 'o-216.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-216.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:44:20', 45, 65, 0),
(11, 1, 7, 1, NULL, 'o-217.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-217.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-31 03:29:40', 480, 166, 0),
(12, 1, 7, 5, NULL, 'o-217.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-217.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 11:46:40', 45, 187, 0),
(13, 1, 8, 1, 'OUTCOME', 'o-218.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-218.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-30 12:16:59', 480, NULL, 0),
(14, 1, 8, 5, 'PROCESSING', 'o-218.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:58:01', NULL, NULL, 0),
(15, 1, 9, 1, 'OUTCOME', 'o-219.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-219.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-30 12:17:04', 480, NULL, 0),
(16, 1, 9, 5, 'OUTCOME', 'o-219.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-219.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 11:37:21', 45, NULL, 0),
(17, 1, 10, 1, 'OUTCOME', 'o-220.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-220.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-26 13:12:40', 480, NULL, 0),
(18, 1, 10, 5, 'OUTCOME', 'o-220.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-220.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 11:39:30', 45, NULL, 0),
(19, 1, 11, 1, NULL, 'o-221.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-221.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-13 04:59:00', 480, 76, 0),
(20, 1, 11, 5, NULL, 'o-221.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-221.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-03 16:52:43', 45, 174, 0),
(21, 1, 12, 1, 'OUTCOME', 'o-222.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-222.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 10:17:13', 480, NULL, 0),
(22, 1, 12, 5, 'PROCESSING', 'o-222.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 20:23:18', NULL, NULL, 0),
(23, 1, 13, 1, NULL, 'o-223.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-223.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 19:00:18', 480, 74, 0),
(24, 1, 13, 5, NULL, 'o-223.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-223.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:59:33', 45, 73, 0),
(25, 1, 14, 1, NULL, 'o-224.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-224.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-12 18:43:38', 480, 64, 0),
(26, 1, 14, 5, NULL, 'o-224.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-224.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:44:23', 45, 66, 0),
(27, 1, 15, 1, NULL, 'o-10.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-10.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-03 07:26:30', 480, 175, 0),
(28, 1, 15, 5, NULL, 'o-10.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-10.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-03 17:44:39', 45, 176, 0),
(29, 1, 16, 1, NULL, 'o-11.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-11.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 09:50:58', 480, 138, 0),
(30, 1, 16, 5, NULL, 'o-11.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-11.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-27 09:35:11', 45, 137, 0),
(31, 1, 17, 1, 'OUTCOME', 'o-12.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-12.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-30 12:16:43', 480, NULL, 0),
(32, 1, 17, 5, 'INCOME', 'o-12.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-09 19:49:16', NULL, NULL, 0),
(33, 1, 18, 1, NULL, 'o-13.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-13.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 09:30:07', 480, 135, 0),
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
(44, 1, 23, 5, NULL, 'o-247.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-247.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 11:48:56', 45, 173, 0),
(45, 1, 24, 1, NULL, 'o-244.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-244.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 09:30:01', 480, 134, 0),
(46, 1, 24, 5, NULL, 'o-244.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-244.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-03 18:48:08', 45, 171, 0),
(47, 1, 25, 1, NULL, 'o-250.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-250.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 11:47:30', 480, 226, 0),
(48, 1, 25, 5, NULL, 'o-250.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-250.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-03 18:48:35', 45, 180, 0),
(49, 1, 26, 1, NULL, 'o-237.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-237.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-28 15:28:23', 480, 143, 0),
(50, 1, 26, 5, NULL, 'o-237.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-237.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 12:15:55', 45, 172, 0),
(51, 1, 27, 1, NULL, 'o-239.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-239.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 09:17:09', 480, 129, 0),
(52, 1, 27, 5, NULL, 'o-239.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-239.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-03 17:43:26', 45, 167, 0),
(53, 1, 28, 1, 'OUTCOME', 'o-235.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-235.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:22:08', 480, NULL, 0),
(54, 1, 28, 5, 'OUTCOME', 'o-235.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-235.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 11:36:39', 45, NULL, 0),
(55, 1, 29, 1, 'OUTCOME', 'o-249.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-249.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 11:57:15', 480, NULL, 0),
(56, 1, 29, 5, 'PROCESSING', 'o-249.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:42:00', NULL, NULL, 0),
(57, 1, 30, 1, NULL, 'o-246.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-246.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-14 09:13:08', 480, 105, 0),
(58, 1, 30, 5, NULL, 'o-246.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-246.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:50:54', 45, 95, 0),
(59, 1, 31, 1, NULL, 'o-254.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-254.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-31 03:29:37', 480, 165, 0),
(60, 1, 31, 5, 'INCOME', 'o-254.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2020-11-10 08:42:21', NULL, NULL, 0),
(61, 1, 32, 1, NULL, 'o-258.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-258.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 17:45:45', 480, 140, 0),
(62, 1, 32, 5, 'OUTCOME', 'o-258.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-258.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 09:03:20', 45, NULL, 0),
(63, 1, 3, 4, NULL, 'o-213.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-213.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 08:23:09', 45, 78, 0),
(64, 1, 14, 4, NULL, 'o-224.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-224.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 04:39:00', 45, 66, 0),
(65, 1, 6, 3, NULL, 'o-216.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-216.1.wheelpair.1', 'qualitycheck', '2020-11-13 08:24:33', 240, 80, 0),
(66, 1, 14, 3, NULL, 'o-224.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-224.1.wheelpair.1', 'qualitycheck', '2020-11-14 09:08:54', 240, 104, 0),
(67, 1, 19, 3, NULL, 'o-225.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-225.1.wheelpair.1', 'qualitycheck', '2021-03-28 16:12:35', 240, 146, 0),
(68, 1, 21, 3, NULL, 'o-236.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-236.1.wheelpair.1', 'qualitycheck', '2021-03-28 16:12:40', 240, 148, 0),
(69, 1, 20, 4, NULL, 'o-230.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-230.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 09:04:49', 45, 88, 0),
(70, 1, 19, 4, NULL, 'o-225.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-225.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 03:26:03', 45, 67, 0),
(71, 1, 23, 4, NULL, 'o-247.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-247.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-31 18:37:53', 45, 173, 0),
(72, 1, 6, 4, NULL, 'o-216.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-216.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 18:47:29', 45, 65, 0),
(73, 1, 13, 3, NULL, 'o-223.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-223.1.wheelpair.1', 'qualitycheck', '2021-03-28 16:12:43', 240, 149, 0),
(74, 1, 13, 4, NULL, 'o-223.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-223.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-12 19:00:32', 45, 73, 0),
(75, 1, 1, 3, NULL, 'o-212.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-212.1.wheelpair.1', 'qualitycheck', '2020-11-13 08:37:36', 240, 81, 0),
(76, 1, 11, 4, NULL, 'o-221.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-221.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-31 18:37:56', 45, 174, 0),
(77, 1, 1, 4, NULL, 'o-212.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-212.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 08:23:57', 45, 75, 0),
(78, 1, 3, 3, NULL, 'o-213.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-213.1.wheelpair.1', 'qualitycheck', '2021-04-03 17:45:17', 240, 178, 0),
(79, 1, 18, 3, 'OUTCOME', 'o-13.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-13.1.wheelpair.1', 'qualitycheck', '2021-04-03 16:51:56', 240, NULL, 0),
(80, 1, 6, 2, 'PROCESSING', 'o-216.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-22 11:39:03', NULL, NULL, -1),
(81, 1, 1, 2, 'PROCESSING', 'o-212.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-22 11:38:30', NULL, NULL, 1),
(82, 1, 33, 1, 'OUTCOME', 'o-226.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-226.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:21:50', 480, NULL, 0),
(83, 1, 33, 5, 'OUTCOME', 'o-226.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-226.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 09:03:22', 45, NULL, 0),
(84, 1, 34, 1, NULL, 'o-259.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-259.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-13 10:53:16', 480, 97, 0),
(85, 1, 34, 5, NULL, 'o-259.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-259.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:53:28', 45, 99, 0),
(86, 1, 35, 1, 'OUTCOME', 'o-261.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-261.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:22:31', 480, NULL, 0),
(87, 1, 35, 5, 'OUTCOME', 'o-261.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-261.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-03 18:48:53', 45, NULL, 0),
(88, 1, 20, 3, NULL, 'o-230.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-230.1.wheelpair.1', 'qualitycheck', '2021-03-28 16:12:38', 240, 147, 0),
(89, 1, 36, 1, NULL, 'o-273.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-273.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2020-11-13 10:53:14', 480, 96, 0),
(90, 1, 36, 5, NULL, 'o-273.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-273.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:53:27', 45, 98, 0),
(91, 1, 37, 1, NULL, 'o-282.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-282.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 09:29:40', 480, 130, 0),
(92, 1, 37, 5, NULL, 'o-282.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-282.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-28 16:11:51', 45, 136, 0),
(93, 1, 38, 1, NULL, 'o-252.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-252.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 09:29:51', 480, 131, 0),
(94, 1, 38, 5, NULL, 'o-252.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-252.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-28 16:12:02', 45, 144, 0),
(95, 1, 30, 3, NULL, 'o-246.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-246.1.wheelpair.1', 'qualitycheck', '2021-04-03 19:03:13', 240, 185, 0),
(96, 1, 36, 4, NULL, 'o-273.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-273.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:54:22', 45, 98, 0),
(97, 1, 34, 4, NULL, 'o-259.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-259.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-13 10:54:18', 45, 99, 0),
(98, 1, 36, 3, NULL, 'o-273.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-273.1.wheelpair.1', 'qualitycheck', '2021-03-28 06:29:45', 240, 142, 0),
(99, 1, 34, 3, NULL, 'o-259.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-259.1.wheelpair.1', 'qualitycheck', '2021-04-03 19:02:59', 240, 182, 0),
(100, 1, 39, 1, NULL, 'o-241.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-241.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 09:29:57', 480, 133, 0),
(101, 1, 39, 5, NULL, 'o-241.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-241.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-03 17:44:04', 45, 145, 0),
(102, 1, 40, 1, NULL, 'o-266.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-266.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 17:45:42', 480, 139, 0),
(103, 1, 40, 5, 'OUTCOME', 'o-266.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-266.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 09:02:59', 45, NULL, 0),
(104, 1, 14, 2, 'PROCESSING', 'o-224.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-26 10:39:49', NULL, NULL, 0),
(105, 1, 30, 4, NULL, 'o-246.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-246.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-14 09:13:38', 45, 95, 0),
(106, 1, 21, 4, NULL, 'o-236.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-236.1.wheelpair.1.1', 'wheelpairassemble', '2020-11-14 09:23:41', 45, 68, 0),
(107, 1, 41, 1, NULL, 'o-232.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-232.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 09:29:54', 480, 132, 0),
(108, 1, 41, 5, NULL, 'o-232.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-232.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-03 17:42:53', 45, 170, 0),
(109, 1, 44, 1, 'INCOME', 'o-14.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:32:20', NULL, NULL, 0),
(110, 1, 44, 5, 'INCOME', 'o-14.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:32:26', NULL, NULL, 0),
(111, 1, 45, 1, 'INCOME', 'o-15.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:36:34', NULL, NULL, 0),
(112, 1, 45, 5, 'INCOME', 'o-15.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:36:34', NULL, NULL, 0),
(113, 1, 46, 1, NULL, 'o-16.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-16.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-22 20:06:55', 480, 234, 1),
(114, 1, 46, 5, 'INCOME', 'o-16.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-22 20:06:02', NULL, NULL, 1),
(115, 1, 47, 1, 'INCOME', 'o-17.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:21', NULL, NULL, 0),
(116, 1, 47, 5, 'INCOME', 'o-17.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:21', NULL, NULL, 0),
(117, 1, 48, 1, 'INCOME', 'o-18.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:54', NULL, NULL, 0),
(118, 1, 48, 5, 'INCOME', 'o-18.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:54', NULL, NULL, 0),
(119, 1, 49, 1, 'INCOME', 'o-19.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:54', NULL, NULL, 0),
(120, 1, 49, 5, 'INCOME', 'o-19.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:54', NULL, NULL, 0),
(121, 1, 50, 1, 'INCOME', 'o-20.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:54', NULL, NULL, 0),
(122, 1, 50, 5, 'INCOME', 'o-20.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:54', NULL, NULL, 0),
(123, 1, 51, 1, 'INCOME', 'o-21.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:54', NULL, NULL, 0),
(124, 1, 51, 5, 'INCOME', 'o-21.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:54', NULL, NULL, 0),
(125, 1, 52, 1, 'INCOME', 'o-22.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:54', NULL, NULL, 0),
(126, 1, 52, 5, 'INCOME', 'o-22.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-18 15:42:54', NULL, NULL, 0),
(127, 1, 53, 1, NULL, 'o-248.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-248.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-27 17:45:48', 480, 141, 0),
(128, 1, 53, 5, NULL, 'o-248.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-248.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 11:46:14', 45, 168, 0),
(129, 1, 27, 4, NULL, 'o-239.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-239.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-31 18:35:24', 45, 167, 0),
(130, 1, 37, 4, NULL, 'o-282.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-282.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-27 09:32:48', 45, 136, 0),
(131, 1, 38, 4, NULL, 'o-252.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-252.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-28 15:30:00', 45, 144, 0),
(132, 1, 41, 4, NULL, 'o-232.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-232.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-31 18:37:44', 45, 170, 0),
(133, 1, 39, 4, NULL, 'o-241.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-241.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-28 15:30:03', 45, 145, 0),
(134, 1, 24, 4, NULL, 'o-244.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-244.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-31 18:37:47', 45, 171, 0),
(135, 1, 18, 4, NULL, 'o-13.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-13.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-27 11:04:28', 45, 79, 0),
(136, 1, 37, 3, NULL, 'o-282.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-282.1.wheelpair.1', 'qualitycheck', '2021-04-03 19:02:57', 240, 181, 0),
(137, 1, 16, 3, 'OUTCOME', 'o-11.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-11.1.wheelpair.1', 'qualitycheck', '2021-03-28 15:29:42', 240, NULL, 0),
(138, 1, 16, 4, NULL, 'o-11.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-11.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-27 09:51:23', 45, 137, 0),
(139, 1, 40, 4, 'INCOME', 'o-266.1.wheelpair.1.1.shaft.1', 'blankprocessing', 480, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-27 17:45:42', NULL, NULL, 0),
(140, 1, 32, 4, 'PROCESSING', 'o-258.1.wheelpair.1.1.shaft.1', 'blankprocessing', 480, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-04 14:16:33', NULL, NULL, 0),
(141, 1, 53, 4, NULL, 'o-248.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-248.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-31 18:36:16', 45, 168, 0),
(142, 1, 36, 2, 'PROCESSING', 'o-273.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-03 19:03:35', NULL, NULL, 0),
(143, 1, 26, 4, NULL, 'o-237.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-237.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-31 18:37:51', 45, 172, 0),
(144, 1, 38, 3, NULL, 'o-252.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-252.1.wheelpair.1', 'qualitycheck', '2021-04-03 19:03:07', 240, 184, 0),
(145, 1, 39, 3, NULL, 'o-241.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-241.1.wheelpair.1', 'qualitycheck', '2021-04-03 19:03:15', 240, 186, 0),
(146, 1, 19, 2, 'INCOME', 'o-225.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-28 16:12:35', NULL, NULL, 0),
(147, 1, 20, 2, 'INCOME', 'o-230.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-28 16:12:38', NULL, NULL, 0),
(148, 1, 21, 2, 'INCOME', 'o-236.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-22 11:40:26', NULL, NULL, 1),
(149, 1, 13, 2, 'INCOME', 'o-223.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-28 16:12:43', NULL, NULL, 0),
(150, 1, 54, 1, 'OUTCOME', 'o-227.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-227.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:22:10', 480, NULL, 0),
(151, 1, 54, 5, 'PROCESSING', 'o-227.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:42:02', NULL, NULL, 0),
(152, 1, 55, 1, 'OUTCOME', 'o-228.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-228.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:23:15', 480, NULL, 0),
(153, 1, 55, 5, 'PROCESSING', 'o-228.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:42:11', NULL, NULL, 0),
(154, 1, 56, 1, 'OUTCOME', 'o-229.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-229.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:22:05', 480, NULL, 0),
(155, 1, 56, 5, 'PROCESSING', 'o-229.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:41:53', NULL, NULL, 0),
(156, 1, 57, 1, NULL, 'o-231.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-231.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-24 16:15:07', 480, 247, 0),
(157, 1, 57, 5, 'OUTCOME', 'o-231.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-231.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 09:03:03', 45, NULL, 0),
(158, 1, 58, 1, 'OUTCOME', 'o-233.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-233.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:23:13', 480, NULL, 0),
(159, 1, 58, 5, 'PROCESSING', 'o-233.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:42:09', NULL, NULL, 0),
(160, 1, 59, 1, NULL, 'o-234.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-234.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-03-31 03:29:35', 480, 164, 0),
(161, 1, 59, 5, NULL, 'o-234.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-234.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-06 04:20:23', 45, 169, 0),
(162, 1, 60, 1, 'OUTCOME', 'o-238.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-238.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:23:17', 480, NULL, 0),
(163, 1, 60, 5, 'PROCESSING', 'o-238.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:42:19', NULL, NULL, 0),
(164, 1, 59, 4, NULL, 'o-234.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-234.1.wheelpair.1.1', 'wheelpairassemble', '2021-03-31 18:36:35', 45, 169, 0),
(165, 1, 31, 4, 'PROCESSING', 'o-254.1.wheelpair.1.1.shaft.1', 'blankprocessing', 480, NULL, 1, NULL, NULL, NULL, NULL, '2021-03-31 18:33:07', NULL, NULL, 0),
(166, 1, 7, 4, NULL, 'o-217.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-217.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-04 17:50:28', 45, 187, 0),
(167, 1, 27, 3, NULL, 'o-239.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-239.1.wheelpair.1', 'qualitycheck', '2021-04-03 19:03:01', 240, 183, 0),
(168, 1, 53, 3, 'PROCESSING', 'o-248.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:49:09', NULL, NULL, 0),
(169, 1, 59, 3, 'OUTCOME', 'o-234.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-234.1.wheelpair.1', 'qualitycheck', '2021-04-06 04:20:33', 240, NULL, 0),
(170, 1, 41, 3, 'OUTCOME', 'o-232.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-232.1.wheelpair.1', 'qualitycheck', '2021-04-03 17:45:29', 240, NULL, 0),
(171, 1, 24, 3, 'OUTCOME', 'o-244.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-244.1.wheelpair.1', 'qualitycheck', '2021-04-03 18:48:24', 240, NULL, 0),
(172, 1, 26, 3, 'PROCESSING', 'o-237.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:39:49', NULL, NULL, 0),
(173, 1, 23, 3, 'PROCESSING', 'o-247.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:49:07', NULL, NULL, 0),
(174, 1, 11, 3, NULL, 'o-221.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-221.1.wheelpair.1', 'qualitycheck', '2021-04-03 17:45:19', 240, 179, 0),
(175, 1, 15, 4, NULL, 'o-10.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-10.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-03 16:51:47', 45, 176, 0),
(176, 1, 15, 3, NULL, 'o-10.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-10.1.wheelpair.1', 'qualitycheck', '2021-04-03 17:45:15', 240, 177, 0),
(177, 1, 15, 2, 'INCOME', 'o-10.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-03 17:45:15', NULL, NULL, 0),
(178, 1, 3, 2, 'INCOME', 'o-213.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-03 17:45:17', NULL, NULL, 0),
(179, 1, 11, 2, 'INCOME', 'o-221.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-03 17:45:19', NULL, NULL, 0),
(180, 1, 25, 3, 'INCOME', 'o-250.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, NULL, NULL, NULL, NULL, NULL, '2021-04-03 18:48:35', NULL, NULL, 0),
(181, 1, 37, 2, 'PROCESSING', 'o-282.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-03 19:03:32', NULL, NULL, 0),
(182, 1, 34, 2, 'PROCESSING', 'o-259.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-03 19:03:34', NULL, NULL, 0),
(183, 1, 27, 2, 'PROCESSING', 'o-239.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-03 19:03:37', NULL, NULL, 0),
(184, 1, 38, 2, 'INCOME', 'o-252.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-03 19:03:07', NULL, NULL, 0),
(185, 1, 30, 2, 'INCOME', 'o-246.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-03 19:03:13', NULL, NULL, 0),
(186, 1, 39, 2, 'INCOME', 'o-241.1.wheelpair.1', 'qualitycheck', 240, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-03 19:03:15', NULL, NULL, 0),
(187, 1, 7, 3, 'OUTCOME', 'o-217.1.wheelpair.1', 'wheelpairassemble', 45, NULL, 1, NULL, 2, 'o-217.1.wheelpair.1', 'qualitycheck', '2021-04-24 13:01:52', 240, NULL, 0),
(188, 1, 61, 1, 'INCOME', 'o-24.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 06:59:47', NULL, NULL, 0),
(189, 1, 61, 5, 'INCOME', 'o-24.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 06:59:47', NULL, NULL, 0),
(190, 1, 62, 1, 'PROCESSING', 'o-23.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 09:23:09', NULL, NULL, 0),
(191, 1, 62, 5, 'INCOME', 'o-23.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 08:14:04', NULL, NULL, 0),
(192, 1, 63, 1, 'OUTCOME', 'o-242.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-242.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:22:11', 480, NULL, 0),
(193, 1, 63, 5, 'PROCESSING', 'o-242.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:42:06', NULL, NULL, 0),
(194, 1, 64, 1, NULL, 'o-243.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-243.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-21 04:20:31', 480, 233, 0),
(195, 1, 64, 5, 'OUTCOME', 'o-243.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-243.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 09:03:01', 45, NULL, 0),
(196, 1, 65, 1, 'PROCESSING', 'o-245.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 09:22:26', NULL, NULL, 0),
(197, 1, 65, 5, 'INCOME', 'o-245.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 08:16:11', NULL, NULL, 0),
(198, 1, 66, 1, 'PROCESSING', 'o-25.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 09:23:05', NULL, NULL, 0),
(199, 1, 66, 5, 'INCOME', 'o-25.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 08:34:09', NULL, NULL, 0),
(200, 1, 67, 1, 'OUTCOME', 'o-251.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-251.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:21:52', 480, NULL, 0),
(201, 1, 67, 5, 'OUTCOME', 'o-251.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-251.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 09:03:24', 45, NULL, 0),
(202, 1, 68, 1, 'OUTCOME', 'o-253.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-253.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:23:19', 480, NULL, 0),
(203, 1, 68, 5, 'PROCESSING', 'o-253.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:42:13', NULL, NULL, 0),
(204, 1, 69, 1, 'OUTCOME', 'o-255.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-255.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:22:06', 480, NULL, 0),
(205, 1, 69, 5, 'PROCESSING', 'o-255.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:41:56', NULL, NULL, 0),
(206, 1, 70, 1, 'PROCESSING', 'o-256.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:24:25', NULL, NULL, 0),
(207, 1, 70, 5, 'INCOME', 'o-256.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 08:46:18', NULL, NULL, 0),
(208, 1, 71, 1, NULL, 'o-257.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-257.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-24 16:15:10', 480, 248, 0),
(209, 1, 71, 5, NULL, 'o-257.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-257.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-24 16:15:27', 45, 249, 0),
(212, 1, 73, 1, 'PROCESSING', 'o-26.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 09:23:07', NULL, NULL, 0),
(213, 1, 73, 5, 'INCOME', 'o-26.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 08:58:19', NULL, NULL, 0),
(214, 1, 74, 1, NULL, 'o-260.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-260.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 15:50:44', 480, 231, 0),
(215, 1, 74, 5, NULL, 'o-260.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-260.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 15:52:48', 45, 232, 0),
(216, 1, 75, 1, 'OUTCOME', 'o-262.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-262.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:04:49', 480, NULL, 0),
(217, 1, 75, 5, 'OUTCOME', 'o-262.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-262.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 09:03:36', 45, NULL, 0),
(218, 1, 76, 1, 'OUTCOME', 'o-263.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-263.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:21:56', 480, NULL, 0),
(219, 1, 76, 5, 'OUTCOME', 'o-263.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-263.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 11:33:29', 45, NULL, 0),
(220, 1, 77, 1, 'OUTCOME', 'o-264.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-264.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:22:29', 480, NULL, 0),
(221, 1, 77, 5, 'INCOME', 'o-264.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 09:17:40', NULL, NULL, 0),
(222, 1, 78, 1, 'PROCESSING', 'o-265.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:31:06', NULL, NULL, 1),
(223, 1, 78, 5, 'INCOME', 'o-265.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-22 11:41:40', NULL, NULL, 1),
(224, 1, 79, 1, 'OUTCOME', 'o-267.1.wheelpair.1.1.shaft.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, 4, 'o-267.1.wheelpair.1.1.shaft.1', 'blankprocessing', '2021-04-07 09:21:58', 480, NULL, 0),
(225, 1, 79, 5, 'OUTCOME', 'o-267.1.wheelpair.1.1.wheel', 'supplywheel', 150, NULL, 1, NULL, 3, 'o-267.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 11:42:23', 45, NULL, 0),
(226, 1, 25, 4, 'INCOME', 'o-250.1.wheelpair.1.1.shaft.1', 'blankprocessing', 480, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 11:47:30', NULL, NULL, 0),
(227, 1, 80, 1, 'INCOME', 'o-268.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 12:18:51', NULL, NULL, 0),
(228, 1, 80, 5, 'INCOME', 'o-268.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 12:18:51', NULL, NULL, 0),
(229, 1, 81, 1, 'INCOME', 'o-269.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 12:18:55', NULL, NULL, 0),
(230, 1, 81, 5, 'INCOME', 'o-269.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 12:18:55', NULL, NULL, 0),
(231, 1, 74, 4, NULL, 'o-260.1.wheelpair.1.1.shaft', 'blankprocessing', 480, NULL, 1, NULL, 3, 'o-260.1.wheelpair.1.1', 'wheelpairassemble', '2021-04-07 15:51:19', 45, 232, 0),
(232, 1, 74, 3, 'PROCESSING', 'o-260.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-07 15:52:59', NULL, NULL, 0),
(233, 1, 64, 4, 'INCOME', 'o-243.1.wheelpair.1.1.shaft.1', 'blankprocessing', 480, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-21 04:20:31', NULL, NULL, 0),
(234, 1, 46, 4, 'INCOME', 'o-16.1.wheelpair.1.1.shaft.1', 'blankprocessing', 480, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-22 20:06:55', NULL, NULL, 1),
(237, 1, 84, 1, 'PROCESSING', 'o-27.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:30:52', NULL, NULL, 0),
(238, 1, 84, 5, 'INCOME', 'o-27.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:29:06', NULL, NULL, 0),
(239, 1, 85, 1, 'INCOME', 'o-270.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:32:16', NULL, NULL, 0),
(240, 1, 85, 5, 'INCOME', 'o-270.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:32:16', NULL, NULL, 0),
(241, 1, 86, 1, 'INCOME', 'o-271.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:33:43', NULL, NULL, 0),
(242, 1, 86, 5, 'INCOME', 'o-271.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:33:43', NULL, NULL, 0),
(243, 1, 87, 1, 'INCOME', 'o-272.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:34:51', NULL, NULL, 0),
(244, 1, 87, 5, 'INCOME', 'o-272.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:34:51', NULL, NULL, 0),
(245, 1, 88, 1, 'INCOME', 'o-274.1.wheelpair.1.1.shaft.1.1.1', 'supplyblankshaft', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:37:07', NULL, NULL, 0),
(246, 1, 88, 5, 'INCOME', 'o-274.1.wheelpair.1.1.wheel.1', 'supplywheel', 150, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 12:37:07', NULL, NULL, 0),
(247, 1, 57, 4, 'INCOME', 'o-231.1.wheelpair.1.1.shaft.1', 'blankprocessing', 480, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 16:15:07', NULL, NULL, 0),
(248, 1, 71, 4, 'PROCESSING', 'o-257.1.wheelpair.1.1.shaft.1', 'blankprocessing', 480, NULL, 1, NULL, NULL, NULL, NULL, '2021-04-24 16:15:41', NULL, NULL, 0),
(249, 1, 71, 3, 'INCOME', 'o-257.1.wheelpair.1.1', 'wheelpairassemble', 45, NULL, NULL, NULL, NULL, NULL, NULL, '2021-04-24 16:15:27', NULL, NULL, 0);

-- --------------------------------------------------------

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
CREATE TABLE IF NOT EXISTS `clients` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Uniq id',
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_index` (`name`)
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
  `message_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `message_from` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'from person',
  `message_type` varchar(10) NOT NULL COMMENT 'INFO, WARNING, CRITICAL',
  `body` varchar(160) NOT NULL,
  `tags` varchar(1024) NOT NULL,
  `thread_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Previous message in thread',
  `flagged` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `from_index` (`message_from`),
  KEY `message_type` (`message_type`),
  KEY `client_id` (`client_id`),
  KEY `thread_id` (`thread_id`)
) ENGINE=InnoDB AUTO_INCREMENT=141 DEFAULT CHARSET=utf8 COMMENT='Messages of users';

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `message_time`, `client_id`, `message_from`, `message_type`, `body`, `tags`, `thread_id`, `flagged`) VALUES
(3, '2021-02-14 08:58:29', 1, 2, 'CRITICAL', 'TEST @\"David Rhuxel\"', '#rr-2223-;@\"David Rhuxel\"', NULL, NULL),
(4, '2021-02-14 10:42:01', 1, 2, 'INFO', 'Заказ #o-23223/222-1 успешно. @Иванов запершай, @\"David Rhuxel\" jdk', '#o-23223/222-1;@Иванов;@\"David Rhuxel\"', NULL, NULL),
(5, '2021-02-14 15:28:19', 1, 1, 'INFO', 'Заказ #o-23223/222-1 успешно. @Иванов запершай, @\"David Rhuxel\" jdk', '#o-23223/222-1;@Иванов;@David Rhuxel', NULL, NULL),
(6, '2021-02-14 20:57:20', 1, 1, 'INFO', 'Заказ #o-23223/222-1 успешно. @Иванов завершай,  asap', '#o-23223/222-1;@Иванов', NULL, NULL),
(7, '2021-02-15 17:59:54', 1, 1, 'INFO', 'Заказ #o-23223/222-1 успешно. @Иванов завершай,  asap', '#o-23223/222-1;@Иванов', NULL, NULL),
(8, '2021-02-15 18:04:03', 1, 1, 'INFO', 'Заказ #o-23223/222-1 успешно. @Иванов завершай,  asap', '#o-23223/222-1;@Иванов', NULL, NULL),
(9, '2021-02-15 19:05:28', 1, 1, 'INFO', 'Заказ #o-23223/222-1 успешно. @Иванов завершай,  asap', '#o-23223/222-1;@Иванов', NULL, NULL),
(10, '2021-02-19 14:13:37', 1, 1, 'INFO', 'test', '', NULL, NULL),
(11, '2021-02-19 14:18:20', 1, 1, 'INFO', 'test', '', NULL, NULL),
(12, '2021-02-19 14:22:02', 1, 1, 'WARNING', 'test', '', NULL, NULL),
(13, '2021-02-19 14:22:34', 1, 1, 'CRITICAL', 'test1', '', NULL, NULL),
(14, '2021-03-26 10:12:31', 1, 1, 'INFO', 'Order #o-282 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-282', NULL, NULL),
(15, '2021-03-26 13:12:40', 1, 1, 'INFO', 'Order #o-220 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-220', NULL, NULL),
(16, '2021-03-26 13:19:34', 1, 1, 'INFO', 'Order #o-241 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-241', NULL, NULL),
(17, '2021-03-26 13:25:48', 1, 1, 'INFO', 'Order #o-10 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-10', NULL, NULL),
(18, '2021-03-26 13:27:50', 1, 1, 'INFO', 'Order #o-232 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-232', NULL, NULL),
(19, '2021-03-26 17:04:20', 1, 1, 'INFO', 'Order #o-239 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-239', NULL, NULL),
(20, '2021-03-26 17:05:20', 1, 1, 'INFO', 'Order #o-248 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-248', NULL, NULL),
(21, '2021-03-26 17:05:43', 1, 1, 'INFO', 'Order #o-217 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-217', NULL, NULL),
(22, '2021-03-26 17:07:15', 1, 1, 'INFO', 'Order #o-237 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-237', NULL, NULL),
(23, '2021-03-27 09:31:07', 1, 1, 'INFO', 'Order #o-232 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-232', NULL, NULL),
(24, '2021-03-27 09:31:10', 1, 1, 'INFO', 'Order #o-241 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-241', NULL, NULL),
(25, '2021-03-27 09:32:01', 1, 1, 'INFO', 'Order #o-247 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-247', NULL, NULL),
(26, '2021-03-27 09:32:04', 1, 1, 'INFO', 'Order #o-282 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-282', NULL, NULL),
(27, '2021-03-27 09:32:25', 1, 1, 'INFO', 'Order #o-266 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-266', NULL, NULL),
(28, '2021-03-27 09:32:27', 1, 1, 'INFO', 'Order #o-258 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-258', NULL, NULL),
(29, '2021-03-27 09:50:51', 1, 1, 'INFO', 'Order #o-11 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-11', NULL, NULL),
(30, '2021-03-27 09:51:15', 1, 1, 'INFO', 'Order #o-11 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-11', NULL, NULL),
(31, '2021-03-27 10:17:13', 1, 1, 'INFO', 'Order #o-222 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-222', NULL, NULL),
(32, '2021-03-27 10:47:36', 1, 1, 'INFO', 'Order #o-213 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-213', NULL, NULL),
(33, '2021-03-27 11:04:16', 1, 1, 'INFO', 'Order #o-13 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-13', NULL, NULL),
(34, '2021-03-27 11:57:15', 1, 1, 'INFO', 'Order #o-249 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-249', NULL, NULL),
(35, '2021-03-27 12:00:38', 1, 1, 'INFO', 'Order #o-273 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-273', NULL, NULL),
(36, '2021-03-27 12:00:42', 1, 1, 'INFO', 'Order #o-230 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-230', NULL, NULL),
(37, '2021-03-27 12:00:44', 1, 1, 'INFO', 'Order #o-236 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-236', NULL, NULL),
(38, '2021-03-27 17:45:24', 1, 1, 'INFO', 'Order #o-244 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-244', NULL, NULL),
(39, '2021-03-28 15:28:12', 1, 1, 'INFO', 'Order #o-252 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-252', NULL, NULL),
(40, '2021-03-28 15:28:47', 1, 1, 'INFO', 'Order #o-282 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-282', NULL, NULL),
(41, '2021-03-28 15:28:50', 1, 1, 'INFO', 'Order #o-239 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-239', NULL, NULL),
(42, '2021-03-28 15:29:20', 1, 1, 'INFO', 'Order #o-252 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-252', NULL, NULL),
(43, '2021-03-28 15:29:22', 1, 1, 'INFO', 'Order #o-241 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-241', NULL, NULL),
(44, '2021-03-28 15:29:42', 1, 1, 'INFO', 'Order #o-11 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-11', NULL, NULL),
(45, '2021-03-28 16:12:19', 1, 1, 'INFO', 'Order #o-213 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-213', NULL, NULL),
(46, '2021-03-28 16:12:21', 1, 1, 'INFO', 'Order #o-223 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-223', NULL, NULL),
(47, '2021-03-30 10:11:00', 1, 1, 'INFO', '@Иванов убирай', '@Иванов', NULL, NULL),
(48, '2021-03-30 10:40:20', 1, 1, 'CRITICAL', '@Иванов, убери', '@Иванов', NULL, NULL),
(49, '2021-03-30 11:56:20', 1, 1, 'INFO', '@\"David Rhuxel\" get it out', '@\"David Rhuxel\"', NULL, NULL),
(50, '2021-03-30 12:10:08', 1, 1, 'INFO', 'Order #o-237 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-237', NULL, NULL),
(51, '2021-03-30 12:16:39', 1, 1, 'INFO', 'Order #o-214 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-214', NULL, NULL),
(52, '2021-03-30 12:16:43', 1, 1, 'INFO', 'Order #o-12 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-12', NULL, NULL),
(53, '2021-03-30 12:16:59', 1, 1, 'INFO', 'Order #o-218 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-218', NULL, NULL),
(54, '2021-03-30 12:17:04', 1, 1, 'INFO', 'Order #o-219 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-219', NULL, NULL),
(55, '2021-03-30 12:17:25', 1, 1, 'INFO', 'Order #o-234 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-234', NULL, NULL),
(56, '2021-03-30 12:17:29', 1, 1, 'INFO', 'Order #o-254 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-254', NULL, NULL),
(57, '2021-03-31 18:35:26', 1, 1, 'INFO', 'Order #o-239 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-239', NULL, NULL),
(58, '2021-03-31 18:36:16', 1, 1, 'INFO', 'Order #o-248 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-248', NULL, NULL),
(59, '2021-03-31 18:36:35', 1, 1, 'INFO', 'Order #o-234 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-234', NULL, NULL),
(60, '2021-04-03 16:51:47', 1, 1, 'INFO', 'Order #o-10 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-10', NULL, NULL),
(61, '2021-04-03 16:51:56', 1, 1, 'INFO', 'Order #o-13 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-13', NULL, NULL),
(62, '2021-04-03 16:51:58', 1, 1, 'INFO', 'Order #o-246 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-246', NULL, NULL),
(63, '2021-04-03 16:52:32', 1, 1, 'INFO', 'Order #o-221 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-221', NULL, NULL),
(64, '2021-04-03 16:52:52', 1, 1, 'INFO', 'Order #o-221 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-221', NULL, NULL),
(65, '2021-04-03 17:41:29', 1, 1, 'INFO', 'Order #o-232 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-232', NULL, NULL),
(66, '2021-04-03 17:44:57', 1, 1, 'INFO', 'Order #o-10 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-10', NULL, NULL),
(67, '2021-04-03 17:45:26', 1, 1, 'INFO', 'Order #o-282 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-282', NULL, NULL),
(68, '2021-04-03 17:45:28', 1, 1, 'INFO', 'Order #o-239 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-239', NULL, NULL),
(69, '2021-04-03 17:45:29', 1, 1, 'INFO', 'Order #o-232 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-232', NULL, NULL),
(70, '2021-04-03 17:45:30', 1, 1, 'INFO', 'Order #o-252 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-252', NULL, NULL),
(71, '2021-04-03 17:45:40', 1, 1, 'INFO', 'Order #o-259 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-259', NULL, NULL),
(72, '2021-04-03 17:45:42', 1, 1, 'INFO', 'Order #o-241 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-241', NULL, NULL),
(73, '2021-04-03 18:47:52', 1, 1, 'INFO', 'Order #o-244 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-244', NULL, NULL),
(74, '2021-04-03 18:48:24', 1, 1, 'INFO', 'Order #o-244 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-244', NULL, NULL),
(75, '2021-04-03 18:48:53', 1, 1, 'INFO', 'Order #o-261 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-261', NULL, NULL),
(76, '2021-04-03 18:48:55', 1, 1, 'INFO', 'Order #o-217 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-217', NULL, NULL),
(77, '2021-04-03 18:48:58', 1, 1, 'INFO', 'Order #o-215 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-215', NULL, NULL),
(78, '2021-04-04 14:18:19', 1, 2, 'INFO', '@\"David Rhuxel\" se1', '@\"David Rhuxel\"', NULL, NULL),
(79, '2021-04-04 14:19:12', 1, 1, 'INFO', '@pavel se2', '@pavel', NULL, NULL),
(80, '2021-04-04 14:20:04', 1, 2, 'INFO', '#223 se3', '#223', NULL, NULL),
(81, '2021-04-04 17:50:28', 1, 2, 'INFO', 'Order #o-217 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-217', NULL, NULL),
(82, '2021-04-04 19:09:22', 1, 1, 'INFO', '@\"David Rhuxel\" se5', '@\"David Rhuxel\"', NULL, NULL),
(83, '2021-04-04 19:10:13', 1, 2, 'INFO', '@\"David Rhuxel\" se6', '@\"David Rhuxel\"', NULL, NULL),
(84, '2021-04-04 19:12:50', 1, 1, 'INFO', '@pavel se7', '@pavel', NULL, NULL),
(85, '2021-04-06 04:20:05', 1, 2, 'INFO', 'Order #o-234 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-234', NULL, NULL),
(86, '2021-04-06 04:20:33', 1, 2, 'INFO', 'Order #o-234 processed \'\' and ready to next workcenter \'wc2_4\'', '#o-234', NULL, NULL),
(87, '2021-04-07 09:00:24', 1, 1, 'WARNING', 'The order #o-262 started. The owner of order is @pavel - urgent', '#o-262;@pavel', NULL, NULL),
(88, '2021-04-07 09:02:59', 1, 2, 'INFO', 'Order #o-266 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-266', NULL, NULL),
(89, '2021-04-07 09:03:01', 1, 2, 'INFO', 'Order #o-243 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-243', NULL, NULL),
(90, '2021-04-07 09:03:03', 1, 2, 'INFO', 'Order #o-231 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-231', NULL, NULL),
(91, '2021-04-07 09:03:08', 1, 2, 'INFO', 'Order #o-257 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-257', NULL, NULL),
(92, '2021-04-07 09:03:20', 1, 2, 'INFO', 'Order #o-258 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-258', NULL, NULL),
(93, '2021-04-07 09:03:22', 1, 2, 'INFO', 'Order #o-226 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-226', NULL, NULL),
(94, '2021-04-07 09:03:24', 1, 2, 'INFO', 'Order #o-251 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-251', NULL, NULL),
(95, '2021-04-07 09:03:36', 1, 2, 'INFO', 'Order #o-262 processed \'\' and ready to next workcenter \'wc2_3\'', '#o-262', NULL, NULL),
(96, '2021-04-07 09:04:49', 1, 1, 'INFO', 'Order #o-262 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-262', NULL, NULL),
(97, '2021-04-07 09:16:00', 1, 1, 'WARNING', 'The order #o-263 started. The owner of order is @pavel - urg', '#o-263;@pavel', NULL, NULL),
(98, '2021-04-07 09:17:40', 1, 1, 'WARNING', 'The order #o-264 started. The owner of order is @pavel - urge', '#o-264;@pavel', NULL, NULL),
(99, '2021-04-07 09:19:13', 1, 1, 'WARNING', 'The order #o-265 started. The owner of order is @pavel - urge', '#o-265;@pavel', NULL, NULL),
(100, '2021-04-07 09:19:45', 1, 1, 'WARNING', 'The order #o-267 started. The owner of order is @pavel - urg', '#o-267;@pavel', NULL, NULL),
(101, '2021-04-07 09:21:46', 1, 2, 'INFO', 'Order #o-243 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-243', NULL, 1),
(102, '2021-04-07 09:21:48', 1, 2, 'INFO', 'Order #o-231 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-231', NULL, NULL),
(103, '2021-04-07 09:21:50', 1, 2, 'INFO', 'Order #o-226 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-226', NULL, NULL),
(104, '2021-04-07 09:21:52', 1, 2, 'INFO', 'Order #o-251 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-251', NULL, NULL),
(105, '2021-04-07 09:21:53', 1, 2, 'INFO', 'Order #o-257 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-257', NULL, NULL),
(106, '2021-04-07 09:21:56', 1, 2, 'INFO', 'Order #o-263 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-263', NULL, NULL),
(107, '2021-04-07 09:21:58', 1, 2, 'INFO', 'Order #o-267 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-267', NULL, NULL),
(108, '2021-04-07 09:22:05', 1, 2, 'INFO', 'Order #o-229 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-229', NULL, NULL),
(109, '2021-04-07 09:22:06', 1, 2, 'INFO', 'Order #o-255 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-255', NULL, NULL),
(110, '2021-04-07 09:22:08', 1, 2, 'INFO', 'Order #o-235 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-235', NULL, NULL),
(111, '2021-04-07 09:22:10', 1, 2, 'INFO', 'Order #o-227 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-227', NULL, NULL),
(112, '2021-04-07 09:22:11', 1, 2, 'INFO', 'Order #o-242 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-242', NULL, NULL),
(113, '2021-04-07 09:22:29', 1, 2, 'INFO', 'Order #o-264 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-264', NULL, NULL),
(114, '2021-04-07 09:22:31', 1, 2, 'INFO', 'Order #o-261 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-261', NULL, NULL),
(115, '2021-04-07 09:23:13', 1, 1, 'INFO', 'Order #o-233 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-233', NULL, NULL),
(116, '2021-04-07 09:23:15', 1, 1, 'INFO', 'Order #o-228 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-228', NULL, NULL),
(117, '2021-04-07 09:23:17', 1, 1, 'INFO', 'Order #o-238 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-238', NULL, NULL),
(118, '2021-04-07 09:23:19', 1, 1, 'INFO', 'Order #o-253 processed \'\' and ready to next workcenter \'wc1_3\'', '#o-253', NULL, NULL),
(119, '2021-04-07 11:36:29', 1, 1, 'INFO', 'Order #o-263 processed \'o-263.1.wheelpair.1.1.wheel\' and ready to next workcenter \'\'', '#o-263', NULL, NULL),
(120, '2021-04-07 11:37:16', 1, 1, 'INFO', 'Order #o-235 processed \'o-235.1.wheelpair.1.1.wheel\' and ready to next workcenter \'W\'', '#o-235', NULL, 1),
(121, '2021-04-07 11:37:21', 1, 1, 'INFO', 'Order #o-219 processed \'o-219.1.wheelpair.1.1.wheel\' and ready to next workcenter \'Wheel pair assembly\'', '#o-219', NULL, NULL),
(122, '2021-04-07 11:39:30', 1, 1, 'INFO', 'Order #o-220 processed \'o-220.1.wheelpair.1.1.wheel\' and ready to next workcenter @\"Wheel pair assembly\"', '#o-220', NULL, NULL),
(123, '2021-04-07 11:42:23', 1, 1, 'INFO', 'Order #o-267 processed \'o-267.1.wheelpair.1.1.wheel\' and ready to @\"Wheel pair assembly\"', '#o-267', NULL, NULL),
(124, '2021-04-07 11:42:25', 1, 1, 'INFO', 'Order #o-248 processed \'o-248.1.wheelpair.1.1.wheel\' and ready to @\"Wheel pair assembly\"', '#o-248', NULL, 1),
(125, '2021-04-07 11:47:16', 1, 2, 'INFO', 'Order #o-250 processed \'o-250.1.wheelpair.1.1.shaft.1.1\' and ready to @\"Blank processing\"', '#o-250', NULL, NULL),
(126, '2021-04-07 11:48:42', 1, 2, 'INFO', 'Order #o-247 processed \'o-247.1.wheelpair.1.1.wheel\' and ready to @\"Wheel pair assembly\"', '#o-247', NULL, NULL),
(127, '2021-04-07 12:15:43', 1, 1, 'INFO', 'Order #o-237 processed \'o-237.1.wheelpair.1.1.wheel\' and ready to @\"Wheel pair assembly\"', '#o-237', NULL, 1),
(128, '2021-04-07 12:18:51', 1, 1, 'WARNING', 'The order #o-268 started. The owner of order is @pavel - ', '#o-268;@pavel', NULL, 1),
(129, '2021-04-07 12:18:55', 1, 1, 'WARNING', 'The order #o-269 started. The owner of order is @pavel - ', '#o-269;@pavel', NULL, 0),
(130, '2021-04-07 15:46:56', 1, 2, 'INFO', '@\"David Rhuxel\" supply #o-260', '@\"David Rhuxel\";#o-260', NULL, 0),
(131, '2021-04-07 15:48:24', 1, 1, 'INFO', 'Order #o-260 processed \'o-260.1.wheelpair.1.1.shaft.1.1\' and ready to @\"Blank processing\"', '#o-260', NULL, 0),
(132, '2021-04-07 15:51:20', 1, 2, 'INFO', 'Order #o-260 processed \'o-260.1.wheelpair.1.1.shaft\' and ready to @\"Wheel pair assembly\"', '#o-260', NULL, NULL),
(133, '2021-04-07 15:51:59', 1, 2, 'INFO', 'Order #o-260 processed \'o-260.1.wheelpair.1.1.wheel\' and ready to @\"Wheel pair assembly\"', '#o-260', NULL, 0),
(134, '2021-04-08 09:10:50', 1, 2, 'INFO', '@\"David Rhuxel\" answer to 129', '@\"David Rhuxel\"', NULL, 0),
(135, '2021-04-08 09:11:35', 1, 1, 'INFO', '@\"pavel\" test passed', '@\"pavel\"', NULL, NULL),
(136, '2021-04-19 08:18:19', 1, 2, 'INFO', '@\"David Rhuxel\" again', '@\"David Rhuxel\"', NULL, 0),
(137, '2021-04-21 10:29:59', 1, 1, 'INFO', '@\"pavel\"  test passed again', '@\"pavel\"', NULL, NULL),
(138, '2021-04-22 20:06:38', 1, 1, 'INFO', 'Order #o-16 processed \'o-16.1.wheelpair.1.1.shaft.1.1\' and ready to @\"Blank processing\"', '#o-16', NULL, NULL),
(139, '2021-04-24 12:29:06', 1, 3, 'WARNING', 'The order #o-27 started. The owner of order is @test - on time 2', '#o-27;@test', NULL, NULL),
(140, '2021-04-24 13:01:52', 1, 3, 'INFO', 'Order #o-217 processed \'o-217.1.wheelpair.1\' and ready to @\"Quality check\"', '#o-217', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `messages_read`
--

DROP TABLE IF EXISTS `messages_read`;
CREATE TABLE IF NOT EXISTS `messages_read` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `message_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `read_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `flagged` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `message_id_2` (`message_id`,`user_id`),
  KEY `message_id` (`message_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8 COMMENT='Info about read events';

--
-- Dumping data for table `messages_read`
--

INSERT INTO `messages_read` (`id`, `message_id`, `user_id`, `read_time`, `flagged`) VALUES
(1, 3, 1, '2021-03-30 14:29:40', NULL),
(2, 4, 1, '2021-03-30 14:29:55', NULL),
(3, 39, 2, '2021-04-04 15:03:44', NULL),
(4, 42, 2, '2021-04-04 15:03:45', NULL),
(5, 70, 2, '2021-04-04 15:03:58', NULL),
(6, 79, 2, '2021-04-04 15:04:43', NULL),
(7, 21, 2, '2021-04-04 17:49:14', NULL),
(8, 27, 2, '2021-04-04 17:49:20', NULL),
(9, 56, 2, '2021-04-04 17:49:23', NULL),
(10, 76, 2, '2021-04-04 17:49:24', NULL),
(11, 78, 1, '2021-04-04 19:00:54', NULL),
(12, 81, 1, '2021-04-04 19:00:57', NULL),
(13, 15, 2, '2021-04-06 04:15:15', NULL),
(14, 84, 2, '2021-04-06 04:15:56', NULL),
(15, 83, 1, '2021-04-07 09:04:18', NULL),
(16, 91, 1, '2021-04-07 11:27:31', NULL),
(17, 95, 1, '2021-04-07 11:40:16', NULL),
(18, 105, 1, '2021-04-07 11:43:29', NULL),
(19, 106, 1, '2021-04-07 11:43:33', NULL),
(20, 87, 2, '2021-04-07 11:43:59', NULL),
(21, 97, 2, '2021-04-07 11:44:05', NULL),
(22, 98, 2, '2021-04-07 11:44:06', NULL),
(23, 99, 2, '2021-04-07 11:44:07', NULL),
(24, 100, 2, '2021-04-07 11:44:11', NULL),
(25, 118, 2, '2021-04-07 11:44:19', NULL),
(26, 122, 2, '2021-04-07 12:32:06', NULL),
(27, 123, 2, '2021-04-07 15:44:45', NULL),
(28, 107, 1, '2021-04-07 15:47:18', NULL),
(29, 113, 1, '2021-04-07 15:47:20', NULL),
(30, 109, 1, '2021-04-07 15:47:21', NULL),
(31, 130, 1, '2021-04-07 15:53:37', NULL),
(32, 132, 1, '2021-04-07 15:53:41', NULL),
(33, 133, 1, '2021-04-07 15:53:44', NULL),
(34, 131, 2, '2021-04-08 07:23:48', NULL),
(35, 128, 2, '2021-04-08 10:38:19', NULL),
(36, 129, 2, '2021-04-08 11:47:34', NULL),
(37, 32, 2, '2021-04-19 06:56:43', NULL),
(38, 45, 2, '2021-04-19 06:56:51', NULL),
(39, 136, 1, '2021-04-21 10:32:23', NULL),
(40, 134, 1, '2021-04-22 11:07:07', NULL);

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
('CRITICAL'),
('INFO'),
('WARNING');

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
  `deadline` datetime DEFAULT NULL,
  `baseline` datetime DEFAULT NULL,
  `estimated` datetime DEFAULT NULL,
  `customer` varchar(50) DEFAULT NULL,
  `comment` varchar(1024) DEFAULT NULL,
  `change_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `import_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `priority` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `client_id_2` (`client_id`,`number`),
  KEY `number` (`number`),
  KEY `client_id` (`client_id`),
  KEY `state` (`state`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `number`, `client_id`, `state`, `current_route`, `deadline`, `baseline`, `estimated`, `customer`, `comment`, `change_time`, `import_time`, `priority`) VALUES
(1, 'o-212', 1, 'ASSIGNED', 1, '2021-03-30 11:16:42', '2021-04-22 19:21:33', '2021-04-25 03:24:43', NULL, NULL, '2021-04-24 12:24:43', '2020-11-09 19:38:46', 1),
(3, 'o-213', 1, 'ASSIGNED', 1, '2021-05-21 11:16:42', '2021-04-26 23:21:33', '2021-04-28 19:24:43', NULL, NULL, '2021-04-24 12:24:43', '2020-11-09 19:39:24', 0),
(4, 'o-214', 1, 'ASSIGNED', 1, '2021-06-08 11:16:42', '2021-05-02 14:36:33', '2021-05-04 16:09:43', NULL, NULL, '2021-04-24 12:24:43', '2020-11-09 19:39:51', 0),
(5, 'o-215', 1, 'ASSIGNED', 1, '2021-05-18 11:16:42', '2021-05-02 04:06:33', '2021-05-04 00:09:43', NULL, NULL, '2021-04-24 12:24:43', '2020-11-09 19:40:03', 0),
(6, 'o-216', 1, 'ASSIGNED', 1, '2021-06-03 11:16:42', '2021-04-25 11:21:33', '2021-04-27 15:24:43', NULL, NULL, '2021-04-24 12:24:43', '2020-11-09 19:40:11', -1),
(7, 'o-217', 1, 'ASSIGNED', 1, '2021-04-01 11:16:42', '2021-04-28 11:06:33', '2021-04-30 07:09:43', NULL, NULL, '2021-04-24 12:24:43', '2020-11-09 19:40:16', 0),
(8, 'o-218', 1, 'ASSIGNED', 1, '2021-04-24 11:16:42', '2021-05-02 14:36:33', '2021-05-04 16:09:43', NULL, NULL, '2021-04-24 12:24:43', '2020-11-09 19:40:21', 0),
(9, 'o-219', 1, 'ASSIGNED', 1, '2021-04-09 11:16:42', '2021-05-02 14:36:33', '2021-05-04 16:09:43', NULL, NULL, '2021-04-24 12:24:43', '2020-11-09 19:40:26', 0),
(10, 'o-220', 1, 'ASSIGNED', 1, '2021-06-23 11:16:42', '2021-05-02 14:36:33', '2021-05-04 16:09:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:40:35', 0),
(11, 'o-221', 1, 'ASSIGNED', 1, '2021-05-17 11:16:42', '2021-04-27 03:21:33', '2021-04-28 23:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:40:39', 0),
(12, 'o-222', 1, 'ASSIGNED', 1, '2021-06-12 11:16:42', '2021-05-02 14:36:33', '2021-05-04 16:09:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:40:45', 0),
(13, 'o-223', 1, 'ASSIGNED', 1, '2021-03-18 11:16:42', '2021-04-26 15:21:33', '2021-04-28 11:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:40:54', 0),
(14, 'o-224', 1, 'ASSIGNED', 1, '2021-06-08 11:16:42', '2021-04-25 19:21:33', '2021-04-27 15:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:41:50', 0),
(15, 'o-10', 1, 'ASSIGNED', 1, '2021-03-21 19:47:03', '2021-04-26 19:21:33', '2021-04-28 15:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:48:39', 0),
(16, 'o-11', 1, 'ASSIGNED', 1, '2021-05-21 19:47:03', '2021-04-25 07:21:33', '2021-04-27 07:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:48:54', 0),
(17, 'o-12', 1, 'ASSIGNED', 1, '2021-03-12 19:47:03', '2021-05-02 14:36:33', '2021-05-04 16:09:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:49:16', 0),
(18, 'o-13', 1, 'ASSIGNED', 1, '2021-03-10 19:47:03', '2021-04-25 07:21:33', '2021-04-27 07:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:49:34', 0),
(19, 'o-225', 1, 'ASSIGNED', 1, '2020-11-27 19:48:21', '2021-04-23 07:21:33', '2021-04-27 23:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:50:56', 0),
(20, 'o-230', 1, 'ASSIGNED', 1, '2020-11-27 19:48:21', '2021-04-26 07:21:33', '2021-04-28 03:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:51:15', 0),
(21, 'o-236', 1, 'ASSIGNED', 1, '2020-12-14 19:48:21', '2021-04-26 11:21:33', '2021-04-25 07:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:51:28', 1),
(22, 'o-240', 1, 'ASSIGNED', 1, '2020-12-24 19:48:21', '2021-05-02 14:36:33', '2021-05-04 16:09:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:51:54', 0),
(23, 'o-247', 1, 'ASSIGNED', 1, '2020-12-05 19:48:21', '2021-04-28 09:36:33', '2021-04-30 05:39:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:52:08', 0),
(24, 'o-244', 1, 'ASSIGNED', 1, '2020-11-27 19:48:21', '2021-04-25 08:06:33', '2021-04-27 08:09:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:52:32', 0),
(25, 'o-250', 1, 'ASSIGNED', 1, '2020-12-23 19:48:21', '2021-04-28 10:21:33', '2021-04-30 06:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:53:23', 0),
(26, 'o-237', 1, 'ASSIGNED', 1, '2020-12-04 19:48:21', '2021-04-28 08:51:33', '2021-04-30 04:54:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-09 19:55:14', 0),
(27, 'o-239', 1, 'ASSIGNED', 1, '2020-11-22 19:48:21', '2021-04-27 15:21:33', '2021-04-29 11:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-10 03:24:47', 0),
(28, 'o-235', 1, 'ASSIGNED', 1, '2020-12-03 19:48:21', '2021-05-02 14:36:33', '2021-05-04 16:09:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-10 08:41:28', 0),
(29, 'o-249', 1, 'ASSIGNED', 1, '2020-12-05 19:48:21', '2021-05-02 14:36:33', '2021-05-04 16:09:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-10 08:41:46', 0),
(30, 'o-246', 1, 'ASSIGNED', 1, '2020-11-23 19:48:21', '2021-04-27 23:21:34', '2021-04-29 19:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-10 08:42:00', 0),
(31, 'o-254', 1, 'ASSIGNED', 1, '2020-12-22 19:48:21', '2021-04-29 12:36:34', '2021-05-01 08:39:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-10 08:42:21', 0),
(32, 'o-258', 1, 'ASSIGNED', 1, '2020-11-29 19:48:21', '2021-05-02 04:06:34', '2021-05-04 00:09:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-10 08:42:43', 0),
(33, 'o-226', 1, 'ASSIGNED', 1, '2020-11-29 19:48:21', '2021-05-02 14:36:34', '2021-05-04 16:09:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-13 08:38:25', 0),
(34, 'o-259', 1, 'ASSIGNED', 1, '2020-11-21 19:48:21', '2021-04-27 11:21:34', '2021-04-29 07:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-13 08:46:18', 0),
(35, 'o-261', 1, 'ASSIGNED', 1, '2020-12-18 19:48:21', '2021-05-02 14:36:34', '2021-05-04 16:09:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-13 08:46:45', 0),
(36, 'o-273', 1, 'ASSIGNED', 1, '2020-11-21 19:48:21', '2021-04-25 23:21:34', '2021-04-27 19:24:44', NULL, NULL, '2021-04-24 12:24:44', '2020-11-13 10:43:59', 0),
(37, 'o-282', 1, 'ASSIGNED', 1, '2020-11-21 19:48:21', '2021-04-27 07:21:34', '2021-04-29 03:24:45', NULL, NULL, '2021-04-24 12:24:45', '2020-11-13 10:44:22', 0),
(38, 'o-252', 1, 'ASSIGNED', 1, '2020-11-23 19:48:21', '2021-04-27 19:21:34', '2021-04-29 15:24:45', NULL, NULL, '2021-04-24 12:24:45', '2020-11-13 10:48:52', 0),
(39, 'o-241', 1, 'ASSIGNED', 1, '2020-11-24 19:48:21', '2021-04-28 03:21:34', '2021-04-29 23:24:45', NULL, NULL, '2021-04-24 12:24:45', '2020-11-13 11:19:18', 0),
(40, 'o-266', 1, 'ASSIGNED', 1, '2020-11-24 19:48:21', '2021-05-02 04:06:34', '2021-05-04 00:09:45', NULL, NULL, '2021-04-24 12:24:45', '2020-11-13 11:19:18', 0),
(41, 'o-232', 1, 'ASSIGNED', 1, '2020-11-24 19:48:21', '2021-04-25 08:06:34', '2021-04-27 08:09:45', NULL, NULL, '2021-04-24 12:24:45', '2020-11-14 13:43:39', 0),
(44, 'o-14', 1, 'ASSIGNED', 1, '2021-03-16 19:47:03', '2021-04-30 17:36:34', '2021-05-02 21:39:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-18 15:32:15', 0),
(45, 'o-15', 1, 'ASSIGNED', 1, '2021-06-08 19:47:03', '2021-04-30 20:06:34', '2021-05-03 00:09:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-18 15:36:34', 0),
(46, 'o-16', 1, 'ASSIGNED', 1, '2021-04-23 19:47:03', '2021-04-30 22:36:34', '2021-04-25 20:09:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-18 15:40:33', 1),
(47, 'o-17', 1, 'ASSIGNED', 1, '2021-03-23 19:47:03', '2021-05-01 01:06:34', '2021-05-03 02:39:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-18 15:42:21', 0),
(48, 'o-18', 1, 'ASSIGNED', 1, '2021-04-08 19:47:03', '2021-05-01 03:36:34', '2021-05-03 05:09:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-18 15:42:54', 0),
(49, 'o-19', 1, 'ASSIGNED', 1, '2021-05-27 19:47:03', '2021-05-01 06:06:34', '2021-05-03 07:39:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-18 15:42:54', 0),
(50, 'o-20', 1, 'ASSIGNED', 1, '2021-03-23 19:47:03', '2021-05-01 08:36:34', '2021-05-03 10:09:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-18 15:42:54', 0),
(51, 'o-21', 1, 'ASSIGNED', 1, '2021-05-17 19:47:03', '2021-05-01 11:06:34', '2021-05-03 12:39:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-18 15:42:54', 0),
(52, 'o-22', 1, 'ASSIGNED', 1, '2021-04-29 19:47:03', '2021-05-01 13:36:34', '2021-05-03 15:09:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-18 15:42:54', 0),
(53, 'o-248', 1, 'ASSIGNED', 1, '2020-12-02 19:48:21', '2021-04-28 08:06:34', '2021-04-30 04:09:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-25 20:08:06', 0),
(54, 'o-227', 1, 'ASSIGNED', 1, '2020-12-05 19:48:21', '2021-05-02 14:36:34', '2021-05-04 16:09:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-30 12:12:37', 0),
(55, 'o-228', 1, 'ASSIGNED', 1, '2020-12-11 19:48:21', '2021-05-02 14:36:34', '2021-05-04 16:09:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-30 12:12:37', 0),
(56, 'o-229', 1, 'ASSIGNED', 1, '2020-12-03 19:48:21', '2021-05-02 14:36:34', '2021-05-04 16:09:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-30 12:12:37', 0),
(57, 'o-231', 1, 'ASSIGNED', 1, '2020-11-26 19:48:21', '2021-05-02 14:36:34', '2021-05-04 16:09:45', NULL, NULL, '2021-04-24 12:24:45', '2021-03-30 12:12:37', 0),
(58, 'o-233', 1, 'ASSIGNED', 1, '2020-12-09 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-03-30 12:12:37', 0),
(59, 'o-234', 1, 'ASSIGNED', 1, '2020-12-04 19:48:21', '2021-04-25 08:06:35', '2021-04-27 08:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-03-30 12:12:37', 0),
(60, 'o-238', 1, 'ASSIGNED', 1, '2020-12-17 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-03-30 12:12:37', 0),
(61, 'o-24', 1, 'ASSIGNED', 1, '2021-06-11 19:47:03', '2021-05-01 16:06:35', '2021-05-03 17:39:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 06:59:47', 0),
(62, 'o-23', 1, 'ASSIGNED', 1, '2021-05-16 19:47:03', '2021-05-01 18:36:35', '2021-05-03 20:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:14:04', 0),
(63, 'o-242', 1, 'ASSIGNED', 1, '2020-12-08 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:14:04', 0),
(64, 'o-243', 1, 'ASSIGNED', 1, '2020-11-25 19:48:21', '2021-05-02 04:06:35', '2021-05-04 00:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:14:04', 0),
(65, 'o-245', 1, 'ASSIGNED', 1, '2020-12-23 19:48:21', '2021-05-01 21:06:35', '2021-05-03 22:39:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:16:11', 0),
(66, 'o-25', 1, 'ASSIGNED', 1, '2021-05-08 19:47:03', '2021-05-01 23:36:35', '2021-05-04 01:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:34:09', 0),
(67, 'o-251', 1, 'ASSIGNED', 1, '2020-11-29 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:38:27', 0),
(68, 'o-253', 1, 'ASSIGNED', 1, '2020-12-12 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:41:02', 0),
(69, 'o-255', 1, 'ASSIGNED', 1, '2020-12-03 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:43:29', 0),
(70, 'o-256', 1, 'ASSIGNED', 1, '2020-12-18 19:48:21', '2021-05-02 02:06:35', '2021-05-04 03:39:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:46:18', 0),
(71, 'o-257', 1, 'ASSIGNED', 1, '2020-11-29 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:46:47', 0),
(73, 'o-26', 1, 'ASSIGNED', 1, '2021-05-14 19:47:03', '2021-05-02 04:36:35', '2021-05-04 06:09:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:58:19', 0),
(74, 'o-260', 1, 'ASSIGNED', 1, '2020-12-13 19:48:21', '2021-04-28 11:51:35', '2021-04-30 07:54:46', NULL, NULL, '2021-04-24 12:24:46', '2021-04-07 08:59:19', 0),
(75, 'o-262', 1, 'ASSIGNED', 1, '2020-12-15 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:47', NULL, NULL, '2021-04-24 12:24:47', '2021-04-07 09:00:20', 0),
(76, 'o-263', 1, 'ASSIGNED', 1, '2020-11-30 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:47', NULL, NULL, '2021-04-24 12:24:47', '2021-04-07 09:16:00', 0),
(77, 'o-264', 1, 'ASSIGNED', 1, '2020-12-18 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:47', NULL, NULL, '2021-04-24 12:24:47', '2021-04-07 09:17:40', 0),
(78, 'o-265', 1, 'ASSIGNED', 1, '2020-12-17 19:48:21', '2021-05-02 07:06:35', '2021-04-26 06:39:47', NULL, NULL, '2021-04-24 12:24:47', '2021-04-07 09:19:13', 1),
(79, 'o-267', 1, 'ASSIGNED', 1, '2020-12-01 19:48:21', '2021-05-02 14:36:35', '2021-05-04 16:09:47', NULL, NULL, '2021-04-24 12:24:47', '2021-04-07 09:19:45', 0),
(80, 'o-268', 1, 'ASSIGNED', 1, '2020-12-18 19:48:21', '2021-05-02 09:36:35', '2021-05-04 11:09:47', NULL, NULL, '2021-04-24 12:24:47', '2021-04-07 12:18:51', 0),
(81, 'o-269', 1, 'ASSIGNED', 1, '2020-12-22 19:48:21', '2021-05-02 12:06:36', '2021-05-04 13:39:47', NULL, NULL, '2021-04-24 12:24:47', '2021-04-07 12:18:55', 0),
(84, 'o-27', 1, 'ASSIGNED', 1, '2021-05-29 19:47:03', '2021-05-04 16:14:06', '2021-05-04 16:14:06', NULL, NULL, '2021-04-24 12:29:06', '2021-04-24 12:29:06', 0),
(85, 'o-270', 1, 'ASSIGNED', 1, '2020-12-23 19:48:21', '2021-05-04 18:47:16', '2021-05-04 18:47:16', NULL, NULL, '2021-04-24 12:32:16', '2021-04-24 12:32:16', 0),
(86, 'o-271', 1, 'ASSIGNED', 1, '2020-12-14 19:48:21', '2021-05-04 21:18:43', '2021-05-04 21:18:43', NULL, NULL, '2021-04-24 12:33:43', '2021-04-24 12:33:43', 0),
(87, 'o-272', 1, 'ASSIGNED', 1, '2020-11-28 19:48:21', '2021-05-04 23:49:51', '2021-05-04 23:49:51', NULL, NULL, '2021-04-24 12:34:51', '2021-04-24 12:34:51', 0),
(88, 'o-274', 1, 'ASSIGNED', 1, '2020-12-14 19:48:21', '2021-05-05 02:22:07', '2021-05-05 02:22:07', NULL, NULL, '2021-04-24 12:37:07', '2021-04-24 12:37:07', 0);

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
  `description` varchar(250) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `from_wc` (`from_wc`),
  KEY `client_id` (`client_id`),
  KEY `to_wc` (`to_wc`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `roads`
--

INSERT INTO `roads` (`id`, `client_id`, `name`, `from_wc`, `to_wc`, `description`) VALUES
(1, 1, 'road1', 1, 4, 'Warehouse crane'),
(2, 1, 'road3', 4, 3, 'Truck 1'),
(5, 1, 'road4', 5, 3, 'Truck 2'),
(6, 1, 'road7', 3, 2, 'QC crane');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL,
  `ban` tinyint(1) DEFAULT NULL,
  `hash` varchar(36) DEFAULT NULL,
  `roles` varchar(2048) NOT NULL,
  `subscriptions` varchar(4096) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`,`client_id`) USING BTREE,
  KEY `client_id` (`client_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COMMENT='users table referenced to factory xml';

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `client_id`, `name`, `ban`, `hash`, `roles`, `subscriptions`) VALUES
(1, 1, 'David Rhuxel', 0, '27f02d4e066a8bbe8c055ec420dad009', 'SUPER_USER', ';#o-25;#o-253;#o-255;#o-256;#o-257;#o-26;#o-260;#o-262;#o-263;#o-264;#o-265;#o-267;#o-268;#o-269'),
(2, 1, 'pavel', 0, '53e6074ce8ba130220b13613bedca72b', 'MOVE_ORDER_WC%wc1_3;USER_MANAGEMENT', '#o-252;#o-253;#o-217;#o-266;#o-254;#o-220;#o-25;#o-251;#o-264;#o-265;#o-267;#o-268;#o-269;#o-260;#o-212;#o-213'),
(3, 1, 'test', 0, '5a105e8b9d40e1329780d62ea2265d8a', 'IMPORT_ORDER;MOVE_ORDER_WC;MOVE_ORDER_ROAD;USER_MANAGEMENT', ';#o-27;#o-270;#o-271;#o-272;#o-274'),
(4, 1, 'test1', 0, NULL, 'MOVE_ORDER_WC%wc1_1', ''),
(5, 1, 'test2', NULL, NULL, '', '');

-- --------------------------------------------------------

--
-- Table structure for table `workcenters`
--

DROP TABLE IF EXISTS `workcenters`;
CREATE TABLE IF NOT EXISTS `workcenters` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL,
  `description` varchar(250) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `client_id` (`client_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `workcenters`
--

INSERT INTO `workcenters` (`id`, `client_id`, `name`, `description`) VALUES
(1, 1, 'wc1_1', 'Supply Blanks'),
(2, 1, 'wc2_4', 'Quality check'),
(3, 1, 'wc2_3', 'Wheelpair assembly'),
(4, 1, 'wc1_3', 'Blank processing'),
(5, 1, 'wc2_1', 'Supply Wheels');

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
ALTER TABLE `messages` ADD FULLTEXT KEY `body` (`body`,`tags`);
ALTER TABLE `messages` ADD FULLTEXT KEY `tags` (`tags`);
ALTER TABLE `messages` ADD FULLTEXT KEY `body_2` (`body`);

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
