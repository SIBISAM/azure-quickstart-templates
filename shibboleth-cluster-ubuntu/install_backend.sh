
mysqlpassword=$1
mySqlUser=$2
mySqlPasswordForUser=$3

apt-get -y update
apt-get -y install apache2 openjdk-7-jdk tomcat7	

#install mysql
echo mysql-server mysql-server/root_password password $mysqlpassword | sudo debconf-set-selections
echo mysql-server mysql-server/root_password_again password $mysqlpassword | sudo debconf-set-selections

apt-get -y install mysql-client mysql-server
apt-get	install libmysql-java

# Allow remote connection
sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# Create secure MySQL configuration file to avoid password exposure in process lists
cat > /tmp/mysql_config.cnf << EOF
[client]
user=root
password=$mysqlpassword
EOF
chmod 600 /tmp/mysql_config.cnf

#create database
mysql --defaults-extra-file=/tmp/mysql_config.cnf -e "create database idp_db";

#create table 
mysql --defaults-extra-file=/tmp/mysql_config.cnf -e "use idp_db; create table StorageRecords(context varchar(255) NOT NULL,id varchar(255) NOT NULL,expires bigint(20) DEFAULT NULL,value longtext NOT NULL,version bigint(20) NOT NULL,PRIMARY KEY(context,id))";

#create user & grant all privileges
mysql --defaults-extra-file=/tmp/mysql_config.cnf -e "create user $mySqlUser@'localhost' identified by '$mySqlPasswordForUser'";
mysql --defaults-extra-file=/tmp/mysql_config.cnf -e "grant all privileges on *.* to $mySqlUser@'localhost'";

mysql --defaults-extra-file=/tmp/mysql_config.cnf -e "create user $mySqlUser@'%' identified by '$mySqlPasswordForUser'";
mysql --defaults-extra-file=/tmp/mysql_config.cnf -e "grant all privileges on *.* to $mySqlUser@'%'";

# Clean up the temporary configuration file
rm -f /tmp/mysql_config.cnf

#restart mysql
service mysql restart 
