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

dnf module disable nodejs -y &>>$LOGFILENAME
VALIDATE $? "disable nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILENAME
VALIDATE $? "enable nodejs:20"

dnf install nodejs -y &>>$LOGFILENAME
VALIDATE $? "install nodejs"

id expense &>>$LOGFILENAME

if [ $? -ne 0 ]
then
    useradd expense &>>$LOGFILENAME
    VALIDATE $? "useradd expense"
else
    echo "Expense user is already exists"
fi

mkdir -p /app &>>$LOGFILENAME
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILENAME
VALIDATE $? "Downloaded backend.zip"

cd /app &>>$LOGFILENAME
VALIDATE $? "Changing directory to /app"

unzip -o /tmp/backend.zip &>>$LOGFILENAME
VALIDATE $? "Unzipping builds"

npm install &>>$LOGFILENAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/expense-shell-practice/backend.service /etc/systemd/system/backend.service &>>$LOGFILENAME
VALIDATE $? "Copy backend.service"

systemctl daemon-reload 

systemctl start backend

systemctl enable backend

dnf install mysql -y &>>$LOGFILENAME
VALIDATE $? "installing mysql"

mysql -h mysql.devopspractice.help -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOGFILENAME

systemctl restart backend

systemctl status backend &>>$LOGFILENAME
VALIDATE $? "backend started"
