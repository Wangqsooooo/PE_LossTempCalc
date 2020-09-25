# 源码管理

## 基于现有拓扑加入新的调制方法

新的调制方法可扩充在'Waves'类中，该类中已有针对半桥结构的SPWM调制、SVM调制以及针对三电平有源中点钳位电路（ANPC）的单电流通路调制（SingleCurrentPath）、双电流通路调制（DualCurrentPath）调制，若想加入新的调制方法，可参考这些已有的调制方法。

同时为了使得源程序能够识别出新加入的调制方法，还需要在以下几个地方进行修改：

1. ModulationType类，需要在其中加入新增加的调制方法的名字
2. TopologyType类，需要在`isAvailableModulation`函数中在对应的拓扑下加入新的调制方法的名字，同时在`printModulation`函数中对应的拓扑下加入新的调制方法的名字。如何加入可以参考现有的一些代码
3. Waves类，在其构造函数的switch-case块中，需要加入对应的代码，这样就可以在构造的时候完成对开关器件驱动信号的配置

当然上述三个修改点都是可选的，如果不进行修改的话只是不能在构造Waves类的同时完成对驱动的信号的配置，在之后还是可以进行配置的，详情可以参见[main_TwoModuleCHB.m](..\Main\main_TwoModuleCHB.m)程序。

写的时候需要注意Waves类中的一个参数'ControlSet'，这个参数代表的是驱动信号是否已经配置好的标志位，当该参数的所有位置均为1时即代表所有开关器件的驱动信号均已配置完毕，否则无法进行下一步的运算。该参数在类的外部无法访问，其置1的操作是在类的内部完成的，不要试图在外部修改该参数。在类的外部配置了驱动信号后，需要发出一个通知（notify），告知Waves类驱动信号已经进行了更新，请根据现有情况更新'ControlSet'参数的值，详情可以参见[main_ThreeLevelANPC_withDeviceHybrid](..\Main\main_ThreeLevelANPC_withDeviceHybrid.m)程序。

## 加入新的拓扑

实际上源程序并不是依靠识别特定的拓扑来完成计算的，这其实是一个历史遗留问题。一开始写的时候是根据特定的拓扑（如两电平和三电平电路）以及特定的调制方法来确定损耗计算方法的。在之后的改进中，这个工具的功能已经不再局限于计算特定拓扑的特定调制方法，而是根据器件连接关系自动寻找电流通路，从而完成损耗计算及结温计算（对于其他电路的损耗及结温计算结果还没有得到仿真的验证）。因此加入新的拓扑和新的调制方法都是锦上添花的东西，实际上对新的拓扑进行计算时不需要对源程序进行任何的修改，实际上Main文件夹中也给了很多没有定义的拓扑类型的计算，如[main_TwoModuleCHB.m](..\Main\main_TwoModuleCHB.m)。

在库中加入新的拓扑后经过运算，Topology类可以识别出该拓扑，并给出Order参数，该参数代表输入拓扑与库中标准拓扑开关器件对应的情况，[test1_ThreeLevel_ANPC](..\material\text\test1_ThreeLevel_ANPC.txt)文本文件定义了一个节点完全相同，但是开关器件编号不同的三电平情况，[test2_ThreeLevel_ANPC](..\material\text\test2_ThreeLevel_ANPC.txt)文本文件定义了节点编号不同的情况，这些情况都能够被识别出来，并在Topoloy类的Type以及Order参数中体现出来。

加入新的拓扑需要以下几个地方进行修改：

1. 给出一个标准的拓扑输入文件，为txt格式，具体参照Material\text文件夹下的其他文件
2. TopologyType类，将新的拓扑名称加入enumeration列表中
3. TopologyType类，需要在`DefinedTopologyPathAndOrder`函数中接入新的拓扑名称以及开关器件的次序，这个次序需要在编写该拓扑的调制方法时特别注意
4. TopologyType类，需要在`isDefinedTopologyGraph`函数新加入一部分代码，这一部分的代码是用来判断图是否形成同构用的



