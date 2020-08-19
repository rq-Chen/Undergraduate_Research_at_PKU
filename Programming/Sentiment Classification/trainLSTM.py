"""trainLSTM.py - Tune parameters for LSTM

Author: Ruiqi Chen
Version: 03/23/2020

Model Structure:
    - Embedding: 5000 * 64
    - LSTM: 64 -> 108
    - Softmax: 108 * 1

Training:

    Hyperparameters to tune:
        lstmBatchSize: from 32 to 256
        lstmLR: from 1e-5 to 1e-3
        lstmDrop: feedforward and recurrent dropout

    Other parameters:
        reduce_lr: reduce LR on plateau
        nEpoch: number of epochs

"""

# ---------- Import requirements ----------- #

from keras.preprocessing import sequence
from keras.models import Sequential
from keras.layers import Dense, Embedding
from keras.layers import LSTM
from keras.datasets import imdb
from keras.optimizers import Adam
from keras.callbacks.callbacks import ReduceLROnPlateau
from keras import backend as K
from pickle import dump, load
import os
import gc
import numpy as np
import matplotlib.pyplot as plt

# ------------- Hyperparameters ------------ #

# For illustration and recording
savePath = './LSTM/TestDO/'
recordName = 'TestDO.pickle'

# For training
nEpoch = 30
lstmBatSize = 128
lstmLR = 4e-5
lstmDrop = 0.5  # feedforward and recurrent dropout
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.2,
    patience=5, min_lr=1e-6)

# For LSTM
nWord = 5000  # Number of most frequent words to use
nDim = 64  # Dimension of the input word vector
lstmOut = 108  # output dimension
nLen = 80  # Length of a token


# -------------- Load data ----------------- #

print('Loading data ...')
(x_train, y_train), (x_test, y_test) = imdb.load_data(
    num_words=nWord, skip_top=10)
print(len(x_train), 'train sequences')
print(len(x_test), 'test sequences')

print('Pading sequences (samples x time) ...')
x_train = sequence.pad_sequences(x_train, maxlen=nLen)
x_test = sequence.pad_sequences(x_test, maxlen=nLen)
print('x_train shape:', x_train.shape)
print('x_test shape:', x_test.shape)

# ---------------- LSTM -------------------- #

print('Building LSTM ...')
lstmM = Sequential()
lstmM.add(Embedding(nWord, nDim))
lstmM.add(LSTM(lstmOut, dropout=lstmDrop, recurrent_dropout=lstmDrop))
lstmM.add(Dense(1, activation='sigmoid'))
lstmM.summary()

lstmOpt = Adam(learning_rate=lstmLR)
lstmM.compile(loss='binary_crossentropy',
    optimizer=lstmOpt, metrics=['accuracy'])

print('Training LSTM...')
lstmHist = lstmM.fit(x_train, y_train,
    batch_size=lstmBatSize, epochs=nEpoch,
    validation_data=(x_test, y_test), callbacks=[reduce_lr])

K.clear_session()
del lstmM
gc.collect()

# -------------- plot and save ----------------- #

if not os.path.isdir(savePath):
    os.mkdir(savePath)

if os.path.isfile(savePath + recordName):
    with open(savePath + recordName, 'rb') as f:
        Record = load(f)
else:
    Record = []

Record.append([lstmHist.history,
        {'BatchSize':lstmBatSize, 'LR':lstmLR,
            'Dropout':lstmDrop, 'nEpoch':nEpoch}])

with open(savePath + recordName, 'wb') as f:
    dump(Record, f)

# Plot training & validation accuracy values
plt.figure()

plt.subplot(1, 2, 1)
plt.plot(lstmHist.history['accuracy'])
plt.plot(lstmHist.history['val_accuracy'])
# plt.plot(gruHist.history['accuracy'])
# plt.plot(rnnHist.history['accuracy'])
plt.title('Accuracy')
plt.ylabel('Accuracy')
plt.xlabel('Epoch')
plt.legend(['Training', 'Test'], loc='upper left')

plt.subplot(1, 2, 2)
plt.plot(lstmHist.history['loss'])
plt.plot(lstmHist.history['val_loss'])
# plt.plot(gruHist.history['val_loss'])
# plt.plot(rnnHist.history['val_loss'])
plt.title('Loss')
plt.ylabel('Loss')
plt.xlabel('Epoch')
# plt.legend(['LSTM', 'GRU', 'SimpleRNN'], loc='upper left')
plt.legend(['Training', 'Test'], loc='upper left')

if len(savePath) == 0:
    plt.show()
else:
    saveName = "LR%.0e_B%d_D%d.png" % (lstmLR, lstmBatSize, lstmDrop*100)
    plt.savefig(savePath + saveName)


