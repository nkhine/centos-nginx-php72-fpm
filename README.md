Create a memcache test consisting of a MySQL database and PHP script
--

The test uses a MySQL database, table, and data to verify you can retrieve the database data and store it in memcache. A PHP script first searches the cache . If the result does not exist, the script queries database. After the query has been fulfilled by the original database, the script stores the result in memcache, using the set command.

More details about this test
* Install memcache docer server:
see https://hub.docker.com/_/memcached


* Create the MySQL database:
see https://dev.mysql.com/doc/mysql-linuxunix-excerpt/5.7/en/docker-mysql-getting-started.html

```
# docker exec -it mysql1 /bin/bash
mysql> use mysql;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> CREATE USER 'cache'@'%' IDENTIFIED BY 'password';
Query OK, 0 rows affected (0.02 sec)

mysql> GRANT ALL on *.* to 'cache'@'%';
Query OK, 0 rows affected (0.02 sec)

mysql> ALTER USER 'cache'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
Query OK, 0 rows affected (0.02 sec)

mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.01 sec)

```

At the mysql prompt, enter the following commands:

```
CREATE DATABASE memcache_test;
USE memcache_test;
CREATE TABLE example (id int, name varchar(30));
INSERT INTO example VALUES (1, "new_data");
```

* On a new terminal, ssh into the centos container

```
docker exec -ti romantic_goldberg /bin/bash
[root@33901ea03cf2 html]# cd /var/www/html

[root@33901ea03cf2 html]# php72 cache-test.php

or navigate to http://172.17.0.2/cache-test.php and refresh the browser

[root@33901ea03cf2 html]# telnet 172.17.0.3 11211
Trying 172.17.0.3...
Connected to 172.17.0.3.
Escape character is '^]'.
stats items
STAT items:3:number 1
STAT items:3:number_hot 0
STAT items:3:number_warm 0
STAT items:3:number_cold 1
STAT items:3:age_hot 0
STAT items:3:age_warm 0
STAT items:3:age 13
STAT items:3:evicted 0
STAT items:3:evicted_nonzero 0
STAT items:3:evicted_time 0
STAT items:3:outofmemory 0
STAT items:3:tailrepairs 0
STAT items:3:reclaimed 0
STAT items:3:expired_unfetched 0
STAT items:3:evicted_unfetched 0
STAT items:3:evicted_active 0
STAT items:3:crawler_reclaimed 0
STAT items:3:crawler_items_checked 0
STAT items:3:lrutail_reflocked 0
STAT items:3:moves_to_cold 1
STAT items:3:moves_to_warm 0
STAT items:3:moves_within_lru 0
STAT items:3:direct_reclaims 0
STAT items:3:hits_to_hot 0
STAT items:3:hits_to_warm 0
STAT items:3:hits_to_cold 0
STAT items:3:hits_to_temp 0
END
quit
Connection closed by foreign host.
[root@33901ea03cf2 html]#
```

more info on PHP memcached - https://www.php.net/manual/en/memcached.set.php