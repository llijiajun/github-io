---
layout: post
title:  "整理提取图片始"
author: "冥郡"
categories: Python
---

##  背景

这一切要从我清理手机开始说起，最大占用手机空间的内容当然是手机上的照片。糟糕的是，将照片传到计算机之后，照片就完全乱了，虽然之前也是一团乱麻。想到之前想存图片当壁纸，存了几万张照片，这次可以总结一下，用python对图片做些简单的分类。所以总的说，目标是尽可能提取高清的图片作为壁纸，必要时需要按风格分一下类。其次是手机上不需要的图片且质量差的，或者是无法打开的照片都清理掉。下面是清理过程中的代码：

## 简单整理图片的思路与实现

### 准备部分

```
#与图像处理相关的包
from PIL import Image
import cv2
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
from pylab import *
#基础系统和数学包
import math
import numpy as np
import os
import shutil
```

### 分类

根据目的，考虑到照片的特性。下面是我对图片的大分类。对于每个大分类下，再进行特性分类，会方便许多。

>* 后缀为.heic的照片：这些图片属于iphone自带格式，利用python读图的函数，无法处理，但可以确定的是，这个格式一定是照片，所以可以单独存一类。
>* 截屏：截屏一般是转发信息，这部分图片一般都是我回消息的垃圾，提取出来可以集中销毁。
>* 太大的图片：大图一般意味着质量高，但这样的图片不会太多，可以集中处理。
>* 太小的图片：小图一般没什么用，这里主要目的是找合适的壁纸，小图当壁纸有损心情。
>* 照片：这里的照片是指满足某些特定尺寸的照片，一般在这个尺寸下得到的图片必然是照片。
>* 未处理的照片：不满足上述条件的照片是最多的，主要目的就是对这些图片分类。

对图片分类的事情和对垃圾分类特别像，说到底还是环境容纳不下了，我必须采取一些措施对他们回收利用，需要考虑的就是照片能做的事情。一方面是作为壁纸，壁纸分为两类，一类是横版，用于计算机；另一类是竖版用于手机壁纸。另一方面是给我当素材（画画、写网页的素材）。所以在大类之下需要考虑对每个大类的小分类是：横版或是竖版，根据颜色、亮度的不同级别细分在不同目录下。之后是部分代码，可以在基础上扩展。

### 粗糙的python代码——大分类

#### 移动文件

只需要改变输入的条件函数就可以移动整个目录下的文件，之后对每个分类只需要注意运行的顺序和条件的写法。

```
#将某个文件夹的图片移动到另一个文件夹，加上某个条件判断
def movefile(source_folder,target_folder,condition):
    filelist=os.listdir(source_folder)
    for files in filelist:
        if files[0]==".":
            continue
        if os.path.isdir(os.path.join(source_folder,files)):
        	continue
        #try:#有异常用来测试，整个过程中异常情况少，原因是图片不够复杂。
        if condition(os.path.join(source_folder,files)):
            full_path=os.path.join(source_folder,files)
            des_path=os.path.join(target_folder,files)
            shutil.move(full_path,des_path)
        #except:
        #    print(os.path.join(source_folder,files))
```

#### heic后缀图片

```
def if_heic(file_path):
    if ".heic" in file_path:
        return True
    else:
        return False
movefile(root,heic,if_heic)
```

#### 截屏图片

iphoneX的截屏图片都是602✖️1304，其他手机的不一定是这个，需要具体情况具体分析

```
def shortcuts(file_path):
    if ".heic" in file_path:
        return False
    try:
        im=Image.open(file_path)
        if im.size[0]==602 and im.size[1]==1304:
            return True
        else:
            return False
    except:
        print(file_path)
movefile(root,shortcut_path,shortcuts)
```
#### 大图片

```
def if_big(file_path):
    size=os.path.getsize(file_path)
    if size>=1048576:
        return True
    else:
        return False
movefile(root,big,if_big)
```

#### 4032✖️3024的照片

```
def if_zp(file_path):
    if ".heic" in file_path:
        return False
    try:
        im=Image.open(file_path)
        if (im.size[0]==4032 and im.size[1]==3024) or (im.size[0]==3024 and im.size[1]==4032):
            return True
        else:
            return False
    except:
        print(file_path)
movefile(root,zp,if_zp)
```

其他大分类的代码也是类似的，取决于读者的想象，这里就不全都放出来，以免限制了想象。

### 粗糙的python代码——小分类

对于小分类，我稍微想了一天，后来读到HSV颜色模型时豁然开朗，这正是我需要的东西。起初困窘于RGB颜色模型，按照颜色分类，从RGB的角度出发的确可行，代码则比较复杂，必须从三个维度划分颜色。起初的想法是，限制于RGB还不如直接使用聚类的方法。后来看到HSV模型，意识到颜色也可以是线性的。其次人肉眼关注的有时候并不只限于颜色类别，更多的是对明暗的辨别。明亮的图片更偏向于白色，反之则对应于黑暗，阴沉，这两种风格的差异可能是选择壁纸时更重要的指标。

使用HSV对颜色分类还需要考虑的问题是，一张图片有m✖️n个像素点，即使是划分好了区间，直接统计也是费时费力不靠谱的。所以我采取的方法是间隔一定距离取像素点作为图片的代表，这样可以大大简化时间。以下分别是对颜色分类和对明亮程度分类的代码：

#### 颜色小分类

```
filelist=os.listdir(path)
for files in filelist:
    if files[0]==".":
        continue
    if os.path.isdir(os.path.join(path,files)):
        continue
    try:
        img = mpimg.imread(os.path.join(path,files))
        HSV=cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        H, S, V = cv2.split(HSV)
        x=H.shape[0]
        y=H.shape[1]
        #间隔取点
        newH=H[np.arange(0,x,30)][:,np.arange(0,y,30)]
        #颜色区间计数
        count=[0 for i in range(classes)]
        for j in newH:
            for i in j:
                if(isinstance(i,int)):
                    count[math.floor(i/(180/classes))]+=1
                else:
                    count[math.floor(i/(360/classes))]+=1
        which_class=argmax(count)

        full_path=os.path.join(path,files)
        des_path=os.path.join(path,str(which_class),files)
        shutil.move(full_path,des_path)
    except:
        print(files)
```

#### 明亮度小分类

```
filelist=os.listdir(path)
for files in filelist:
    if files[0]==".":
        continue
    if os.path.isdir(os.path.join(path,files)):
        continue
    try:
        img = mpimg.imread(os.path.join(path,files))
        HSV=cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        H, S, V = cv2.split(HSV)
        x=V.shape[0]
        y=V.shape[1]
        newV=V[np.arange(0,x,30)][:,np.arange(0,y,30)]
        count=[0 for i in range(classes)]
        for j in newV:
            for i in j:
                if(isinstance(i,int)):
                    count[math.floor(i/(256/classes))]+=1
        which_class=argmax(count)
        
        full_path=os.path.join(path,files)
        des_path=os.path.join(path,str(which_class),files)
        shutil.move(full_path,des_path)
    except:
        print(files)
```

最后补充一点，毕竟最主要的目的是提取壁纸，最后附上筛选壁纸条件的代码。首先我计算机的分辨率比较高，壁纸需要在2000以上才足够清晰，其次是需要横图作为计算机墙纸，竖图作为手机壁纸。

#### 提取壁纸图片

```
path=root
two_thousand_up="2000plus"
two_thousand_minus="2000minus"
wall="wall"
phone="phone"
if not os.path.exists(path+"/"+wall+two_thousand_up):
    os.makedirs(path+"/"+wall+two_thousand_up)
if not os.path.exists(path+"/"+wall+two_thousand_minus):
    os.makedirs(path+"/"+wall+two_thousand_minus)
if not os.path.exists(path+"/"+phone+two_thousand_up):
    os.makedirs(path+"/"+phone+two_thousand_up)
if not os.path.exists(path+"/"+phone+two_thousand_minus):
    os.makedirs(path+"/"+phone+two_thousand_minus)

filelist=os.listdir(path)
for files in filelist:
    if files[0]==".":
        continue
    if os.path.isdir(os.path.join(path,files)):
        continue
    try:
        im=Image.open(os.path.join(path,files))
        if (im.size[0]>=2000 and im.size[1]>=2000) and im.size[0]>im.size[1]:
            shutil.move(os.path.join(path,files),os.path.join(path,wall+two_thousand_up,files))
        elif (im.size[0]>=2000 and im.size[1]>=2000) and im.size[0]<=im.size[1]:
            shutil.move(os.path.join(path,files),os.path.join(path,phone+two_thousand_up,files))
        elif im.size[0]>im.size[1]:
            shutil.move(os.path.join(path,files),os.path.join(path,wall+two_thousand_minus,files))
        elif im.size[0]<=im.size[1]:
            shutil.move(os.path.join(path,files),os.path.join(path,phone+two_thousand_minus,files))
    except:
        print(files)
```

### 小结

整个过程主要是为了熟悉python提取图片的流程。细节还有许多可以加强的地方。比较遗憾的是，最后还是没有用上利用无监督算法等，对图片做进一步划分。为了保护隐私，这里没有放我整理之后的图片。对于小分类，的确可以按照颜色和明亮程度很好的划分出我需要的图片。但并不能划分出我图片中最大的两个类别：人像和画。这一点是可以由编写分类算法来实现的。等未来有时间进一步研究时，将再写sort_img2。

上半学期做了一些关于图片分类的大作业，在实际对我自己的照片分类时，我有些许对当时做的不恰当的点进行了反思。很大程度上，这些简单的分类手段已经足以细化图片，而当时简单地将所有图片整合为一个维度，就直接开始增强训练，这点现在想想是不太妥当的。