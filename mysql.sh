#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
O="\e[33m"
N="\e[0m"

mkdir -p /var/log/expense-logs

LOGS_DIR="/var/log/expense-logs"
FILENAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
LOGFILENAME="$LOGS_DIR/$FILENAME-$TIMESTAMP.log"


VALIDATE() {

    if [ $1 -ne 0 ]
    then
        echo -e "$2 .. $R FAILURE $N"
        exit 1
    else
        echo -e "$2 .. $G SUCCESS $N"
    fi

}

CHECKROOT() {
if [ $USERID -ne 0 ]
then
    echo "ERROR:: You must have sudo access to execute this script"
    exit 1
fi
}

CHECKROOT

dnf install mysql-server -y &>> $LOGFILENAME
VALIDATE $? "mysql installed"

systemctl enable mysqld &>> $LOGFILENAME
VALIDATE $? "mysql service enabled"

systemctl start mysqld &>> $LOGFILENAME
VALIDATE $? "mysql start started"

# mysql_secure_installation --set-root-pass ExpenseApp@1
# VALIDATE $? "password set"

#mysql -h mysql.devopspractice.help -u root -pExpenseApp@1 

mysql -h 172.31.13.67 -u root -pExpenseApp@1 -e 'show databases;' &>> $LOGFILENAME

if [ $? -ne 0 ]
then
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>> $LOGFILENAME
    VALIDATE $? "password set"
else
    echo -e "MySQL Root password already setup ... $Y SKIPPING $N"
fi
