#!/bin/bash

#获取本地ip地址
function getLocalIp()
{
    LocalIp=`ifconfig -a|grep inet|grep -v inet6|grep -v 127.0.0.1|awk '{print $2}'|tr -d "addr:"`
	echo $LocalIp
}

tomcat_path="/opt/tomcat/webapps/"
deploy_path="/opt/deploy/"
config_path="/WEB-INF/classes/config/"
web_path="ROOT/static"
db_config_path="/WEB-INF/classes/db/"
date=$(date "+%Y%m%d")
back_path="/opt/tomcat/bak/$date/"

#替换配置文件
function setConfig()
{
   sed -i 's!^'$1'.*!'$1'='$2'!g' $3
   echo "sed -i 's!^'$1'.*!'$1'='$2'!g' $3"
}

#文件服务配置
function setFdfsConf()
{
    fname="${tomcat_path}$1${config_path}file.properties"
	localip=$(getLocalIp)
	if [ -f "$fname" ];then
		setConfig "file.trackerServier" "$2:22122"   $fname
		setConfig "file.storageServer" "$2:23000" $fname
		setConfig "file.httpUrl" "http://$2:8880/" $fname
	fi
}

#rabbitmq配置
function setRabbitmq()
{
   fname="${tomcat_path}$1${config_path}rabbitmq.properties"
   if [ -f "$fname" ];then
	   setConfig "rabbitmq.serviceip" "$2" $fname
	   setConfig "rabbitmq.username" "admin" $fname
	   setConfig "rabbitmq.password" "admin" $fname
   fi
}

#redis配置
function setRedis()
{
   fname="${tomcat_path}$1${config_path}redis.properties"
   if [ -f  "$fname" ];then
	  setConfig "redis.host" "$2" $fname
	  setConfig "redis.dbchose" "3" $fname
   fi
}

#struct配置
function setStruct()
{
   fname="${tomcat_path}$1${config_path}struct.properties" 
   if [ -f "$fname" ];then
	   setConfig "structur.apiKey" "$2" $fname
	   setConfig "structur.secretKey" "$2" $fname
	   setConfig "structur.serviceUrl" "http://$3:9902/signalway/image/structurization.htm" $fname
	   setConfig "timatrix.libName" "$4" $fname
   fi
}

#数据库配置
function setDb()
{
   fname="${tomcat_path}$1${config_path}jdbc.properties"
   if [ -f "$fname" ];then
      setConfig "pgsql.db.user" "postgres" $fname
	  setConfig "pgsql.db.password" "1234zxcv" $fname
	  setConfig "pgsql.db.url" "jdbc:postgresql://$2:5432/tencentPoc" $fname
      setConfig "pgsql.readOnleydb.url" "jdbc:postgresql://$3:5432/tencentPoc" $fname
   fi
}

#第三方登录配置
function setCasLogin()
{
   fname="${tomcat_path}$1${config_path}caslogin.properties"
   if [ -f "$fname" ];then
       setConfig "casServiceUrl" "http://$2"  $fname
	   setConfig "casLoginSuccessUrl" "http://$3"  $fname
   fi
}

#备份tomcat
function bakWar()
{
   time=$(date "+%Y%m%d-%H%M%S")
   if [ -d "${tomcat_path}$1" ]; then
      tar -zcPf ${back_path}bak_$1$time.tar.gz -C ${tomcat_path} $1
      rm -fr ${tomcat_path}$1
   fi
}

#停止tomcat
function stopTomcat()
{
   for tomcatuid in `ps -ef | grep -v grep | grep tomcat | awk '{print $2}'`
   do 
	  kill -9  $tomcatuid;
   done;
}

#部署tomcat
function deployTomcat()
{
    unzip -oq $deploy_path$1.war -d /opt/tomcat/webapps/$1
}

function startTomcat()
{
   /opt/tomcat/bin/startup.sh 
}

#设置所有配置
function setConf()
{
   localip=$(getLocalIp)
   setFdfsConf $1 "172.18.2.9"
   setRabbitmq $1 "172.18.2.5"
   setRedis $1 "172.18.2.5"
   setDb $1 "172.18.2.5" "172.18.2.5"
   setStruct $1 "LIZL46C6E9844E24B3CBBDC03E2630FF" "172.18.10.137" "PocTestlib6" $fname
   setCasLogin $1 "172.18.121.13:8080" "172.18.2.5:8080"
}

function setAllConf()
{
   setConf "highwayAnalysisEntry"
   setConf "highwayClientEntry"
   setConf "highwayDeviceEntry"
   setConf "highwayTimingEntry"
   setConf "imgStructurEntry"
}

function main()
{
   stopTomcat
   cd $tomcat_path
   mkdir -p $back_path
   deployTomcat "highwayAnalysisEntry"
   deployTomcat "highwayClientEntry"
   deployTomcat "highwayDeviceEntry"
   deployTomcat "highwayTimingEntry"
   deployTomcat "imgStructurEntry"
   setAllConf
   startTomcat
}

main

