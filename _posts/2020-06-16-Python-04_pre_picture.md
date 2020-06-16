---
layout: post
title:  "一些乱七八糟的图片处理"
author: "冥郡"
categories: [Python]
---

## 背景

记录一些摸索图片处理过程中，看到的，和自己研究的图片预处理方法

## 图片移动

```
# 给定判断函数的批量图片移动
import shutil
import os
def movefile(source_folder,target_folder,condition):
    #source_folder 原文件夹,target_folder目标文件夹,condition 给定文件路径，判断是否满足移动的条件
    filelist=os.listdir(source_folder)
    for files in filelist:
        if files[0]==".":
            continue
        try:
            if condition(os.path.join(source_folder,files)):
                full_path=os.path.join(source_folder,files)
                des_path=os.path.join(target_folder,files)
                shutil.move(full_path,des_path)
        except:
            print(os.path.join(source_folder,files))
```

例如，在对手机图片进行分类时，最容易区分的是手机截屏，因为手机截屏的尺寸总是固定尺寸的。则若需要截屏图片可以用以下的例子：

```
from PIL import Image
def if_screenshot(file_path):
    try:
        im=Image.open(file_path)
        if im.size[0]==602 and im.size[1]==1304:
            return True
        else:
            return False
    except:
        print(file_path)
        return False
movefile(root,Jie_p,if_screenshot)
```

谈到对照片分类，除了利用图片尺寸、大小，这些比较显然的因素外(利用类似于以上的判断函数)，我更加关心的是利用颜色划分图片。眯起眼睛分辨图片的最佳方法是用颜色，但直接使用RGB合理吗？其实不合适。RGB的变化无法很好得将图片按颜色分割到每个区间，因为它有三个通道，并不是一种线性的关系。所以可以考虑新的划分方式，即利用HSV格式。RGB可以转化为HSV，先根据明暗关系，再根据颜色划分其实是更合理的，符合人眼的直觉。

这里我举一个取巧的例子，使得图片按照明暗关系和颜色划分的代码。这里只放一层，实际可以先按V(明暗)划分，再按照H(颜色)划分。取巧的点在于，对图片做分类的时候，并不是计算其完整的颜色作为分类，而是类似于hash的方法，采一些均匀的格子，然后统计格子颜色的分布，取其出现颜色最多的格子作为整个图片的代表位置，即可将图片按照明暗、颜色分开。

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
                count[math.floor(i/(256/classes))]+=1
        which_class=argmax(count)
        
        full_path=os.path.join(path,files)
        des_path=os.path.join(path,str(which_class),files)
        shutil.move(full_path,des_path)
    except:
        print(files)
```

## 图片切割与缩放

当图片特别充裕时，可以将图片切割为正方形，再resize训练所需要的tensor，但有些时候，我们数据并不是那么充足。为了能够充分利用所有数据，就不能大手大脚的切割图片。本人想了一种切割的方式(有可能不是第一个使用的人，也不一定是最好的方法)。

方法的想法很简单，对于长为Y宽为X的图片，假设他们的长宽不等，且有 $(k-1)X < Y< kX$，常理来说，这个图片若切分宽为X，那么应该切为k-1份，均匀舍弃中间的缝隙。但我们的前提是数据容量不足，那么应该充分利用中间共有的部分。将$kX-Y$均匀分为k-1份，作为公用部分，剩下的事也就是确认位置和resize而已。下面是批量转化不规则图片为正方形 256\*256 的代码：

```
import matplotlib.image as mpimg
from skimage import transform
import math
global count
count=0
aimpath="train/"
def decomp_img(img_name):
    global count
    img=mpimg.imread(img_name)
    (x,y,_)=img.shape
    if x==y:
        mpimg.imsave(aimpath+str(count)+".jpg",img)
        count+=1
    elif y>x:
        if y%x==0:
            n_piece=y//x
            for i in range(n_piece):
                cut_img=img[i*x:(i+1)*x,:,:]
                cut_img=transform.resize(cut_img,(256,256))
                mpimg.imsave(aimpath+str(count)+".png",cut_img)
                count+=1
        else:
            n_piece=math.ceil(y/x)
            n_cover=math.floor(y/x)
            d_cover_length=(x*n_piece-y)//n_cover
            top=0
            bot=x
            for i in range(n_piece):
                cut_img=img[:,top:bot,:]
                cut_img=transform.resize(cut_img,(256,256))
                mpimg.imsave(aimpath+str(count)+".png",cut_img)
                count+=1
                top=bot-d_cover_length
                bot=top+x
    else:
        if x%y==0:
            n_piece=x//y
            for i in range(n_piece):
                cut_img=img[:,i*y:(i+1)*y,:]
                cut_img=transform.resize(cut_img,(256,256))
                mpimg.imsave(aimpath+str(count)+".png",cut_img)
                count+=1
        else:
            n_piece=math.ceil(x/y)
            n_cover=math.floor(x/y)
            d_cover_length=(y*n_piece-x)//n_cover
            #print(n_cover)
            top=0
            bot=y
            for i in range(n_piece):
                cut_img=img[top:bot,:,:]
                cut_img=transform.resize(cut_img,(256,256))
                mpimg.imsave(aimpath+str(count)+".png",cut_img)
                count+=1
                top=bot-d_cover_length
                bot=top+y
path="picture"
filelist=os.listdir(path)
for files in filelist:
    if files[0]==".":
        continue
    if os.path.isdir(os.path.join(path,files)):
        continue
    decomp_img(os.path.join(path,files))
```






