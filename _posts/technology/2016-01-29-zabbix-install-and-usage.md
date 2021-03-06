---
layout: post
title: 安装/搭建/使用Zabbix
description: Zabbix如何安装？如何监控、出图、报警、发邮件？Zabbix还有哪些功能？
category: technology
tags: Zabbix,智能运维
---

## 一、Zabbix简介

### 1.关于智能运维
随着技术的发展，云计算和大数据变得热门，企业的IT设施也在不断的增长。面对着成千上万的机器集群，传统的运维方式已经渐渐无法满足时代的要求，如何同时监控大批量的机器并智能报警、同时批量配置机器、在整套业务系统中快速定位问题，成为了运维人员需要掌握的基本技能。

面对这样的需要，市面上也涌现了一大批高质量的智能运维产品，目前看来，智能运维产品主要有以下四种：

- 监控及报警：监控机器性能、网卡、服务是否开启等，发现问题通过邮件、短信等方式及时报警。
- 批量配置：快速将某些配置同步到大量的机器中。
- 问题快速定位：从大量机器中监控各项日志、业务流程，快速定位出现的问题。
- 应用监控测试：监控业务的响应时间，主要体现在网页监控上，此处不进行说明。

市面上常见的较为完善的产品如下（加粗为推荐产品）：

| 监控及报警  |  批量配置 | 问题快速定位  |
| ------------ | ------------ | ------------ |
| Nagios | Puppet  | Splunk  |
| Cacti  | Func  |  **ELKstack** |
| **Zabbix** | **Saltstack**  | Graylog  |
| Ganglia | ……  | ……  |
|……|……  | ……  |

除了这些常见的国际产品，还有国内功能较为完善的监控宝、阿里云监控等，除此之外，还有一些功能强大的产品，比如：

- 专注于收集数据的`Collectd`、`Graphite`
- 专注于应用监测管理的`NewRelic`
- 专注于抓取业务流程的`Wireshark`
- 专注于图形展示的`Grafana`
- 专注于时间序列数据存储的`InfluxDB`
- 专注于统一报警的`One Alert`
- 其他……

### 2.同类产品简介
对于监控软件来说，最常见的是Cacti、Nagios、Zabbix三个软件，下面对这三个产品进行一下简单的介绍：

**Cacti**：cacti是基于PHP,MySQL,SNMP及RRDTool开发的网络流量监测图形分析工具。可以通过SNMP协议或自定义脚本的方式，从主机、数据库、应用、硬件设备中抓取相关的性能参数，并通过RRDTOOL绘制成趋势图展示出来。
Cacti包含了用户管理、监控模板、树形图展示等功能，可以方便的大批量的展示趋势图片，和Zabbix相比，Cacti的界面清晰美观，但功能上要逊色很多。
![](/images/2016-01-29-zabbix-install-and-usage/95f8e50f-dea9-4f32-8094-b5daf854089d.jpg)

**Nagios**：Nagios是一个监视系统运行状态和网络信息的监视系统。Nagios能监视所指定的本地或远程主机以及服务，同时提供异常通知功能等。设计者将Nagios设计成监测的管理中心，尽管其功能是监测服务和主机，但是他自身并不包括这部分功能的代码，所有的监测、监测功能都是由相关插件来完成的，包括报警功能。
nagios最大的亮点是轻量灵活，且报警机制很强。在企业中，经常将Nagios和Cacti结合起来使用。
![](/images/2016-01-29-zabbix-install-and-usage/010b204f-d858-40c1-bc84-48558899e0b2.jpg)

**Zabbix**：相比较其他产品，Zabbix是一个大而全的产品。功能非常的多，也考虑了很多方面的需求。包括用户管理、报警、收集数据、日志监控、图形展示、拓扑展示等等，并且每个功能都做的非常的精细。读者将跟随本篇实践文档，实际对Zabbix进行操作。
![](/images/2016-01-29-zabbix-install-and-usage/65280414-4a5c-49be-b05e-c002be50f1fa.png)


三个产品都是开源免费的，三个产品的优劣如下：

- Cacti：比较着重于直观数据的监控，易于生成图形，用来监控网络流量、cpu使用率、硬盘使用率等可以说很在合适不过。
- Nagios：则比较注重于主机和服务的监控，并且有很强大的发送报警信息的功能。
- Cacti+Nagios：把两者结合起来，既可以使报警机制高效及时，又可以很容易的查看各项数据的情况。
- Zabbix：已经完美取代Ngios+Cacti，唯一的缺点就是界面丑一些，但是不久后发布的Zabbix3.0正式版会对界面进行全面的改善，所以，对于监控方面来讲，Zabbix是最应该学习的产品。

![](/images/2016-01-29-zabbix-install-and-usage/5abacba2-18ec-4c66-a878-26de65d52cee.png)



### 3.zabbix进程组成结构
默认情况下zabbix包含5个程序：zabbix_agentd、zabbix_get、zabbix_proxy、zabbix_sender、zabbix_server，另外一个zabbix_java_gateway是可选，这个需要另外安装。下面来分别介绍下他们各自的作用。

- **zabbix_agentd**
客户端守护进程，此进程收集客户端数据，例如cpu负载、内存、硬盘使用情况等
- **zabbix_get**
zabbix工具，单独使用的命令，通常在server或者proxy端执行获取远程客户端信息的命令。通常用户排错。例如在server端获取不到客户端的内存数据，我们可以使用zabbix_get获取客户端的内容的方式来做故障排查。
- **zabbix_sender**
zabbix工具，用于发送数据给server或者proxy，通常用于耗时比较长的检查。很多检查非常耗时间，导致zabbix超时。于是我们在脚本执行完毕之后，使用sender主动提交数据。
- **zabbix_server**
zabbix服务端守护进程。zabbix_agentd、zabbix_get、zabbix_sender、zabbix_proxy、zabbix_java_gateway的数据最终都是提交到server
备注：当然不是数据都是主动提交给zabbix_server,也有的是server主动去取数据。
- **zabbix_proxy**
zabbix代理守护进程。功能类似server，唯一不同的是它只是一个中转站，它需要把收集到的数据提交/被提交到server里。为什么要用代理？代理是做什么的？卖个关子，请继续关注运维生存时间zabbix教程系列。
- **zabbix_java_gateway**
zabbix2.0之后引入的一个功能。顾名思义：Java网关，类似agentd，但是只用于Java方面。需要特别注意的是，它只能主动去获取数据，而不能被动获取数据。它的数据最终会给到server或者proxy。

## 二、项目简介及环境说明

### 1.项目简介
此次实验的目的如下：

- 掌握Zabbix基本的安装和配置
- 利用Zabbix监控一台Linux主机
- 利用Zabbix监控一台MySQL
- Zabbix其他功能简介

### 2.环境说明
为保证实验效果，要求机器可以`联网`，并`关闭防火墙`，如何使虚拟机连接互联网不在此教程范围内。
虚拟机环境如下：

|---+---+---+--+--+--|
|机器|操作系统|IP地址|CPU数量|内存|磁盘|
|---|---|---|--|--|--|
|虚拟机A|RHEL6.5|192.168.18.131|1颗|2G|40G|
|虚拟机B|RHEL6.5|192.168.18.132|1颗|2G|40G|
|---+---+---+--+--+--|

Zabbix版本：2.4.7。MySQL版本：5.1.73

## 三、Zabbix的搭建及配置

>本实验中，`虚拟机B`为服务器，`虚拟机A`为被监控的主机。

### 1.服务器端（虚拟机B）
1.配置好服务器的本地yum源（此处不做详细介绍）

2.安装基础的软件包（确保以下每个包都安装了）

~~~BASH
# yum -y groupinstall "Development Tools"
# yum -y install httpd mysql mysql-server php php-mysql php-common php-mbstring php-gd php-odbc php-pear curl curl-devel net-snmp net-snmp-devel perl-DBI php-xml ntpdate php-bcmath
~~~

3.创建Zabbix用户

~~~
# useradd zabbix
~~~

4.在MySQL中创建Zabbix数据库及用户

~~~
# mysql -uroot -p123456
mysql> use mysql;
mysql> delete from user where user='';
mysql> create database zabbix character set utf8;
mysql> grant all privileges on zabbix.* to zabbix@'%' identified by 'zabbix';
mysql> commit;
mysql> flush privileges;
~~~

>如何初始化MySQL数据库不在此教程范围内

5.为yum工具配置网易和Zabbix官方的软件仓库

~~~SHELL
# wget -O /etc/yum.repos.d/CentOS6-Base-163.repo http://mirrors.163.com/.help/CentOS6-Base-163.repo
# rpm -ivh http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm 
~~~

6.安装Zabbix并将相关数据导入MySQL数据库中

~~~
# yum install zabbix-server-mysql zabbix-web-mysql
# cd /usr/share/doc/zabbix-server-mysql-2.4.7/create
# mysql -uzabbix -pzabbix zabbix < schema.sql
# mysql -uzabbix -pzabbix zabbix < images.sql
# mysql -uzabbix -pzabbix zabbix < data.sql
~~~

7.修改Zabbix配置文件中的数据库部分

~~~
# vi /etc/zabbix/zabbix_server.conf
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
~~~

8.修改php的配置

~~~SHELL
# vim /etc/php.ini
添加以下内容：
date.timezone=Asia/Shanghai
~~~

9.启动相关服务，关闭防火墙、selinux等

~~~
# service zabbix-server start
# service httpd restart
# service iptables stop
# setenforce 0
# vim /etc/selinux/config
将SELINUX=enforcing更改为SELINUX=disabled
~~~

10.启动Web界面，完成剩余的安装工作
访问地址`http://192.168.18.132/zabbix/`，一直下一步。安装完后，通过“用户名：admin”“密码：zabbix”来登录。

11.参考资料：

* [Zabbix官方文档](https://www.zabbix.com/documentation/2.4/manual/installation/install_from_packages)
* [Zabbix搭建技术博客](http://blog.chinaunix.net/xmlrpc.php?r=blog/article&uid=17238776&id=4594985)

### 2.被监控端（虚拟机A）
1.为yum安装Zabbix源

~~~
# rpm -ivh http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm
~~~

2.安装agent端的软件包

~~~
# yum  -y groupinstall  "Development Tools"
# yum install zabbix-agent
~~~

3.修改agent端的配置文件，填写上服务端的IP地址

~~~
# vim /etc/zabbix/zabbix_agentd.conf
Server=192.168.18.132
~~~

4.启动agent

~~~
# service zabbix-agent start
~~~

5.参考资料：

- [根据官方文档快速学会使用zabbix](https://www.zabbix.com/documentation/2.4/manual/quickstart/login)
- [根据野生教程快速使用zabbix](http://www.ttlsa.com/monitor/zabbix/page/8/)

## 四、Zabbix快速入门
>由于此部分为入门级别的教程，所以会通过大量的截图及备注来展现每一步的操作。

### 1.配置Zabbix为中文界面
Zabbix自带了多种语言的语言包，只需要简单配置一些，就可以让Zabbix显示中文界面，但其对中文的翻译有很多不合适的地方，所以实际环境中推荐使用英文显示。

1.点击右上角的Profile，进入修改语言界面。
![](/images/2016-01-29-zabbix-install-and-usage/d5827e2c-fb0c-4622-9d33-48c050da33b8.png)

2.在Profile中修改默认显示的语言，并保存修改。
![](/images/2016-01-29-zabbix-install-and-usage/f587e5f7-9aa9-4910-a955-00ae6f653b05.png)

3.可以看到，界面已经变成了中文界面。
![](/images/2016-01-29-zabbix-install-and-usage/0eecc0e5-5411-49ba-949b-08d97dce5f6b.png)

### 2.为Zabbix创建第一个用户
Zabbix默认只有两个用户：

- 'Admin'用户是Zabbix的超级用户，拥有所有的权限。
- 'Guest'用户是一个特殊的用户，如果你没有登录，那么你的权限就是“客户”账户所拥有的权限。客户账户对Zabbix的对象没有任何权限。

Zabbix默认的超级用户是Admin，密码是zabbix，以超级用户登录后，就会在右下方看到“连接为Admin”的提示。超级用户有修改配置和管理Zabbix的权限。在登录时，如果连续失败5次，那么30秒内就不能再次登录了，以防止有人使用暴力破解或字典攻击，并且管理员成功登录后，会提示之前登录失败的IP地址。

下面将演示如何创建一个新用户：

1.按照“管理 --> 用户 --> 下拉菜单选用户”的顺序进入用户管理界面，并点击“创建用户”按钮。
![](/images/2016-01-29-zabbix-install-and-usage/4b553c86-1f15-490d-b5c5-429d516bf0f9.png)

2.填写用户的基本信息，其中：用户名、群组、密码必须要填写。
![](/images/2016-01-29-zabbix-install-and-usage/04e911a0-4346-431e-8ce0-a056175c27e8.png)

3.进入“示警媒介”页面，点击“添加”。所谓示警媒介，就是指的接收报警的方式。
![](/images/2016-01-29-zabbix-install-and-usage/d7e4335c-d793-48e3-9c5d-ff62a343d212.png)

4.选择接收报警的类型、时间段、级别，并点击“添加”按钮。邮箱推荐使用163邮箱，如果使用qq邮箱可能会导致后期无法收到邮件。
![](/images/2016-01-29-zabbix-install-and-usage/f4c5aed2-b880-45e8-89b2-f97bcdc030fa.png)

5.点击添加后，可以看到刚才添加的接收方式。
![](/images/2016-01-29-zabbix-install-and-usage/14ae8b53-f06c-4361-aeaf-13ee8e16d045.png)

6.进入“许可权”界面，将刚添加用户的用户类型配置为超级管理员，并点击保存。
![](/images/2016-01-29-zabbix-install-and-usage/e2454cdd-7ac8-429d-a909-141d428226e8.png)

7.点击更新后，可以看到刚才添加的用户，点击右上角的登出，使用刚添加的用户登录。
![](/images/2016-01-29-zabbix-install-and-usage/dd063971-06e9-4c92-a421-aeffeac743d1.png)

8.使用刚才创建的用户登录。
![](/images/2016-01-29-zabbix-install-and-usage/1ebb1d74-63bd-4200-9afc-dea31f171ac3.jpg)
 
9.可以看到，右下角出现了`连接为'qiao'`，说明登录成功。
![](/images/2016-01-29-zabbix-install-and-usage/5b718343-0a8d-4924-a01f-45d8160c4c10.png)

### 3.使用Zabbix监控第一个主机
Zabbix中主机的概念非常灵活，并不单单指一台物理机器，而是任何一个网络上的实体（物理的或者虚拟的）。比如一个物理机器，一个网络交换机，一个虚拟机或者一个应用。本实验中，我们将尝试监控虚拟机A的一些性能。

1.按照如下顺序，创建一台新的主机：组态（应翻译为配置） --> 主机 --> 创建主机
![](/images/2016-01-29-zabbix-install-and-usage/68697fc6-3e43-444d-a4d0-c852d3cc65b0.png)

2.填写主机的基本信息，主机名称、群组、IP地址为必填项。填写完成后点击添加。
![](/images/2016-01-29-zabbix-install-and-usage/762b7a6c-6d11-489c-83a1-f1c23aa9bf2b.png)
其中的几种介面含义如下：

- 代理接口：服务器通过“虚拟机A”上安装的agent程序抓取数据
- SNMP介面：服务器通过SNMP协议抓取数据。SNMP，即简单网络管理协议，支持各种硬件设施，不需要在被监控端安装任何agent
- JMX：服务器通过JMX方式获取数据。JMX（Java Management Extensions，即Java管理扩展），是一个为应用程序、设备、系统等植入管理功能的框架。
- IPMI：服务器通过IPMI方式获取数据。IPMI（Intelligent Platform Management Interface，即智能平台管理接口），是一种开放标准的硬件管理接口规格。

3.点击添加后，就可以看到刚才添加的主机了。
![](/images/2016-01-29-zabbix-install-and-usage/ca3d29cd-ef45-45ad-afcf-22fed8394cf5.png)

### 4.为主机添加监控项
监控项是Zabbix收集数据的基础，如果没有监控项，就不会收集数据，因为从哪里收集数据、收集什么数据等等，都是通过监控项来定义的。默认Zabbix将监控项翻译为“项目（item）”

1.点击新建虚拟机的“项目”。
![](/images/2016-01-29-zabbix-install-and-usage/182b8d41-8414-4fc3-b7a5-abd9a205d763.png)

2.点击“创建监控项”，为主机添加第一个监控项。
![](/images/2016-01-29-zabbix-install-and-usage/f741a344-4113-4449-98e0-241feeff22cf.png)

3.填写监控项的基本信息，其中名称、类型、键值、数据类型是必填项，其余保持默认即可。
![](/images/2016-01-29-zabbix-install-and-usage/5f7d94a6-0732-4e2a-9f5d-6045bd0c39cf.png)
图片中的配置解释

- 历史数据就是每次获取到的数据，那么趋势数据是什么呢？当你查看一周或者一月的图表，图表上看到的MAX/MIN/AVG/COUNT都是取自趋势数据，趋势数据一小时获取一次。
- 键值就是指定要从agent获取哪一项具内容，key允许传参，可以用[arg1,agr2]的形式将参数传递进去。
  - 本例中，`system.cpu.load`就指定了agent上监控cpu负载的一个键，这个键的第一个参数指定要监控哪个CPU，第二个参数指平均几分钟的负载，[all,avg1]即指的所有CPU的最近一分钟的负载。
  - 点击选择后，可以看到Zabbix默认自带了哪些key。如果使用英文界面，对每个key的作用及参数都会有详细的解释，但中文版的翻译很差，很难看懂。

4.添加完成后，会看到项目后面变为了(1)，并且右侧可用性中的[Z]变成了绿色。如果[Z]是红色，则可以将鼠标悬停在[Z]上面，查看具体的错误信息。
![](/images/2016-01-29-zabbix-install-and-usage/1a32e137-5e8b-4dba-af50-707f7efc39c5.png)

5.添加完成后，进入“检测中 --> 最新数据 --> 显示过滤条件 --> 选择 --> 虚拟机A --> 展开Other --> 查看CPU的图形”
![](/images/2016-01-29-zabbix-install-and-usage/af33e0b6-56c3-4164-94e7-61babbfa1ed1.png)

6.耐心等待一段时间，就可以看到抓取的数据了。
![](/images/2016-01-29-zabbix-install-and-usage/cc549002-1f5f-4e40-a5a3-fdbc55009576.png)

### 5.对监控项创建触发器
触发器的作用是，当某个监控项的值超出一定的范围，或者满足一定的条件时，就会变成“问题”状态。如果这个触发器绑定了某个发送告警邮件的动作，则一旦触发，就会自动发送邮件给相关人员。

1.进入“组态 --> 主机”，点击“虚拟机A”上的“触发器”。
![](/images/2016-01-29-zabbix-install-and-usage/db906942-05b4-4651-bde2-18c9ac944629.png)

2.点击右上角的“创建触发器”
![](/images/2016-01-29-zabbix-install-and-usage/908f0340-bc77-4c1f-9dea-17fbbcbb6b4d.png)

3.填写触发器的基本信息。
![](/images/2016-01-29-zabbix-install-and-usage/dbd3b5c5-c917-41ed-895c-95f59490f439.png)
表达式的语法如下：

~~~
{<server>:<key>.<function>(<parameter>)}<operator><constant>
~~~

- server：指定服务器。
- key：指定服务器的监控项，可以带参数。
- function：指定对哪些值进行判断，如最近几次数据的平均值，最新值和上一次的差距，一段时间内的最大值等
- parameter：function的参数，比如“最近一段周期内数据的平均值”，可以通过(#3)的方式指定最近3次，或者(300)的方式指定最近300秒。
- operator：操作符，大于，小于，等于，不等于之类的
- constant：常量值

>详细语法见[官方文档](https://www.zabbix.com/documentation/2.4/manual/config/triggers/expression)。

4.如果不使用表达式，可以点击“添加”按钮，使用图形界面生成表达式，其中的内容如下：
![](/images/2016-01-29-zabbix-install-and-usage/3e67746a-6db3-44dd-a98c-cc0800497cd7.png)

5.点击“插入”后，就可以看到刚才添加的触发器了。
![](/images/2016-01-29-zabbix-install-and-usage/06f6516d-8e83-4e75-a1c6-b4d7901367c7.png)

6.进入“监测中 --> 触发器”，查看触发器的状态，会看到有个“正常”一直在闪烁。
![](/images/2016-01-29-zabbix-install-and-usage/e1611471-9106-446a-9f17-19fdd9ce7fe9.png)

7.连接虚拟机A的终端，执行以下命令，等1两分钟后再次查看其状态，会发现触发器的状态变成了“问题”。

~~~
# cat /dev/urandom|md5sum
~~~

![](/images/2016-01-29-zabbix-install-and-usage/116f69d6-741d-4600-8e40-3e4a1ab80ecd.png)

>实验结束后，使用“Ctrl + C”，终止虚拟机A上的`# cat /dev/urandom|md5sum`命令。

### 6.创建被触发后发送邮件的动作

1.确保安装Zabbix的Server安装了postfix和mailx，并且打开postfix服务（如果是5.x的红帽系统，则需要安装sendmail，并且编译安装较新的mailx，直接yum安装的mailx版本太旧。）

~~~
# yum install -y mailx postfix
# chkconfig postfix on
# service postfix start
~~~

2.配置发送电子邮件的方式
![](/images/2016-01-29-zabbix-install-and-usage/ca1bef76-764b-49c6-9824-c901e1396e2f.png)

3.配置如下，使zabbix利用本地的postfix发送邮件。
![](/images/2016-01-29-zabbix-install-and-usage/af67bece-2fc1-4182-89e7-e61b55663736.png)

4.配置动作，进入“组态 --> 动作 --> 创建动作”
![](/images/2016-01-29-zabbix-install-and-usage/c090ab2c-b666-4e6a-b56b-878102f8f0a8.png)

5.填写动作的基本信息，如果勾选了“恢复信息”，则可以配置当问题消失时应该发送什么内容的告警。其中{XXX}代表的是宏变量，比如{TRIGGER.STATUS}就是指“触发器的状态”。
![](/images/2016-01-29-zabbix-install-and-usage/0a135a64-87d2-4e90-8bfc-6e3ca8117d21.png)

6.填写触发动作的条件
![](/images/2016-01-29-zabbix-install-and-usage/b96af3ef-3629-4298-a95d-2ff0043efba7.png)

7.添加完后，可以看到，当满足“机器不是在维修期”，并且“触发器是虚拟机A的CPU负载过高”，并且“触发器的值是问题”三个条件时，才会执行这个动作。
![](/images/2016-01-29-zabbix-install-and-usage/e8dfd3aa-6a4a-47ef-9e8e-a10423593049.png)

8.填写满足条件后做哪些操作。点击：操作 --> 新的
![](/images/2016-01-29-zabbix-install-and-usage/f5db06d6-28de-4dec-9c7e-b8c4e65e5a4b.png)

9.填写操作的时间、动作、对象等。
![](/images/2016-01-29-zabbix-install-and-usage/f6d75d0d-4baa-41b0-9369-11171b3f779b.png)

10.再次添加一次报警，这次是给管理员组发送报警信息。
![](/images/2016-01-29-zabbix-install-and-usage/a17366d9-106e-4bd4-ad22-7fe509e282a6.png)
步骤中的1、2、3分别代表第1次报警、第2次报警、第3次报警。如下设置则表示前三次发送给管理员用户组的所有用户，但只给“qiao”发送两次报警。这样的好处是，可以实现故障开始时发送邮件给值班运维，如果多少分钟还没处理好，则发送邮件给主管或者经理，甚至是老板。

11.点击添加，可以看到刚才设置的动作
![](/images/2016-01-29-zabbix-install-and-usage/0f63008e-6426-42e2-9dbc-0216bc25036a.png)

12.再次使用`# cat /dev/urandom |md5sum`命令模拟高负载，动作被触发后，可以看到收到的邮件。不过由于发件邮箱的域名为@localhost，所以会被自动识别为垃圾邮件。（如果仔细检查所有配置后，依然无法发送，则可以在服务器上使用mailq查看邮件队列，并尝试更换一下电信/联通等的DNS）
![](/images/2016-01-29-zabbix-install-and-usage/c63480a5-a9fc-4964-9b39-88d712315eb8.png)

## 五、功能进阶
>经过前面几个功能的学习，读者应该对Zabbix的界面和功能有了一个大致的了解。为了方便阅读，同时使教程更加精简，接下来将尽量减少截图的使用次数。

### 1.使用模板监控Linux主机
在文档前面的部分，已经介绍了如何添加主机并监控其中的一些监控项，以及在监控项的值过高时触发报警并发送邮件。然而，当面对大量机器，或者想同时添加大量监控内容时，显然不能像这样一个一个的慢慢添加。此时，就用到了Zabbix的模板功能。

- 点击“组态 --> 主机 --> 虚拟机A --> 模板”，进入主机模板配置界面
- 点击“连接新模板”右侧的选择
- 勾选“Template OS Linux”并点击“选择”
- 点击“添加”，此时在“连结的模板”中就会出现刚才刚添加的模板。右侧的“取消关联”指的是不再使主机应用此模板，而“取消关联并清理”则是在取消应用模板时，也删掉与之相关的监控项目、触发器等。
- 点击“更新”，此时在“虚拟机A”中的“项目”、“触发器”、“图形”、“探索”等都从`(0)`变成了其他数字。
- 点击“监测中 --> 最新数据”，在过滤器中将“虚拟机A”选中，此时可以看到出现了很多模板自带的监控项。展开任意一个监控项组，并点击最右侧的图形，则可以看到其最近的性能趋势。

可以看到，利用模板功能，可以轻易的添加大量监控项。

>在Zabbix中，用户可以自己创建模板，还可以将有联系的模板嵌套起来，比如定义了一个监控Linux主机的模板，又定义了一个监控MySQL的模板，就可以在MySQL模板中嵌套基础的Linux模板。

### 2.添加自定义脚本
有时候我们想让被监控端执行一个zabbix没有预定义的检测，zabbix的用户自定义参数功能提供了这个方法。我们可以在客户端配置文件zabbix_angentd.conf里面配置UserParameter，
下面我们一起来添加一个自定义脚本（用户自定义参数里指定的脚本由zabbix agent来执行，最大可以返回512KB的数据）：

1.在被监控端（虚拟机A）上调整agent的配置并使其生效。

~~~
# vim /etc/zabbix/zabbix_agentd.conf
UserParameter=test.add[*],echo $1 + $2|bc
# service zabbix-agent restart
~~~

可以看到，我们添加了一个将数字相加的命令，可以通过`test.add[10,20]`的方式传参。

>自定义脚本的语法如下：`UserParameter=key[*],command`。
其中`key`必须整个系统唯一，`[*]`指传进来的参数，对应后面命令的`$1`到`$9`，`command`为调用这个`key`时执行的命令，可以是一行命令或是一个脚本。

2.进入“组态 --> 主机”，为虚拟机A新建一个项目（监控项），并将键值填写为`test.add[10,20]`，并点击“添加”。

3.进入“监测中 --> 最新数据”，查看刚刚添加的监控项目，可以看到最新数据返回了30。

### 3.利用Zabbix监控MySQL数据库
>如果Zabbix的是由低版本升级到2.2的，可能不会有MySQL模板，此时就需要访问[官方wiki](https://zabbix.org/wiki/Zabbix_Templates/Official_Templates)下载“Template_App_MySQL-2.2.0.xml”，然后“组态 --> 模板 --> 汇入”，将下载的模板导入Zabbix。

从Zabbix 2.2开始，Zabbix官方已经支持了MySQL监控，但是MySQL监控默认是不可用的，需要经过额外的设置才可以使用。

1.进入“组态 --> 主机 --> 虚拟机A --> 模板”，为其添加一个新的模板“Template App MySQL”。

2.进入“组态 --> 主机 --> 虚拟机A的项目”，可以看到，添加模板后，新增了很多MySQL相关的监控项，但有些项目的“状态”都是“不支持的”。
因为Zabbix的MySQL模板里所需要的key值，Zabbix的agent端并非原生就支持，此时就需要在客户端上配置一下用户自定义参数，以满足模板中的key值。我们使用的2.4.7版本默认自带了相关的脚本，当然，也可以自己通过自己编写脚本来支持。

3.打开被监控端（虚拟机A）的终端，执行以下命令，可以看到Zabbix agent中自带了和MySQL相关的“userparameter”参数。

~~~
# ls /etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf
/etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf
# cat /etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf
……
~~~


4.查看上述配置文件的注释，发现需要在`/var/lib/zabbix`下配置`.my.cnf`文件，用以存储连接数据库的用户名密码等

~~~
# mkdir /var/lib/zabbix
# vim /var/lib/zabbix/.my.cnf
[mysql]
host = localhost
user = zabbix
password = zabbix
socket = /var/lib/mysql/mysql.sock
[mysqladmin]
host = localhost
user = zabbix
password = zabbix
socket = /var/lib/mysql/mysql.sock
# chown zabbix:zabbix /var/lib/zabbix/ -R
~~~

5.在上述脚本中，为保证安全，没有使用root用户，而是一个新的zabbix用户，因此需要在MySQL中单独为Zabbix创建一个低权限用户，用户名和密码都是“zabbix”。

~~~
# mysql -uroot -p123456
mysql> GRANT USAGE ON *.* TO 'zabbix'@'localhost' IDENTIFIED BY 'zabbix';
mysql> FLUSH PRIVILEGES;
~~~

6.配置完成后，重启zabbix-agent服务

~~~
# service zabbix-agent restart
~~~

7.**等待一段时间后**，进入“组态 --> 主机 --> 虚拟机A的项目”，可以看到，MySQL相关的监控项“状态”都变成了“已启用”，进入“监测中 --> 最新数据”，可以看到MySQL参数绘制的图形。

## 六、其他功能简介
作为一个“All in One”式的监控平台，Zabbix的功能多且强大，远非一篇实验文档所能包含的。更多的功能需要读者通过亲自实践、阅读官方文档、学习网络教程等方式渐渐发觉。在此次实验最后，将为读者以鸟瞰的方式展现Zabbix还有哪些强大的功能：

1.用户管理与报警媒介

- **认证**：多种认证方式（内置、HTTP、LADP）
- **用户**：权限管理、用户分组、定制接收告警（级别、时间、方式）
- **告警媒介**：多种报警途径（邮件/短信/微信/声音）
- **审计**：不同时间段内哪些用户操作过哪些资源，及其时间点、IP地址、细节等。

2.监控与图形展示

- **主机**：对主机分组、对不同的应用进行监控、支持宏变量、维修器自动停止报警、主机资产管理
- **监控项**：丰富的监控模式（agent/snmp/jmx/ssh/telnet/陷阱/监控日志/监控网页等），对监控项进行分组，允许传参，自动生成趋势数据，对返回值进行名称映射（返回1代表在线，0代表离线）等。
- **图片展示**：添加监控项时自动展示趋势图、支持一张图片多个来源
- **图表**：自定义仪表盘（一个页面摆放哪些图片）、为仪表盘添加动态元素（时钟等）、幻灯片的方式轮流播放多个仪表盘。
- **拓扑图**：绘制拓扑图，并将图中的内容和监控项、触发器等对应起来。
- **触发器**：灵活的触发条件、通过表达式判断、自动保存触发历史、触发器之间可以依赖（发现MySQL挂了本想告警，结果发现是因为主机挂了，就自动不报警）、报表（统计触发率等）
- **触发历史**：对每次发生的问题备注原因及解决方案、自动发现了主机时也会记录历史
- **动作**：支持自定义告警内容时使用变量、灵活的触发条件、触发后可以报警或执行远程命令、触发后不同时间段做出不同的动作。
- **模板**：对模板分组、模板之间相互嵌套、对主机批量应用模板、可以包含多种实体（监控项、触发器、动作等）。

3.高级功能

- **模块**：使用C语言开发自己的模块。
- **导入导出**：导入导出文件、模板、主机、拓扑图等等，支持XML格式及JSON格式
- **自动发现**：自动扫描一个IP范围内的主机并监控、自动扫描新添加的磁盘、支持正则表达式及表达式在线测试等。
- **API**：Zabbix提供丰富的接口，以便用户自定义界面等内容。
- **分布式**：Zabbix支持分布式监控，以方便适应不同的IT架构。

可以看到，Zabbix的功能繁多，其强大与灵活远远超出了目前流行的Cacti、Nagios等监控软件，是运维人员必学的开源产品。

关于Zabbix的介绍就到这里，本次实验到此结束，更多内容请参考下面的链接。

- [官方文档](https://www.zabbix.com/documentation)
- [官方论坛](https://www.zabbix.com/forum/)
- [运维生存时间系列教程](http://www.ttlsa.com/zabbix/)
