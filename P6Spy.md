#P6Spy实验记录
>注：本实验所有操作均在同一台主机上完成，系统版本为RHEL6.5，并假设读者已经安装好了MySQL数据库。
实验用到的文件在文章中都提到了原始下载地址。但也打包了一分并上传至网盘。[资源链接](http://pan.baidu.com/s/1jG6O5KU "密码：c7i9" )（密码悬停可见）

一、基础的TOMCAT环境搭建
===
####1. 安装`JDK`
从Oracle官网下载`jdk-8u65-linux-x64.rpm`，[网址][1]，并使用yum命令安装。
安装完成后，配置环境变量如下：
```
export JAVA_HOME=/usr/java/jdk1.8.0_65/jre
export PATH=$PATH:$JAVA_HOME/bin
```

<br />
####2. 安装`JDBC`驱动
从Oracle官网下载`mysql-connector-java-5.1.37.tar.gz`，[网址][2]，并解压。
然后，将其中的`mysql-connector-java-5.1.37-bin.jar`拷贝至`JAVA_HOME/lib`及`JAVA_HOME/jre/lib`路径下
安装完成后，在`JAVA_HOME`及`PATH`后面，配置环境变量如下：
```
export CLASSPATH=/usr/java/jdk1.8.0_65/lib/mysql-connector-java-5.1.37-bin.jar:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$CLASSPATH
```
>理论上JRE也可以，未测试过

<br />
####3. 安装Tomcat
直接`yum install -y tomcat*`，在rhel6.5上就会自动安装Tomcat6相关的包。
安装完成后，配置root用户的环境变量如下：
```
export CATALINA_HOME=/usr/share/tomcat6
export CATALINA_BASE=/usr/share/tomcat6
export PATH=$PATH:$CATALINA_HOME/bin
```

<br />
####4. 配置JNDI
配置JNDI的DataSource，编辑`$CATALINA_HOME/conf/context.xml`文件，在`<Context>`，`</Context>`标签中添加如下内容：
```
<Resource
  name="jdbc/tttt"
  auth="Container"
  type="javax.sql.DataSource"
  driverClassName="com.mysql.jdbc.Driver"
  url="jdbc:mysql://127.0.0.1:3306/mysql"
  username="root"
  password="123456"
  maxActive="100"
  maxIdle="30"
  maxWait="5000"
/>
```
配置完成后，通过`service tomcat6 start`开启Tomcat服务

<br />
####5. 创建JavaWeb的demo项目
进入`$CATALINA_HOME/webapps`路径下，创建文件夹`test`，并在`test`路径下创建`index.jsp`文件并编辑，其中内容如下：
```jsp
<%@page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="javax.naming.*"%>
<%@page import="javax.sql.DataSource"%>

<html>
<body>

<%
try {
  Context ctx = new InitialContext();
  Context envContext = (Context) ctx.lookup("java:/comp/env");
  DataSource ds = (DataSource) envContext.lookup("jdbc/test");
  Connection conn = ds.getConnection();
  out.println(conn);
  conn.close();
  }
catch (NamingException e) {
  e.printStackTrace();
  }
catch (SQLException e) {
  e.printStackTrace();
  }
%>
</body>
</html>
```
访问demo项目的url，如`http://192.168.18.131:8080/test/`，如果返回如下内容，则说明目前已经成功的使jsp程序访问到mysql数据库了。
```
org.apache.commons.dbcp.PoolableConnection@33eab061 
```

<br />
二、使用P6Spy
===
####1. 下载并部署P6Spy相关文件
下载P6Spy软件包`p6spy-2.1.4.tar.gz`并解压。[网址][3]，将`p6spy-2.1.4.jar`和`spy.properties`拷贝至`CATALINA_HOME/lib`路径下。
>经过试验，将`p6spy-2.1.4.jar`拷贝至`CLASSPATH`路径底下，或者`CATALINA_HOME/webapps/test/WEB-INF/lib`下，都没有作用。然而将`spy.properties`拷贝至`CATALINA_HOME/webapps/test/WEB-INF/classess`路径下是可以的。

<br />
####2. 配置P6Spy使其生效
编辑`$CATALINA_HOME/conf/context.xml`文件，修改其中Resource中的对数据源的定义
```XML
<Resource
  name="jdbc/test"
  auth="Container"
  type="javax.sql.DataSource"
  driverClassName="com.p6spy.engine.spy.P6SpyDriver" //这里改了
  url="jdbc:p6spy:mysql://127.0.0.1:3306/mysql"  //这里改了
  username="root"
  password="123456"
  maxActive="100"
  maxIdle="30"
  maxWait="5000"
/>
```

编辑`$CATALINA_HOME/lib/spy.properties`，添加如下配置：
```java
driverlist=com.mysql.jdbc.Driver
logfile = /tmp/spy.log  //这个文件是使用tomcat用户生成的，确保文件的位置对其有读写权限
```

<br />
####3. 在jsp中执行SQL语句
编辑demo项目中的index.jsp，修改代码使其执行一些SQL语句：
```
<%@page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="javax.naming.*"%>
<%@page import="javax.sql.DataSource"%>

<html>
<body>

<%
try {
  //连接数据库
  Context ctx = new InitialContext();
  Context envContext = (Context) ctx.lookup("java:/comp/env");
  DataSource ds = (DataSource) envContext.lookup("jdbc/test");
  Connection conn = ds.getConnection();
  out.println(conn);

  //执行SQL数据并获取结果
  Statement stmt = conn.createStatement();
  ResultSet rst = stmt.executeQuery("select user,host,password from user");

  //将结果输出到网页上
  while(rst.next())
  {
    out.println("<br><tr>");
    out.println("<td>"+rst.getString("user")+"</td>");
    out.println("<td>"+rst.getString("host")+"</td>");
    out.println("<td>"+rst.getString("password")+"</td>");
    out.println("</tr>");
  }

  //关闭数据库连接
  conn.close();
  }
catch (NamingException e) {
  out.println(e);
  e.printStackTrace();
  }
catch (SQLException e) {
  out.println(e);
  e.printStackTrace();
  }
%>
```
修改完后，再次访问项目的url，如`http://192.168.18.131:8080/test/`，如果出现类似下面的内容，则说明可以正常访问：
```
org.apache.commons.dbcp.PoolableConnection@7aa7cff1 
root % *6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9 //这个就是从表中抓取的内容
```

确保可以正常访问后。查看`/tmp/spy.log`文件，则可以看到刚才的SQL已经被记录了下来：
```
1448443164955|45|statement|connection 1|select user,host,password from user|
```
至此，实验结束。

<br />
三、概念解释
===
####1. 关于mvn
mvn即maven，如果知道ANT是什么，那么则非常容易理解。如果没听过类似的工具，那么撇开繁杂晦涩的专业术语，可以将maven简单的理解为一个“项目管理工具”。软件开发人员可以利用maven，简化大量操作，下面是网络上对maven的一些介绍，可以方便理解maven的作用：
- 我们每做一个项目，都要往lib目录扔很多jar包，spring的啊hibernate的啊apache的啊等等，这样就会导致很多包不知从哪个角落下载回来的，名称千奇百怪，版本也不明，项目多了以后还得自己复制来复制去，容易有多种不同版本的包混杂。maven最基本最重要的功能就是管理这些项目间的依赖关系，用一个xml来维护。如果你的工程要用spring，你就在maven的pom.xml里配一下spring的项目名称和版本号，要用其他的也一样。
得益于maven已经成为java世界的主流工具，绝大部分知名的项目都在maven中央仓库有标准名称，有各种不同的版本存在，你只要配下名称，配下版本号，maven就会自动从网上为你下载jar包并让你的工程依赖上，你的本地硬盘的仓库目录能看到井井有条的你用过的所有第三方项目的jar包和源代码，再也不用去下载那些来路不明的jar包再扔到工程里了，也不用担心写同一个项目的两个人一个用了3.0版的spring，一个用了2.5版的spring，以至搞出莫名其妙的问题
- 有了maven，我们不再需要往git或svn提交jar包，项目库的体积大大减小，下载项目变得快多了。而且只要提交一个pom.xml文件和你的代码，其他人自然也能下载到和你本地一模一样的第三方jar包，下过一次某个jar包以后，其他项目再用同一个jar包时，maven自然会使用本地仓库文件夹里存在的jar包，不需要再次下载，也不会出现很多个拷贝。
- maven的pom.xml任何一个主流ide工具都认识，都可以导入项目，你不用再操心你提交的.project和.settings文件因为别人的eclipse版本和你不同而导不进去，也不用再担心有人用的是别的ide认不得你的eclipse项目元文件，你不需要提交这些和开发工具有关的文件到服务器上了。
综合看来，maven的作用还是用来管理项目，协助开发的。对于java程序而言，发布之后的事情和maven并没有关系。

<br />
####2. 关于JNDI
JNDI并没有什么神秘的，作用就是把原本在程序中写死的链接单独提取出来，统一在一个配置文件中进行设置，并起个名字供程序引用。对于Oracle DBA，可以简单的将其理解为tnsname。
JNDI的作用最常用的是用来连接数据库，如果和JDBC进行比较，则最大的区别就是：JNDI把连接串、用户名密码、驱动程序等内容写在配置文件里、而JDBC将这些写在程序里。
>注意：配置JNDI的方式多种多样，包括多种全局配置、和多种私有配置。
一定要弄明白`java:comp`、`context.lookup()`等相关概念，以及配置文件的作用范围，否则程序无法正常访问JNDI。
在Tomcat中，JNDI只能通过网页访问jsp文件时才可以使用，或者在jsp文件中调用的test.class中的访问函数也可以，不能直接在test.java或test.class中访问。

<br />
####3. 关于P6Spy
P6Spy的作用是抓取JAVA程序对于SQL语句的调用。其实现原理是通过修改JNDI的配置文件，使其执行自己，自己将传过来的SQL进行处理后再扔给JDBC：
- 原本的执行顺序：Java程序中调用JNDI --> JNDI调用JDBC驱动 --> JDBC执行SQL
- 改后的执行顺序：Java程序中调用JNDI --> JNDI调用P6Spy --> P6Spy调用JDBC驱动 --> JDBC执行SQL

可以看到，原理非常的简单。配置起来也比较简单，只需要配两个文件即可：
- JNDI的配置文件：原来指向JDBC驱动，现在指向P6Spy。
- P6Spy的配置文件：指向JNDI原来指向的JDBC驱动。

[1]:http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html "Oracle官网"
[2]:http://dev.mysql.com/downloads/connector/j/ "MySQL官网"
[3]:http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22p6spy%22 "Maven Central"


<br /><br /><br /><br /><br />
