---
layout: post
title:  "Kmeans base on Cython"
author: "冥郡"
categories: [Python,C,Algorithm]
---

##  背景

Kmeans 是机器学习比较基础的算法，利用包调用比较容易，未来的算法可以很复杂，但基础都是一样简单的。算法层面尽量写得简单，将优化过程尽量写复杂。由于想使用Cython，先写C++部分，这里需要定义命名空间。头文件代码如下：

#### KMeans.h

```
#ifndef KMEANS
#define KMEANS

#include <iostream>
#include <Eigen/Dense>

using namespace std;
using namespace Eigen;

namespace cluster {
    class Kmeans{
    public:
        size_t n_cluster;
        int max_iter;
        double tol;
        int n_jobs;
        MatrixXd centers;
        vector<int> label;
        Kmeans();
        Kmeans(int n,int mi,double to,int jobs);
        ~Kmeans();
        void fit(const Eigen::Map<Eigen::MatrixXd> &mat);
        MatrixXd & center();
        vector<int> predict(const Eigen::Map<Eigen::MatrixXd> & data);
    };
}
#endif
```

这里使用Eigen库，也是为了将整个项目做的尽量复杂。其次，实现过程中使用一些c++11的特性，简化代码，实现KMeans的代码如下：

#### KMeans.cpp

```
#include "KMeans.h"
#include <iostream>
#include <Eigen/Dense>
#include "rand.h"
#include <functional>

using namespace std;
using namespace Eigen;

namespace cluster {
    Kmeans::Kmeans(){//参数借鉴sklearn
        n_cluster=2;
        max_iter=300;
        tol=0.0001;
        n_jobs=1;
    }
    Kmeans::Kmeans(int n,int mi,double to,int jobs){
        n_cluster=n;
        max_iter=mi;
        tol=to;
        n_jobs=jobs;
    }
    Kmeans::~Kmeans(){}
    void Kmeans::fit(const Eigen::Map<Eigen::MatrixXd> &input){
        centers.resize(n_cluster,input.rows());
        MatrixXd temp_centers(n_cluster,input.rows());
        MatrixXd data(input);//according to col
        vector<int>index=CreateRandomNums(data.rows(),n_cluster);
        //自己定义的随机数生成，随机初始化聚类中心
        for(size_t i=0;i<n_cluster;i++){
            temp_centers.col(i)=data.col(index[i]);
        }
        label=vector<int>(input.cols());
    
        int iter=0;
    
        while(//使用lambda函数，简化代码
            [=](){
                size_t tmp_loop=centers.cols();
                for(size_t i=0;i<tmp_loop;i++){
                    double diff=(centers.col(i)-temp_centers.col(i)).norm();
                    if(diff>tol)
                        return 1;
                }
                return 0;
            }() && max_iter>iter){
            centers=temp_centers;
            size_t tmp_loop2=data.cols();
            for(size_t i=0;i<tmp_loop2;i++){
                int minclass=0;
                double dis=9999999999999;
                double temp_dis;
                for(size_t j=0;j<n_cluster;j++){
                    temp_dis=[=](){ return (data.col(i)-centers.col(j)).norm();}();
                    //cout<<temp_dis<<endl;
                    if(temp_dis<dis){
                        dis=temp_dis;
                        minclass=j;
                    }
                }
                label[i]=minclass;
            }
            temp_centers=MatrixXd::Zero(n_cluster,input.rows());
            vector<int> count=vector<int>(n_cluster);

            tmp_loop2=input.cols();
            for(size_t i=0;i<tmp_loop2;i++){
                temp_centers.col(label[i])=(count[label[i]]*temp_centers.col(label[i])+data.col(i))/(count[label[i]]+1);
                count[label[i]]+=1;
            }
            iter+=1;
        }
        cout<<"final iterator times:"<<iter<<endl;
    }
    MatrixXd & Kmeans::center(){//返回聚类中心
        return centers;
    }
    vector<int> Kmeans::predict(const Eigen::Map<Eigen::MatrixXd> & data){
    	//根据聚类中心返回聚类结果
        size_t num=data.cols();
        cout<<num<<endl;
        vector<int> result=vector<int>(num);
        for(size_t i=0;i<num;i++){
            int minclass=0;
                double dis=9999999999999;
                double temp_dis;
                for(size_t j=0;j<n_cluster;j++){
                    temp_dis=[=](){ return (data.col(i)-centers.col(j)).norm();}();
                    //cout<<temp_dis<<endl;
                    if(temp_dis<dis){
                        dis=temp_dis;
                        minclass=j;
                    }
                }
                result[i]=minclass;
        }
        return result;
    }
}
```

下面是引用c++部分的关键，需要先写.pyx、.pxd文件，这是链接C代码的关键。

#### cluster.pxd

```
from libcpp.vector cimport vector
from eigency.core cimport *

cdef extern from "KMeans.cpp":
    pass

# Decalre the class with cdef
cdef extern from "KMeans.h" namespace "cluster":
    cdef cppclass Kmeans:
        Kmeans() except +
        Kmeans(int ,int ,double ,int) except +
        void fit(Map[MatrixXd] &)
        int n_cluster
        int max_iter
        double tol
        int n_jobs
        vector[int] label
        MatrixXd centers
        MatrixXd & center()
        vector[int] predict(Map[MatrixXd] &)

```

#### clu.pyx

```
# cython: language_level=3
# distutils: language = c++

from cluster cimport Kmeans
from libcpp.vector cimport vector

# 这里定义的函数才能作为接口被引用
cdef class KMeans:
    cdef Kmeans c_kmeans  # Hold a C++ instance which we're wrapping

    def __cinit__(self,n_cluster,max_iter,tol,n_jobs):
        self.c_kmeans = Kmeans(n_cluster,max_iter,tol,n_jobs)
    def fit(self, np.ndarray array):
        return self.c_kmeans.fit(Map[MatrixXd](array))

    def center(self):
        return ndarray(self.c_kmeans.center())

    def predict(self,np.ndarray array):
        return self.c_kmeans.predict(Map[MatrixXd](array))
```

下面是编译的关键文件，这里并没有写完整，而应该根据不同机器调整，原因是需要引入eigen库

#### setup.py

```
from distutils.core import setup,Extension
from Cython.Build import cythonize


setup(
	ext_modules=cythonize(Extension(
		name='cluster',
		version='0.0.1',
		sources=['clu.pyx'],
		language='c++',
		extra_compile_args=["-std=c++11"],
		include_dirs=["../eigen"],
		install_requires=['Cython>=0.2.15','eigency>=1.77'],
		packages=['little-try'],
		python_requires='>=3'
	))
)
```



