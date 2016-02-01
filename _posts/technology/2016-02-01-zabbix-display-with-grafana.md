---
layout: post
title: Zabbix通过Grafana展现漂亮的趋势图
description: Zabbix的趋势图太丑？换成Grafana试试！当然也可以试着期待Zabbix3.0哦
category: technology
tags: Zabbix,智能运维,Grafana
---

## 先大体的了解一下Grafana

>**注意，如果只想看Grafana如何给Zabbix出图，那么不需要看InfluxDB和collectd的相关内容**

### 一，关闭不需要的服务

1. 使用`service iptables stop`关闭防火墙，以防止由于网络问题导致的各种奇怪问题。
2. 使用`setenforce 0`关闭selinux，防止安全权限等繁琐内容影响相关软件的正常使用。
3. 如果不想自定义关闭，而是具体配置相关规则，请自行搜索相关资料。
4. 可以通过`chkconfig iptables off`禁用防火墙开机自启，修改`/etc/selinux/config`文件禁用selinux开机自启。

### 二，安装influxDB并开启相关服务

>InfluxDB是一种数据库，按照时间序列来存储数据，非常适合存放历史统计数据，可以认为是rrdtool的进阶版。

1、配置influxdb的官方yum源

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

2、使用yum安装influxdb，并启动相关服务。InfluxDB是Go语言写的，不需要其他依赖包。

~~~
#   yum install influxdb
#   service influxdb start
~~~

3、使用`influx`命令进入influxdb的交互shell，在其中按照如下方式创建一个数据库。可以看到，语法和MySql用起来很相似。

~~~
# influx
>  SHOW DATABASES
>  CREATE DATABASE mydb
>  SHOW DATABASES
>  USE mydb
~~~

4、使用下列语句来插入几行数据，并使用SELECT查询刚刚插入的语句。详细语法请参考官方文档。

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

5、除使用交互环境获取数据外，InfluxDB还提供HTTP API，方便其他应用获取数据。

~~~
# curl -G 'http://localhost:8086/query?pretty=true' --data-urlencode "db=mydb" --data-urlencode "q=SELECT value FROM cpu"
~~~

6、除使用交互环境外，InfluxDB还提供了网页管理界面，默认用户名：root，密码：root。可以尝试访问 http://hostip/8083 来登录其管理界面。

7、配置influxdb可以接受collectd发过来的数据，关于collectd，会在后面介绍。

~~~
# vim /etc/influxdb/influxdb.conf
修改以下内容，使InfluxDB可以接受collectd发过来的数据，并将数据保存至mydb数据库中
[collectd]
  enabled = true
  database = "mydb"
# service influxdb restart
~~~

8、现在，查看一下InfluxDB开启的端口，确认influxdb服务正常运行。如果配置正确，则可以看到有4个端口，其中的25826端口是用来接收collectd发送的数据的。

~~~
# netstat -tupln|grep influx
tcp    0   0 :::8083      :::*        LISTEN      46476/influxd
tcp    0   0 :::8086      :::*        LISTEN      46476/influxd
tcp    0   0 :::8088      :::*        LISTEN      46476/influxd
udp    0   0 :::25826     :::*                    46476/influxd
~~~

### 三，使用collectd向influxDB中插入数据

>collectd是一个开源的监控程序，可以每隔一段时间，自动获取相关的监控参数，并发送给其他应用对这些监控数据进行处理。

1、配置epel源，并安装collectd

~~~
# rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
# yum install -y collectd
~~~

2、编辑其配置文件，使collectd将收集到的数据发送到InfluxDB中。

~~~
查看配置文件默认监控哪些内容
# egrep -v '^#|^$' /etc/collectd.conf
FQDNLookup   true
LoadPlugin syslog
LoadPlugin cpu
LoadPlugin interface
LoadPlugin load
LoadPlugin memory
　
# vim /etc/collectd.conf
添加以下内容，Server后面的IP地址是InfluxDB服务器所在的IP地址。
LoadPlugin network
<Plugin network>
        Server "192.168.18.132" "25826"
</Plugin>
~~~

3、启动collectd服务

~~~
# service collectd start
~~~

4、在InfluxDB中查看有没有获取到数据，如果没有数据，请耐心等待一段时间。

~~~
# influx
> USE mydb
> select * from /.*/ limit 5
~~~

### 四，安装grafana并开启相关服务

>Grafana是开源的一款图表展示工具，界面美观，配置方便。

1、直接安装grafana官方的安装包，并启动相关服务。同样因为是Go语言所写，不需要其他依赖包。

~~~
# yum install https://grafanarel.s3.amazonaws.com/builds/grafana-2.6.0-1.x86_64.rpm
# service grafana-server start
~~~

2、使用用户名：admin，密码：admin，访问 http://hostip:3000 并登陆进去。

3、根据以下步骤，添加数据源，使其可以从InfluxDB中获取数据绘图。

- 点击：左上角图标 --> Data Sources --> Add new
- 填写：Name    ：随便填
- 填写：Type    ：选择influxDB的版本
- 填写：Url     ： http://hostip:8086
- 填写：Database：mydb
- 填写：User    ：root
- 填写：Password：root
- 点击：Test Connection，确保可以正常连接后，点击Save按钮。

4、配置好数据的来源后，再添加面板、行、图像，将数据绘制成图片

- 点击：Dashboard --> New
- 点击：绿色小块 --> Add Panel --> Graph

5、具体配置图像的绘图方式

- 点击：General，配置标题等内容
- 点击：Metrics，填写sql语句，从InfluxDB中将数据查询出来
- 点击：save dashboard

### 五，配置开机自启脚本

上述步骤无误后，如果只做Grafana项目，则可以执行下列命令，设置相关服务为开机自启。（这种方式和chkconfig比较起来，可以更直观的了解这个功能有哪些组件）

~~~
echo '# grafana' >> /etc/rc.local
echo 'service influxdb start' >> /etc/rc.local
echo 'service collectd start' >> /etc/rc.local
echo 'service grafana-server start' >> /etc/rc.local
~~~

## 将Grafana和Zabbix结合起来

### 一，前期配置

- 配置好Zabbix以及相关监控项，详细步骤请参考我的另外一篇教程[安装/搭建/使用Zabbix](/zabbix-install-and-usage)，真的超详细哦。
- 在此之前，确保已正确安装grafana。如果Grafana只为了给Zabbix出图，那么InfluxDB和collectd是不需要安装的。


### 二，安装grafana-zabbix

>Grafana-Zabbix是一个Grafana的插件，Github上的项目地址在[这里](https://github.com/alexanderzobnin/grafana-zabbix)。

1、下载源码包并解压放入Grafana存放插件的路径后，重启Grafana服务，插件就安装成功了。

~~~
# cd /usr/share/grafana/public/app/plugins/datasource
# wget https://codeload.github.com/alexanderzobnin/grafana-zabbix/tar.gz/v2.5.1 -O grafana-zabbix.tar.gz
# tar -xf grafana-zabbix.tar.gz
# mv grafana-zabbix-2.5.1/zabbix/ ./
# service grafana-server restart
~~~

2、插件安装成功后，就可以添加zabbix数据源了。

- 点击：左上角图标-->Data Sources-->Add new
- 选择：Type选择Zabbix
- 填写：Name    ：Zabbix
- 填写：Url     ：http://192.168.18.132/zabbix/api_jsonrpc.php
- 填写：User    ：admin
- 填写：Password：zabbix
- 点击：Test Connection，确保可以正常使用后，点击save保存。

3、配置好数据源后，新建面板及图像，在图像中配置好要展示哪些监控项。

- Group：Zabbix主机所在的主机组。
- Host：要展示的主机。可以单独选择主机，或在filter中填写正则表达式来匹配相关主机。
- Application：监控项所在的分组。
- Item：要展示的监控项。可以单独选择监控项，或在filter中填写正则表达式来匹配监控项。

4、配置好后，就可以看到Grafana绘制的漂亮图片啦。可以进入Zabbix的“检测中 --> 最新数据”查看原来的图片，并进行比较。
