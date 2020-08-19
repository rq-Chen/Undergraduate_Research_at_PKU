"""trainRNN.py - Tune parameters for RNN

Author: Ruiqi Chen
Version: 03/23/2020

Model Structure:
    - Embedding: 5000 * 64
    - Recurrent: 64 (+200) * 200 (full sequence)
    - Recurrent: 200 (+80) * 80
    - Softmax: 80 * 1

Training:

    Hyperparameters to tune:
        BatSize: from 32 to 256
        LR: from 1e-5 to 1e-3
        Drop: feedforward and recurrent dropout

    Other parameters:
        reduce_lr: reduce LR on plateau
        nEpoch: number of epochs

"""

# ---------- Import requirements ----------- #

from keras.preprocessing import sequence
from keras.models import Sequential
from keras.layers import Dense, Embedding
from keras.layers import SimpleRNN
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
savePath = './RNN/TestDO/'
recordName = 'TestDO.pickle'

# For training
nEpoch = 30
BatSize = 64
LR = 7e-5
Drop = 0.2  # feedforward and recurrent dropout
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.2,
    patience=5, min_lr=1e-6)

# For GRU
nLen = 80
nWord = 5000  # Number of most frequent words to use
nDim = 64  # Dimension of the input word vector
rnnHid = 200  # number of neurons in the hidden layer
rnnOut = 80  # output layer


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

# ---------------- RNN --------------------- #

print("Building RNN ...")
rnnM = Sequential();

rnnM.add(Embedding(nWord, nDim))
rnnM.add(SimpleRNN(rnnHid, dropout=Drop, recurrent_dropout=Drop, return_sequences=True))
rnnM.add(SimpleRNN(rnnOut, dropout=Drop, recurrent_dropout=Drop))
rnnM.add(Dense(1, activation='sigmoid'))
rnnM.summary()

rnnOpt = Adam(learning_rate=LR)
rnnM.compile(loss='binary_crossentropy',
    optimizer=rnnOpt, metrics=['accuracy'])

print('Training RNN ...')
rnnHist = rnnM.fit(x_train, y_train,
    batch_size=BatSize, epochs=nEpoch,
    validation_data=(x_test, y_test), callbacks=[reduce_lr])

K.clear_session()
del rnnM
gc.collect()

# -------------- plot and save ----------------- #

if not os.path.isdir(savePath):
    os.mkdir(savePath)

if os.path.isfile(savePath + recordName):
    with open(savePath + recordName, 'rb') as f:
        Record = load(f)
else:
    Record = []

Record.append([rnnHist.history,
        {'BatchSize':BatSize, 'LR':LR,
            'Dropout':Drop, 'nEpoch':nEpoch}])

with open(savePath + recordName, 'wb') as f:
    dump(Record, f)

# Plot training & validation accuracy values
plt.figure()

plt.subplot(1, 2, 1)
plt.plot(rnnHist.history['accuracy'])
plt.plot(rnnHist.history['val_accuracy'])
plt.title('Accuracy')
plt.ylabel('Accuracy')
plt.xlabel('Epoch')
plt.legend(['Training', 'Test'], loc='upper left')

plt.subplot(1, 2, 2)
plt.plot(rnnHist.history['loss'])
plt.plot(rnnHist.history['val_loss'])
plt.title('Loss')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['Training', 'Test'], loc='upper left')

if len(savePath) == 0:
    plt.show()
else:
    saveName = "LR%.0e_B%d_D%d.png" % (LR, BatSize, Drop*100)
    plt.savefig(savePath + saveName)


