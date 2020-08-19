"""cmpRNN.py - Compare different RNNs' performance on IMDb dataset

Author: Ruiqi Chen
Version: 03/23/2020

This script aims at comparing different RNN's performance given the
same word embedding strategies on the IMDb sentiment dataset.

Model Structures:
    LSTM: 64-to-108, 30% dropout
    GRU: 64-to-128, 20% dropout
    RNN: 64-to-200-to-80, 10% dropout

Training Parameters:
    LSTM: batch size = 128, initial learning rate = 4e-5
    GRU: batch size = 128, initial learning rate = 2e-5
    RNN: batch size = 64, initial learning rate = 7e-5

When comparing different models, we used 5000-to-64 dense encoding
    and a softmax classifier. All models have a similar number of 
    parameters (about 75k).
    

"""

from pickle import load
import matplotlib.pyplot as plt
import numpy as np

# --------------- Parameters --------------- #

# Illustration
savePath = './Compare/'
accLim = [0.5, 0.9]  # Plot limit for accuracy
accDiffLim = [-0.15, 0.15]  # Plot limit for difference in accuracy
lossLim = [0.3, 0.7]  # Plot limit for loss value
lossDiffLim = [-0.15, 0.15]  # Plot limit for difference in loss

# LSTM
LSTMFile = './LSTM/TestLR/TestLR.pickle'
LSTMKey = 'LR'
LSTMValue = 4e-5

# GRU
GRUFile = './GRU/TestDO/TestDO.pickle'
GRUKey = 'Dropout'
GRUValue = 0.1

# RNN
RNNFile = './RNN/TestDO/TestDO.pickle'
RNNKey = 'Dropout'
RNNValue = 0.1

# -------------- load data ----------------- #

with open(LSTMFile, 'rb') as f:
    temp = load(f)
for curr in temp:
    if curr[1][LSTMKey] == LSTMValue:
        lstmHist = curr[0]
        break

with open(GRUFile, 'rb') as f:
    temp = load(f)
for curr in temp:
    if curr[1][GRUKey] == GRUValue:
        gruHist = curr[0]
        break

with open(RNNFile, 'rb') as f:
    temp = load(f)
for curr in temp:
    if curr[1][RNNKey] == RNNValue:
        rnnHist = curr[0]
        break
    
# ----------------- Accuracy ----------------- #

plt.figure(figsize=(9.6, 4.26))

plt.subplot(1, 3, 1)
plt.plot(lstmHist['accuracy'])
plt.plot(gruHist['accuracy'])
plt.plot(rnnHist['accuracy'])
plt.title('Training')
plt.ylim(accLim)

allTicks, _ = plt.yticks()
for currY in allTicks[1:-1]:
    plt.plot([0, 30], [currY, currY], '--k', alpha=0.1)

plt.ylabel('Accuracy')
plt.xlabel('Epoch')
# plt.legend(['LSTM', 'GRU', 'SimpleRNN'], loc='lower right')
plt.box()

plt.subplot(1, 3, 2)
plt.plot(lstmHist['val_accuracy'])
plt.plot(gruHist['val_accuracy'])
plt.plot(rnnHist['val_accuracy'])
plt.title('Validation')
plt.ylim(accLim)

allTicks, _ = plt.yticks()
for currY in allTicks[1:-1]:
    plt.plot([0, 30], [currY, currY], '--k', alpha=0.1)

plt.xlabel('Epoch')
# plt.legend(['LSTM', 'GRU', 'SimpleRNN'], loc='lower right')
# plt.yticks([])
plt.box()

plt.subplot(1, 3, 3)
plt.plot(np.array(lstmHist['accuracy']) - np.array(lstmHist['val_accuracy']))
plt.plot(np.array(gruHist['accuracy']) - np.array(gruHist['val_accuracy']))
plt.plot(np.array(rnnHist['accuracy']) - np.array(rnnHist['val_accuracy']))
plt.title('Training - Validation')
plt.ylim(accDiffLim)
plt.yticks([-0.1, 0, 0.1])

allTicks, _ = plt.yticks()
for currY in allTicks:
    plt.plot([0, 30], [currY, currY], '--k', alpha=0.1)

plt.xlabel('Epoch')
plt.legend(['LSTM', 'GRU', 'SimpleRNN'], loc='lower right')
plt.box()

plt.suptitle('Accuracy', y = 0.999, fontsize = 14)
plt.savefig(savePath + 'Accuracy.png')

# ------------------- Loss ----------------------#

plt.figure(figsize=(9.6, 4.26))

plt.subplot(1, 3, 1)
plt.plot(lstmHist['loss'])
plt.plot(gruHist['loss'])
plt.plot(rnnHist['loss'])
plt.title('Training')
plt.ylim(lossLim)
plt.ylabel('Loss')
plt.xlabel('Epoch')
# plt.legend(['LSTM', 'GRU', 'SimpleRNN'], loc='upper right')

allTicks, _ = plt.yticks()
for currY in allTicks[1:-1]:
    plt.plot([0, 30], [currY, currY], '--k', alpha=0.1)

plt.ylabel('Loss')
plt.xlabel('Epoch')
# plt.legend(['LSTM', 'GRU', 'SimpleRNN'], loc='lower right')
plt.box()

plt.subplot(1, 3, 2)
plt.plot(lstmHist['val_loss'])
plt.plot(gruHist['val_loss'])
plt.plot(rnnHist['val_loss'])
plt.title('Validation')
plt.ylim(lossLim)
plt.xlabel('Epoch')
# plt.legend(['LSTM', 'GRU', 'SimpleRNN'], loc='upper right')

allTicks, _ = plt.yticks()
for currY in allTicks[1:-1]:
    plt.plot([0, 30], [currY, currY], '--k', alpha=0.1)

plt.xlabel('Epoch')
# plt.legend(['LSTM', 'GRU', 'SimpleRNN'], loc='lower right')
plt.box()

plt.subplot(1, 3, 3)
plt.plot(np.array(lstmHist['loss']) - np.array(lstmHist['val_loss']))
plt.plot(np.array(gruHist['loss']) - np.array(gruHist['val_loss']))
plt.plot(np.array(rnnHist['loss']) - np.array(rnnHist['val_loss']))
plt.title('Training - Validation')
plt.ylim(lossDiffLim)
allTicks = [-0.1, -0.05, 0, 0.05, 0.1]
plt.yticks(allTicks)

for currY in allTicks:
    plt.plot([0, 30], [currY, currY], '--k', alpha=0.1)

plt.xlabel('Epoch')
plt.legend(['LSTM', 'GRU', 'SimpleRNN'], loc='upper right')
plt.box()

plt.suptitle('Loss', y = 0.999, fontsize = 14)
plt.savefig(savePath + 'Loss.png')
# plt.show()
