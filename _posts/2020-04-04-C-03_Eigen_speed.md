---
title: 如何提高Eigen效率
author: 冥郡
layout: post
categories: [C,algorithm1]
---

## 背景

为了加速c++的矩阵计算，MKL是比较好的方案，但MKL写代码实在不太友好，其次容易出bug。MKL计算矩阵乘法速度十分快，但其实对代码优化到极致之后，Eigen矩阵计算速度是可以和MKL媲美的。由此，我也对CMake进行了一定的研究。我主要是从知乎[Eigen的速度为什么这么快？](https://www.zhihu.com/question/28571059)中学习到的。我仅作为搬运工，并加入一些自己的实际探索。

## 优化手段

从知乎中总结：

> 1. 矩阵乘法，若等式左边的变量与右式相乘变量没有关系，则可以使用 A.noalias() 替代 A

> 2. -mavx 和 -mfma 两个参数， 若对g++ 编译而言， -O3 可以在编译上优化

> 3. 写 CMakefile 并链接矩阵加速库 MKL 、 Blas 、Lapack 。

这些都是比较容易实现达到的优化方法。主要讲一下利用MKL优化。

## 参考资料

[1] <https://www.zhihu.com/question/28571059>