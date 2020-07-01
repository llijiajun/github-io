---
layout: post
title:  "读取Graph数据的代码"
author: "冥郡"
categories: [C,Python]
---

## 背景

记录读图的一些代码，由于图一般都会储存为稀疏矩阵的形式，否则大图根本无法储存，所以最终返回的都是稀疏矩阵，比较节约空间的是csr matrix。

## CSR Matrix and COO Matrix

COO Matrix 比较容易理解。从图的角度出发其实就是将每条边都存下来。

要想压缩数据，无论什么方法，其实都是在合并同类项。COO Matrix有什么好压缩的呢？单个顶点出发的边可以将它们的顶点合并，用一个数表示。最终也就得到了CSR Matrix。

CSR Matrix可以理解为，先对顶点都预先编号为0-V，那么只需要记录一下，每个顶点有多少出边和出边的位置即可。CSR Matrix由三个数组构成：offsets、edges、values。有时候，offsets 在某些函数输入会拆分为 PointerB 和 PointE，意思也很简单，即某顶点开始时，已经记录边的数量，和此顶点结束时，会记录边的数量。至于 edges 记录的是边的终点，values 记录边的权重。对 CSR Matrix理解的程度决定了，你能对矩阵计算所沉浸的深度，利用CSR进行图的访问和计算是非常方便的，要使有机会写到 MKL 矩阵运算库的解析，会有更深的理解。

## Python 部分

### Mat

Mat 格式的文件通常是由 Matlab 生成，读取可以使用scipy.io.loadmat，在图数据中，似乎是约定好的，变量"network"代表图的邻接矩阵，"group"代表的是图结点的分类，所以读取代码为：
```
# 读取图的邻接矩阵
def load_matrix(file,variable_name="network"):
    return scipy.io.loadmat(file)[variable_name]
# 读取图的结点的标签
def load_label(file,variable_name="group"):
    return scipy.io.loadmat(file)[variable_name]
```

值得注意的是，这里的标签需要根据对应的训练模型调整为合理的形式。例如多分类任务sklearn和logreg应该是有区别的。


### edgelist


### GCN datasets


## C,C++

### edgelist