---
layout: home
---

<div class="index-content technology">
    <div class="section">
        <ul class="artical-cate">
            <li class="on"><a href="/technology"><span>Technology</span></a></li>
            <li><a href="/life"><span>Life</span></a></li>
            <li><a href="/hobbies"><span>Hobbies</span></a></li>
            <li><a href="/thinking"><span>Thinking</span></a></li>
            <li><a href="/aboutme"><span>AboutMe</span></a></li>
        </ul>

        <div class="cate-bar"><span id="cateBar"></span></div>

        <ul class="artical-list">
        {% for post in site.categories.technology %}
            <li>
                <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
                <div class="title-desc">{{ post.description }}</div>
            </li>
        {% endfor %}
        </ul>
    </div>
    <div class="aside">
    </div>
</div>
