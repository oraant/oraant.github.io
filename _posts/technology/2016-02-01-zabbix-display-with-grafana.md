---
layout: post
title: Zabbix通过Grafana展现漂亮的趋势图
description: Zabbix的趋势图太丑？换成Grafana试试！当然也可以试着期待Zabbix3.0哦
category: technology
tags: Zabbix,智能运维,Grafana
---

## 先全面的了解一下Grafana

### 一，关闭不需要的服务

1. 关闭防火墙
2. 关闭selinux


### 二，安装influxDB并开启相关服务

>InfluxDB按照时间序列来存储数据，非常适合存放历史统计数据，可以认为是rrdtool的进阶版

1、配置yum源

~~~
# cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
#   [influxdb]
#   name = InfluxDB Repository - RHEL \$releasever
#   baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
#   enabled = 1
#   gpgcheck = 1
#   gpgkey = https://repos.influxdata.com/influxdb.key
#   EOF
~~~

2、安装influxdb的单独包并启动

~~~
#   yum install influxdb
#   service influxdb start
~~~

3、使用influxdb库

~~~
# influx
>  SHOW DATABASES
>  CREATE DATABASE mydb
>  SHOW DATABASES
>  USE mydb
~~~

4、读写数据

~~~
> INSERT cpu,host=serverA,region=us_west value=0.64
> INSERT cpu,host=serverA,region=us_west value=1.64
> INSERT cpu,host=serverA,region=us_west value=2.64
> INSERT cpu,host=serverA,region=us_west value=3.64
> INSERT cpu,host=serverA,region=us_west value=4.64
> 
> SELECT * FROM cpu
name: cpu
…………
time                    host    region  value
1453953608525585913     serverA us_west 0.64
1453953613005756086     serverA us_west 1.64
1453953614917158282     serverA us_west 2.64
1453953616757137296     serverA us_west 3.64
1453953618374023412     serverA us_west 4.64
~~~

5、使用HTTP API获取数据

~~~
# curl -G 'http://localhost:8086/query?pretty=true' --data-urlencode "db=mydb" --data-urlencode "q=SELECT value FROM cpu"
~~~

6、测试能否访问

~~~
访问 http://hostip/8083   登录其管理界面，查看是否可以正常登录。
~~~

7、配置influxdb可以接受collectd发过来的数据

~~~
# vim /etc/influxdb/influxdb.conf
修改以下内容：
[collectd]
  enabled = true
  database = "mydb"
# service influxdb restart
~~~

8、确认influxdb服务正常运行

~~~
# netstat -tupln|grep influx
tcp    0   0 :::8083      :::*        LISTEN      46476/influxd
tcp    0   0 :::8086      :::*        LISTEN      46476/influxd
tcp    0   0 :::8088      :::*        LISTEN      46476/influxd
udp    0   0 :::25826     :::*                    46476/influxd
~~~

### 三，使用collectd向influxDB中插入数据

1、安装并使用collectd

~~~
# rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
# yum install -y collectd
~~~

2、编辑配置文件

~~~
# egrep -v '^#|^$' /etc/collectd.conf
FQDNLookup   true
LoadPlugin syslog
LoadPlugin cpu
LoadPlugin interface
LoadPlugin load
LoadPlugin memory
　
# vim /etc/collectd.conf
添加以下内容
LoadPlugin network
<Plugin network>
        Server "192.168.18.132" "25826"
</Plugin>
~~~

3、启动collectd

~~~
# service collectd start
~~~

### 四，安装grafana并开启相关服务

1、直接安装grafana的单独包

~~~
# yum install https://grafanarel.s3.amazonaws.com/builds/grafana-2.6.0-1.x86_64.rpm
# service grafana-server start
~~~

2、使用用户名：admin，密码：admin，访问 http://hostip:3000   并登陆

3、添加数据源

~~~
点击：左上角图标 --> Data Sources --> Add new
填写：  Name    ：随便填
填写：  Type    ：选择influxDB的版本
填写：  Url     ： http://hostip:8086
填写：  Database：mydb
填写：  User    ：root
填写：  Password：root
点击：Test Connection，确保可以正常连接
点击：Save
~~~

4、添加面板、行、图像

~~~
点击：Dashboard --> New
点击：绿色小块 --> Add Panel --> Graph
~~~

5、配置图像

~~~
点击：General，配置标题等内容
点击：Metrics，填写sql语句
拖动：拖动上方图片，查找数据并将时间拉开，确保可以看到数据
点击：save dashboard
~~~

### 五，配置开机自启脚本

执行下列命令，设置相关服务为开机自启。（这种方式和chkconfig比较起来，可以更直观的了解这个功能有哪些组件）

~~~
echo '# grafana' >> /etc/rc.local
echo 'service influxdb start' >> /etc/rc.local
echo 'service collectd start' >> /etc/rc.local
echo 'service grafana-server start' >> /etc/rc.local
~~~

## 将Grafana和Zabbix结合起来

### 敬请期待

正在努力码字中
