# 不同词向量编码与解码器结构在IMDb数据集上的表现分析
## 解码器比较

`trainLSTM.py` - 训练LSTM

`trainGRU.py` - 训练GRU

`trainRNN.py` - 训练SimpleRNN

`cmpParam.py` - 比较不同超参数设置

`cmpRNN.py` - 比较三个神经网络分类器的表现

## 编码器比较

`trainSG.py` - 训练Skip-gram词向量并用LSTM分类

`trainCBOW.py` - 训练CBOW词向量并用LSTM分类

`cmpEmbed` - 比较不同词向量编码方式的表现


## 文件命名

“LR”“BS”“DO”分别表示学习率、Batch size、Dropout。

Compare文件夹下是解码器比较，Embedding文件夹下是编码器比较。