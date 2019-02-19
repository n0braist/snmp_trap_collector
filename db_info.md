### event db information

``` 
 mysql> show tables;
 +-------------------+
 | Tables_in_eventdb |
 +-------------------+
 | comment           | 
 | event             | 
 +-------------------+
 2 rows in set (0.00 sec)
 
 mysql> show columns from event;
 +--------------+---------------------+------+-----+---------+----------------+
 | Field        | Type                | Null | Key | Default | Extra          |
 +--------------+---------------------+------+-----+---------+----------------+
 | id           | bigint(20) unsigned | NO   | PRI | NULL    | auto_increment | 
 | host_name    | varchar(255)        | NO   | MUL | NULL    |                | 
 | host_address | binary(16)          | NO   |     | NULL    |                | 
 | type         | int(11)             | NO   |     | NULL    |                | 
 | facility     | int(11)             | YES  | MUL | NULL    |                | 
 | priority     | int(11)             | NO   | MUL | NULL    |                | 
 | program      | varchar(50)         | NO   |     | NULL    |                | 
 | message      | varchar(4096)       | YES  |     | NULL    |                | 
 | ack          | tinyint(1)          | YES  | MUL | 0       |                | 
 | created      | datetime            | YES  | MUL | NULL    |                | 
 | modified     | datetime            | YES  | MUL | NULL    |                | 
 +--------------+---------------------+------+-----+---------+----------------+
 11 rows in set (0.00 sec)

 Alarm priorities:
 -----------------
 PRIORITY 0 (EMERGENCY)
 PRIORITY 1 (ALERT)
 PRIORITY 2 (CRITICAL)
 PRIORITY 3 (ERROR)
 PRIORITY 4 (WARNING)
 PRIORITY 5 (NOTICE)
```

### snmptt information

``` 
 MariaDB [snmptt]> show tables;;             
 +-------------------+
 | Tables_in_snmptt  |
 +-------------------+
 | snmptt            |
 | snmptt_statistics |
 +-------------------+
 2 rows in set (0.00 sec)
 
 ERROR: No query specified
 
 MariaDB [snmptt]> show columns from  snmptt;
 +------------+------------------+------+-----+---------+----------------+
 | Field      | Type             | Null | Key | Default | Extra          |
 +------------+------------------+------+-----+---------+----------------+
 | id         | int(10) unsigned | NO   | PRI | NULL    | auto_increment |
 | eventname  | varchar(50)      | YES  |     | NULL    |                |
 | eventid    | varchar(50)      | YES  |     | NULL    |                |
 | trapoid    | varchar(100)     | YES  |     | NULL    |                |
 | enterprise | varchar(100)     | YES  |     | NULL    |                |
 | community  | varchar(20)      | YES  |     | NULL    |                |
 | hostname   | varchar(100)     | YES  |     | NULL    |                |
 | agentip    | varchar(16)      | YES  |     | NULL    |                |
 | category   | varchar(20)      | YES  |     | NULL    |                |
 | severity   | varchar(20)      | YES  |     | NULL    |                |
 | uptime     | varchar(20)      | YES  |     | NULL    |                |
 | traptime   | varchar(30)      | YES  |     | NULL    |                |
 | formatline | varchar(255)     | YES  |     | NULL    |                |
 +------------+------------------+------+-----+---------+----------------+
 13 rows in set (0.00 sec)
```
