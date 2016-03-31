---
layout: post
title: 快速搭建一个web服务器
description: 适合对开发和web一窍不通的运维人员，分分钟让你明白前端后台是怎么交互的
category: technology
tags: bootstrap,python,flask
---

## 快速搭建一个web服务器

>
- Document Version: 1.2
- OS Environment: RHEL6.5

## 一、Flask框架

### 1，Flask简介

#### 什么是框架？

很多开发人员在听说框架时，往往抱着一种畏惧心理，认为这是一种很高大上的、很复杂的新技术，下意识的认为这门技术的学习成本太高，于是躲的远远的。

关于框架的定义，并没有一个准确清晰通用的答案。实际上，对我们来讲，可以将其简单的类比为Word模板、PPT模板。

就像套用模板后，你可以方便的直接引用模板自带的背景、字体、颜色、布局等等，同样在软件开发领域，框架也可以使我们在开发一个新的产品时，极为方便的调用很多现成的功能、模块，大量的节省了重复造轮子的时间，也极大的提高了开发效率。

所以框架的学习成本并不高——本来就是用来方便大家的嘛，所以一般上什么新项目时，推荐找一下有没有现成的产品或者框架，如果有合适的，将会节省大量的时间。

然而这并非意味着框架就是万能的，对于中小型的产品来讲，它确实能起到提高效率的作用，然而一旦到了大型或者超大型项目，由于框架屏蔽了很多底层的东西，过于依赖框架反而会限制产品的发展，此时则需要去深入探索框架及语言的底层原理，甚至对其做一些二次开发。这一点在较新的框架中较为明显，对于成熟、稳定的框架，这方面的顾虑则要少很多。

#### Flask是什么？

Flask是一个轻量级的Web应用框架, 使用Python编写。Python的web框架有很多，最常用的是Django。

Django是一个使用广泛、较为成熟稳定的web框架，正式项目中，也比较推荐用Django来做。和Django的大而全比起来，Flask则显得更为小巧灵活，只需极少的配置即可快速搭建一个简单的web应用。

由于此实验的目的只是为了体验web开发，理解前端后台的交互过程，故选用Flask框架完成此项目。

### 2，Flask安装

配置好本地yum源后，将开发包的所有软件都装齐

~~~
yum -y groupinstall "Development Tools"
~~~

访问Flask的[下载网址](https://pypi.python.org/pypi/Flask)，下载最新版（目前是0.10.1）的安装文件。

下载并上传到Linux服务器上后，解压并安装Flask（需联网，Flask需要依赖python其他的一些包，如果没装过则会联网下载）

~~~
tar -xf Flask-0.10.1.tar.gz
cd Flask-0.10.1/
python setup.py install
~~~

在python中导入flask的包，如果没有报错，则说明安装成功

~~~
python ## 进入Python交互界面
>>> import flask ## 在Python交互界面中，导入flask包，如果没有报错，则说明Flask安装好了
~~~

### 3，Flask使用

#### 快速入门

下面根据官方文档的快速入门，做一个小例子

一个最小的 Flask 应用看起来会是这样的：

~~~
from flask import Flask
app = Flask(__name__)
 
@app.route('/')
def hello_world():
    return 'Hello World!'
 
if __name__ == '__main__':
    app.run(host='0.0.0.0')
~~~

把它保存为 server.py （或是类似的），然后用 Python 解释器来运行。 确保你的应用文件名不是 flask.py ，因为这将与 Flask 本身冲突。

~~~
[root@rhel6 webdemo]## python server.py
 * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
~~~

打开浏览器，访问你Linux机器的IP地址加5000端口，就可以看到刚才的结果了。

假设我的IP地址为`192.168.18.132`，则访问`http://127.0.0.1:5000/`

#### 网址路由

在一开始的小例子中，我们可以看到一个`@app.route('/')`，这种用法是使用的Python的装饰器。装饰器的作用在于执行一个方法前，对这个方法做一些额外的操作，比如在文件中记录一下这次调用，或者在方法前后多打印一些提示信息等。

读者可以不用理会装饰器的具体作用，只要理解成这是Flask种的固定用法即可。

其中`@app.route('/')`里面的`/`，是指的通过浏览器访问页面时的地址，这个可以随便填写，例如我们将其写成`/chinaitsoft`试试：

~~~
# coding:utf-8
from flask import Flask
app = Flask(__name__)
 
@app.route('/chinaitsoft')  ## 在这里更改对哪个网址做出反应
def index():
    return '这里是北京中研软科技有限公司。' ## 注意，因为使用了中文，需要在第一行添加"# coding:utf-8"来避免乱码
 
if __name__ == '__main__':
    app.run(host='0.0.0.0')
~~~

再次`python server.py`运行服务器后，通过浏览器访问`http://192.168.18.132:5000/chinaitsoft`，就可以看到刚才返回的内容了。

~~~
[root@rhel6 webdemo]## curl http://192.168.18.132:5000/chinaitsoft ## 在命令行中访问网址
这里是北京中研软科技有限公司。
~~~

#### 页面渲染

透过前面的实验，我们了解了如何对特定的网址进行反应，但反应的结果只是简单的一串字符。如果想返回一个html页面，应该怎么办呢？

首先，我们在server.py所在的路径中，新建一个templates文件夹，然后在这个文件夹中新建一个html文件：

~~~
├── server.py
└── templates
    └── index.html
~~~

更改server.py的内容如下

~~~
from flask import Flask
from flask import render_template  # 新导入了Flask模块中的一个方法
app = Flask(__name__)

@app.route('/')  # 访问根路径
def index():
    return render_template('index.html')  # Flask自动从templates文件夹下寻找叫index.html的网页，并返回给浏览器。

if __name__ == '__main__':
    # 启动服务，并开启debug模式。
    app.run(host='0.0.0.0',debug=True)  # debug模式可以在改动文件后自动重启服务器，并且提示遇到的错误。
~~~

html文件的内容如下：

~~~
[root@rhel6 webtmp]# cat templates/index.html
<p style="color:white;text-align:center;background-color:#333;">this is a html web page!</p>
~~~

**内容解释：**

- `<p></p>`：是HTML语言中的标签，用于表示一个段落，标签中间可以填写任意的文字
- `style`：定义了行内的CSS语言，用于描述`<p></p>`标签中的文字用什么格式来展示
- `color:white`：表示文字的颜色为白色
- `text-align:center`：表示文字居中对齐
- `background-color:#333`：表示段落的背景颜色为灰黑色

操作完成后，重新运行server.py，并访问`http://192.168.18.132:5000`，可以看到更改后的网页如下：
 
<p style="color:white;text-align:center;background-color:#333;">this is a html web page!</p>

### 4，向HTML网页传递变量

我们虽然成功的展示了一个页面，但这个页面的内容都是静态的，如果想要在Python中，将经过程序的运算得到的结果传给网页，应该怎么做呢？下面我们就通过一个小例子来实现这个功能。

更改server.py的内容如下：

~~~
from flask import Flask
from flask import render_template
app = Flask(__name__)

@app.route('/')
def index():
    string = 'get string here!'
    return render_template('index.html',my_var=string)  # 向页面中传递参数，并向浏览器返回这个页面

if __name__ == '__main__':
    app.run(host='0.0.0.0',debug=True)
~~~

html文件的内容如下：

~~~
[root@rhel6 webtmp]# cat templates/index.html
<p style="color:white;text-align:center;background-color:#333;">{ { my_var|safe } }</p>
~~~

**内容解释：**

- `{ { } }`：是一个容器，在里面定义变量，两个括号中间是没有空格的，此处是为了方便博客展示才加上的。
- `my_var`：是一个变量，用于接收Flask传递进来的内容
- `|`：管道符，用于连接后面的命令
- `safe`：表示以安全模式过滤前面的内容如把`"<p></p>"`这种字符串解析成`<p></p>`标签，没看出来区别？注意双引号。

操作完成后，重新运行server.py，并访问`http://192.168.18.132:5000`，可以看到变量的内容已经传到给了网页。更改后的网页如下：
 
<p style="color:white;text-align:center;background-color:#333;">get string here!</p>

#### Flask的其他资料

关于Flask的更多资料，比如通过网址传递参数等方法，请参考其官方文档：

[中文文档地址](http://docs.jinkan.org/docs/flask/)
[英文文档地址](http://flask.pocoo.org/docs/0.10/)

## 二、前端展示

### 1，HTML语言

HTML语言是一种标记语言，一个最简单的html文档格式应该如下：

~~~
<!DOCTYPE html>  # 文档类型声明，告诉浏览器这是个html文档
<html>  # 文档开始标记
     <body>  # 内容开始标记
        <p>This is my first paragraph.</p>  # 用于展示一段文字的标记
        <a href="http://www.chinaitsoft.com">this is a link</a>  # 用于展示一段文字的标记
    </body>  # 内容结束标记
 </html>  # 文档结束标记
~~~

其中的`<p></p>`我们已经知道了是用来展示一个段落的内容，`<a></a>`则是展示一个超链接。

在`<a></a>`中，前面的`<a>`中可以加上`href="www.chinaitsoft.com"`，来表现这个链接的地址，`<a></a>`中间则写上链接的文字。

`<a href="http://www.chinaitsoft.com">this is a link</a>`在浏览器中的展示如下：<a href="http://www.chinaitsoft.com">this is a link</a>

>链接指定的地址可以是一个完整的链接，如`http://www.chinaitsoft.com`，也可以是一个相对于本站根路径的相对路径，如`/iostat`

### 2，一个完整的html页面

如果我们不想每次访问一个url时都要手动去写，就可以在页面中定义几个链接，直接点击这些链接即可访问相关的网址，举例如下：

~~~
<!DOCTYPE html>
<html>
     <body>
        <a href="/iostat"> show_iostat </a>  # 访问iostat链接
        <a href="/uptime"> show_uptime </a>  # 访问uptime链接
        <p>{ { my_var|safe } }</p>  # 从Flask中接收变量并输出为一个段落
    </body>  # 内容结束标记
 </html>  # 文档结束标记
~~~

### 3，扩展

如果想做出漂亮的网页，不但要学习html语言，还要对css有所了解，在对css有了一定基础的情况下，再套用一些现成的前端框架，如bootstrap，或是直接使用在线其布局系统，方便快速的做出一个网页。

CSS：方便的统一指定页面的展示方式（颜色、大小、动画等）

BootStrap：一套基于CSS的框架，可以理解为皮肤

JS：使页面动起来（[小例子](http://www.tripwiremagazine.com/wp-content/uploads/images/stories/Articles/9_Funniest_JavaScript_effects/You%20must%20love%20me.html)）

由于此教程的目的不在于此，故前端相关内容请凭兴趣自学。

## 三、Python后台处理

### 1，执行系统命令

如何在python中执行系统命令呢——使用os模块里的popen方法。

~~~
>>> from os import popen
>>> result = popen('uptime')
>>> output = result.readlines()
>>> print output
[' 14:44:59 up 14 days,  8:25,  2 users,  load average: 0.00, 0.00, 0.00\n']
~~~

popen方法会返回执行命令后的输出，使用readlines()将其内容全部读出，就会返回一个list列表，然后相对这个列表做什么都随自己了就。

### 2，访问数据库

如何通过python访问mysql数据库呢？这时就用到了`MySQL-python`这个模块。

使用`pip install MySQL-python`可以安装这个模块。rhel6.5的镜像盘中也有这个模块的rpm包，这意味着如果你使用的是rhel6.5自带的python，直接使用`yum install MySQL-python`也可以得到版本相符的模块。安装完成后，在python中`import MySQLdb`不报错，则说明安装成功了。

下面将演示python如何通过MySQLdb模块访问MySQL数据库：

~~~
>>> import MySQLdb  # 导入MySQLdb模块
>>> conn=MySQLdb.connect(host="localhost",user="root",passwd="123456",db="mysql",charset="utf8")  # 配置相关参数，建立到数据库的链接
>>> cursor = conn.cursor()  # 在这个链接下生成一个游标
>>> cursor.execute('select host,user,password from user')  # 使用这个游标执行一个sql语句，注意不要有分号
3L
>>> datas = cursor.fetchall()  # 使游标遍历sql语句的执行结果
>>> print datas  # 将执行结果打印出来
((u'%', u'wordpress', u'*C260A4F79FA905AF65142FFE0B9A14FE0E1519CC'), (u'%', u'root', u'*6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9'), (u'%', u'zabbix', u'*DEEF4D7D88CD046ECA02A80393B7780A63E7E789'))
>>> cursor.close()  # 关闭打开的游标
>>> conn.close()  # 关闭打开的链接
~~~

### 3，一个较为完整的小例子

有了上面的基础，我们来做一个完整的例子

html页面的内容：

~~~
[root@rhel6 webtmp]# cat templates/index.html
<!DOCTYPE html>
<html>
     <body>
        <a href="/iostat"> show_iostat </a>
        <a href="/uptime"> show_uptime </a>
        <p>{ { my_var|safe } }</p>
    </body>
</html>
~~~

server文件的内容：

~~~
[root@rhel6 webtmp]# cat server.py
# coding:utf-8
from flask import Flask
from flask import render_template
from os import popen

app = Flask(__name__)

@app.route('/')
@app.route('/iostat')  # 这里指定了两个url，表示访问任意一个网址都会用这个方法来响应。
def iostat():
    string = '<br>'.join(popen('iostat').readlines())
    return render_template('index.html',my_var=string)

@app.route('/uptime')
def uptime():
    string = '<br>'.join(popen('uptime').readlines())
    return render_template('index.html',my_var=string)

if __name__ == '__main__':
    app.run(host='0.0.0.0',debug=True)
~~~

重启服务器并打开页面后，可以看到如下内容：

><a href="/iostat"> show_iostat </a>
        <a href="/uptime"> show_uptime </a>
><p>Linux 2.6.32-431.el6.x86_64 (rhel6.5b)     03/24/2016     _x86_64_    (1 CPU)
<br>avg-cpu:  %user   %nice %system %iowait  %steal   %idle
<br>           1.07    0.00    0.90    1.02    0.00   97.00
<br>Device:            tps   Blk_read/s   Blk_wrtn/s   Blk_read   Blk_wrtn
<br>sda              13.81         4.10       250.87    5045242  308788036
<br>scd0              0.00         0.11         0.00     138936          0
></p>

### 4，完整DEMO的地址

如果想得到一个页面漂亮，功能完善的DEMO，请访问WebDemo在github上的repo地址。[点击跳转](https://github.com/oraant/webdemo)

WebDemo的repo里面有着调用系统命令，向命令传递参数、访问数据库、调用BootStrap框架等内容的源码，读者可以直接观看源码，或者完整拷贝下整个项目，只要配置好了环境，那这个项目是可以直接通过`python server.py`来使用的。

## 四、其他web服务器简述

如今，成熟的web服务器有很多，除了Django、Flask这类基于某种语言的，较为轻量的产品外，还有Apache这种老牌的服务器。

在常见的LAMP环境中的P，一般来讲都是指的php，利用php来做这个项目，则要简单很多：经过简单的配置，浏览器可以通过访问`http://x.x.x.x/index.php`  这种方式，来访问一个动态脚本，方便的和后台进行交互。

其他还有一些适合于大型项目重量级的服务器，如Tomcat、WebLogic等，相对于之前的，这种服务器一般学习成本高出很多，不建议初学者学习。
