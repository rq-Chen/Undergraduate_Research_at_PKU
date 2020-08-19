# Word Embedding Strategies & RNN Decoders for Sentiment Classification 

## Comparison of Decoders

`trainLSTM.py` - Train LSTM

`trainGRU.py` - Train GRU

`trainRNN.py` - Train SimpleRNN

`cmpParam.py` - Hyperparameter tuning

`cmpRNN.py` - Compare the performance of three decoders

## Comparison of Encoders

`trainSG.py` - Train Skip-gram word vectors and classify by LSTM

`trainCBOW.py` - Train CBOW word vectors and classify by LSTM

`cmpEmbed` - Compare the performance of three embedding strategies

## File Naming

"LR", "BS", "DO" represent learning rate、batch size and dropout repectively.

`/Compare` contains the comparison result for decoders and `/Embedding` for encoders.

`Report.pdf` summarizes the result (in Chinese).