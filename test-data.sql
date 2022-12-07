USE TestDB;
-- enable changes tracking on the database level
ALTER DATABASE CURRENT
  SET CHANGE_TRACKING = ON
  (CHANGE_RETENTION = 2 HOURS, AUTO_CLEANUP = ON);
GO
-- drop tables
DROP TABLE IF EXISTS test_Object;
DROP TABLE IF EXISTS test_ObjectValue;
GO
-- and create them again
CREATE TABLE test_Object (
  id INT IDENTITY(1, 1) NOT NULL,
  name NVARCHAR(100),
  comment NVARCHAR(MAX),
  CONSTRAINT PK_test_Object PRIMARY KEY CLUSTERED (id)
);
CREATE TABLE test_ObjectValue (
  obj_id INT,
  date_time DATETIME,
  value1 INT,
  value2 NVARCHAR(10),
  value3 NUMERIC(5, 2),
  CONSTRAINT PK_test_ObjectValue PRIMARY KEY CLUSTERED (obj_id, date_time)
);
-- enable change tracking on the table level
ALTER TABLE test_Object ENABLE CHANGE_TRACKING;
ALTER TABLE test_ObjectValue ENABLE CHANGE_TRACKING;
GO
-- fill tables
-- create object 1
INSERT INTO test_Object(name, comment)
  VALUES ('Jennifer Baker', 'lauraflores@example.org');
-- create values for object 1
INSERT INTO test_ObjectValue
  (obj_id, date_time, value1, value2, value3)
  VALUES
    (1, '2022-11-15 01:22:58', 876, '#9QZOqHw6w', 883.66),
    (1, '2022-11-15 07:23:47', 289, 'ZgS7_Ul&@T', 143.29),
    (1, '2022-11-15 23:50:23', 224, '_7MUYXqqn1', 401.94),
    (1, '2022-11-17 00:21:39', 845, '_HGQ6Hh^tq', 131.65),
    (1, '2022-11-17 00:25:17', 807, 'ujAYEq@1*3', 767.53),
    (1, '2022-11-17 18:03:09', 476, '$K@q6@Ge8y', 950.68),
    (1, '2022-11-18 03:11:37', 290, 'K7HBfTJg)Q', 991.70),
    (1, '2022-11-19 12:21:14', 151, '+w7Hui5dpP', 572.83),
    (1, '2022-11-19 21:03:12', 137, '#k4GZknA)F', 686.34),
    (1, '2022-11-19 21:44:00', 925, '0CRm1Obj!a', 278.62);
GO
-- create object 2
INSERT INTO test_Object(name, comment)
  VALUES ('Peter Mckay', 'cwood@example.org');
-- create values for object 2
INSERT INTO test_ObjectValue
  (obj_id, date_time, value1, value2, value3)
  VALUES
    (2, '2022-11-13 19:52:42', 839, 'H^m1Sv)dF*', 925.04),
    (2, '2022-11-14 05:16:25', 670, '@K^2O!yjBZ', 774.91),
    (2, '2022-11-14 22:30:42', 864, 'xt9c@CMk)%', 767.11),
    (2, '2022-11-15 23:13:39', 962, '(&Z&gGHe21', 495.54),
    (2, '2022-11-16 16:34:37', 355, '*7OkBmz^Vg', 549.07);
GO
-- create object 3
INSERT INTO test_Object(name, comment)
  VALUES ('Whitney Cooper', 'robertberry@example.net');
-- create values for object 3
INSERT INTO test_ObjectValue
  (obj_id, date_time, value1, value2, value3)
  VALUES
    (3, '2022-11-13 10:49:20', 867, '(6Pcc&h_Pp', 239.36),
    (3, '2022-11-13 23:14:55', 325, '6*fs6RHarS', 144.78),
    (3, '2022-11-14 02:17:14', 270, '0#b1)Sr1_P', 614.12),
    (3, '2022-11-14 22:55:38', 644, 'D18MdEeg@%', 828.77),
    (3, '2022-11-15 17:52:10', 378, 'uM*S0LvO+3', 267.43),
    (3, '2022-11-15 22:12:31', 115, ')$+(4S@ryJ', 316.61),
    (3, '2022-11-16 13:30:40', 176, '6vKd&btT!p', 494.55),
    (3, '2022-11-17 15:51:50', 827, '&aHfq+_rH9', 531.71),
    (3, '2022-11-18 08:35:17', 431, 'aoB44ZVu%1', 471.69),
    (3, '2022-11-18 13:05:26', 799, '&0RrT#6eak', 721.25),
    (3, '2022-11-19 00:08:51', 723, ')2V5y4IL3m', 701.45),
    (3, '2022-11-19 16:23:15', 671, 'cVx_&SY7^5', 406.38);
GO
-- create object 4
INSERT INTO test_Object(name, comment)
  VALUES ('Nathaniel Smith', 'christinareid@example.com');
-- create values for object 4
INSERT INTO test_ObjectValue
  (obj_id, date_time, value1, value2, value3)
  VALUES
    (4, '2022-11-14 01:09:16', 342, '87zOn@Fi(7', 853.33),
    (4, '2022-11-15 02:19:40', 841, '!30mrYQbl+', 258.59),
    (4, '2022-11-17 13:27:19', 938, 'J38LKxglu*', 725.06),
    (4, '2022-11-18 02:19:15', 336, 'E!*I&8HiDU', 184.52),
    (4, '2022-11-18 20:43:01', 891, 'QH_1!GMhf6', 941.14),
    (4, '2022-11-20 03:35:04', 870, '698Hmqs(($', 316.95);
GO
-- create object 5
INSERT INTO test_Object(name, comment)
  VALUES ('Christine Smith', 'larsonkristopher@example.org');
-- create values for object 5
INSERT INTO test_ObjectValue
  (obj_id, date_time, value1, value2, value3)
  VALUES
    (5, '2022-11-14 01:18:32', 233, 'sy1URJYu$8', 860.38),
    (5, '2022-11-14 04:29:27', 667, 'T#HipJdp^3', 994.73),
    (5, '2022-11-15 03:30:07', 530, ')5KctadfUv', 112.03),
    (5, '2022-11-15 05:41:41', 782, '@LFiu5OU8%', 243.72),
    (5, '2022-11-15 11:04:53', 735, 'i2BQyiyZ#I', 885.22),
    (5, '2022-11-15 23:40:47', 510, '*O445NSg#L', 301.65),
    (5, '2022-11-16 12:58:13', 549, '%Q$FD7mE(0', 361.06),
    (5, '2022-11-17 04:51:41', 729, '5m$2CUkqnH', 927.10),
    (5, '2022-11-17 06:42:27', 989, '$@UZAJMC2j', 836.32),
    (5, '2022-11-17 22:31:57', 992, 'AL*t6YgaO%', 138.09),
    (5, '2022-11-18 13:41:49', 370, 'a#Wl%tig$2', 789.16),
    (5, '2022-11-18 15:49:35', 677, 'X5GP#ih!_)', 645.83),
    (5, '2022-11-18 22:50:56', 603, 'jH8%*NNs#6', 686.36),
    (5, '2022-11-19 10:07:54', 262, '!rY%#5XkDd', 310.18);
GO
