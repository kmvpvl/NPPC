-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 31, 2021 at 08:39 PM
-- Server version: 10.4.17-MariaDB
-- PHP Version: 8.0.0

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
CREATE DEFINER=`root`@`localhost` PROCEDURE `addMessage` (IN `_factory` VARCHAR(50), IN `_message_from` VARCHAR(50), IN `_message_type` VARCHAR(9), IN `_body` VARCHAR(250), IN `_tags` VARCHAR(1024), IN `_thread_id` BIGINT UNSIGNED)  NO SQL
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `assignRouteToOrder` (IN `_client_id` BIGINT UNSIGNED, IN `_order` VARCHAR(50), IN `_route` INT)  NO SQL
    COMMENT 'sets route to added order'
update routes set route=`_route` where `client_id` = `_client_id` and number like `_order`$$

DROP PROCEDURE IF EXISTS `assignWorkcenterToRoutePart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `assignWorkcenterToRoutePart` (IN `_factory` VARCHAR(50), IN `_order_id` BIGINT UNSIGNED, IN `_order_part` VARCHAR(4096), IN `_operation` VARCHAR(250), IN `_wc` VARCHAR(50), IN `_bucket` VARCHAR(10), IN `_consumption_plan` DOUBLE)  NO SQL
BEGIN
set @client_id = getClientID(`_factory`);
insert into assigns  (client_id, order_id, order_part, operation, workcenter_id, bucket, fullset, consumption_plan) VALUES(@client_id, `_order_id`, `_order_part`, `_operation`, getWorkcenterID(@client_id, `_wc`), `_bucket`, 1, `_consumption_plan`);
END$$

DROP PROCEDURE IF EXISTS `deleteOrder`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteOrder` (IN `_client_id` BIGINT UNSIGNED, IN `_order` VARCHAR(50))  NO SQL
begin
set @orid = (select id from orders where client_id=`_client_id` and number like `_order`);
delete from assigns where client_id=`_client_id` and order_id = @orid;
delete from orders where client_id=`_client_id` and number like `_order`;

end$$

DROP PROCEDURE IF EXISTS `getAllTags`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllTags` ()  NO SQL
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignInfo` (IN `_assign_id` INT)  NO SQL
SELECT assigns.order_part, assigns.next_order_part, orders.number, orders.current_route  FROM `assigns` 
left join orders on orders.id = assigns.order_id
WHERE assigns.id = `_assign_id`$$

DROP PROCEDURE IF EXISTS `getAssignsByRoads`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignsByRoads` (IN `_factory` VARCHAR(50), IN `_wc_from` VARCHAR(50), IN `_wc_to` VARCHAR(50))  NO SQL
BEGIN
set @client_id = getClientID(`_factory`);
SELECT assigns.*, orders.number, orders.state, orders.estimated, orders.deadline, orders.baseline FROM assigns 
left join orders on orders.id=assigns.order_id
WHERE bucket like  'OUTCOME' and getWorkcenterID(@client_id, `_wc_from`) = workcenter_id and getWorkcenterID(@client_id, `_wc_to`) = next_workcenter_id order by orders.priority desc, orders.deadline asc;
end$$

DROP PROCEDURE IF EXISTS `getAssignsByWorkcenter`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAssignsByWorkcenter` (IN `_factory` VARCHAR(50), IN `_wc` VARCHAR(50), IN `_buckets` VARCHAR(250))  NO SQL
BEGIN
set @client_id = getClientID(`_factory`);
set @wc_id = getWorkcenterID(@client_id, `_wc`);
call getAssignsByWorkcenterID(@client_id, @wc_id, `_buckets`);
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

DROP PROCEDURE IF EXISTS `getMessages`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getMessages` (IN `_factory` VARCHAR(50), IN `_user` VARCHAR(50), IN `_tags` VARCHAR(250), IN `_types` VARCHAR(50))  NO SQL
BEGIN
set @client_id = getClientID(`_factory`);
set @user_id = getUserID(@client_id, `_user`);
if `_types` = '' THEN
	set `_types` = (select GROUP_CONCAT(`message_types`.`message_type`) from `message_types`);
end if; 
select `messages`.`id`, `messages`.`message_time`
, `users`.`name` as `from`, `messages`.`message_type`
, `messages`.`body`, `messages`.`tags`, `messages`.`thread_id`
, `messages_read`.`read_time`
from `messages`
left join `messages_read` on `messages`.`id` = `messages_read`.`message_id`
left join `users` on `users`.`id`=`messages`.`message_from`
where  
(`messages`.`client_id` = @client_id
-- and (`messages_read`.`user_id` = @user_id or `messages_read`.`user_id` is null)
and find_in_set(`messages`.`message_type`, `_types`) > 0)
or MATCH(`messages`.`tags`) against (concat('+("@', `_user`, '"', `_tags`, ')')IN BOOLEAN MODE)
-- and if (`messages_read`.`read_time` is not null or `_read`, 1, 0) = `_read`
-- and `messages`.`message_from` <> @user_id
order by `messages`.`message_time` DESC
;
end$$

DROP PROCEDURE IF EXISTS `getOrder`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrder` (IN `_factory` VARCHAR(50), IN `_order_num` VARCHAR(50))  NO SQL
BEGIN
set @client_id = getClientID(`_factory`);
select * from orders where client_id = @client_id and number like `_order_num`;

END$$

DROP PROCEDURE IF EXISTS `getOrderHistory`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrderHistory` (IN `_order_id` BIGINT UNSIGNED)  NO SQL
select assigns.*, workcenters.name as workcenter_name, workcenters.description as workcenter_desc, roads.id as road_id, roads.name as road_name, roads.description as road_desc
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

DROP PROCEDURE IF EXISTS `getOutcomeRoad`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getOutcomeRoad` (IN `_assign_id` BIGINT UNSIGNED)  NO SQL
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

DROP PROCEDURE IF EXISTS `getRoadsWorkload`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getRoadsWorkload` (IN `_factory` VARCHAR(50))  NO SQL
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `getUser` (IN `_factory` VARCHAR(50), IN `_user` VARCHAR(50))  NO SQL
select * from `users` WHERE `users`.`client_id` = getClientID(`_factory`) and `users`.`name` like `_user`$$

DROP PROCEDURE IF EXISTS `getWorkcentersWorkload`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getWorkcentersWorkload` (IN `_factory` VARCHAR(50))  NO SQL
BEGIN
set @client_id = getClientID(`_factory`);
select `workcenters`.`name`, `workcenters`.`description`, `assigns`.`operation`
 , count(`assigns`.`id`) as `operation_count`
from `workcenters`
left JOIN `assigns` on `assigns`.`workcenter_id`=`workcenters`.`id`
where `workcenters`.`client_id`=@client_id and find_in_set(`assigns`.`bucket`, 'INCOME,PROCESSING')
 group by `workcenters`.`id`, `assigns`.`operation`;
END$$

DROP PROCEDURE IF EXISTS `makeMessageRead`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `makeMessageRead` (IN `_message_id` BIGINT UNSIGNED, IN `_user` VARCHAR(50))  NO SQL
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
DROP FUNCTION IF EXISTS `addOrder`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `addOrder` (`_factory` VARCHAR(50), `_number` VARCHAR(50), `_state` VARCHAR(10), `_route_id` INT, `_deadline` DATETIME) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'adds new order and returns uniq ID of order in database'
begin
set @client_id = getClientID(`_factory`);
insert into orders (number, client_id, state, current_route, deadline) values(`_number`, @client_id, `_state`, `_route_id`, `_deadline`);
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

DROP FUNCTION IF EXISTS `getBuckets`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getBuckets` (`_widget` INT) RETURNS VARCHAR(1024) CHARSET utf8 NO SQL
return (SELECT GROUP_CONCAT(bucket order by orderby SEPARATOR ',') from workcenter_bucket where showit =`_widget`)$$

DROP FUNCTION IF EXISTS `getClientID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getClientID` (`_factoryName` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED NO SQL
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
CREATE DEFINER=`root`@`localhost` FUNCTION `getWorkcenterID` (`_client_id` BIGINT UNSIGNED, `_name` VARCHAR(50)) RETURNS BIGINT(20) UNSIGNED NO SQL
    COMMENT 'returns workcenter''s id by mnemonic id of one'
return (select id from workcenters where client_id = `_client_id` and `name` like `_name`)$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
