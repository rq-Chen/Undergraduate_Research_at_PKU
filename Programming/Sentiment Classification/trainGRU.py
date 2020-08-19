"""trainGRU.py - Tune parameters for GRU

Author: Ruiqi Chen
Version: 03/23/2020

Model Structure:
    - Embedding: 5000 * 64
    - GRU: 64 -> 128
    - Softmax: 128 * 1

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
from keras.layers import GRU
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
savePath = './GRU/TestDO/'
recordName = 'TestDO.pickle'

# For training
nEpoch = 30
BatSize = 128
LR = 2e-5
Drop = 0.4  # feedforward and recurrent dropout
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.2,
    patience=5, min_lr=1e-6)

# For GRU
nLen = 80
nWord = 5000  # Number of most frequent words to use
nDim = 64  # Dimension of the input word vector
gruOut = 128  # output dimension


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

# ------------------ GRU ------------------ #

print('Building GRU ...')
gruM = Sequential()
gruM.add(Embedding(nWord, nDim))
gruM.add(GRU(gruOut, dropout=Drop, recurrent_dropout=Drop))
gruM.add(Dense(1, activation='sigmoid'))
gruM.summary()

gruOpt = Adam(learning_rate=LR)
gruM.compile(loss='binary_crossentropy',
    optimizer=gruOpt, metrics=['accuracy'])

print('Training GRU...')
gruHist = gruM.fit(x_train, y_train,
    batch_size=BatSize, epochs=nEpoch,
    validation_data=(x_test, y_test), callbacks=[reduce_lr])

K.clear_session()
del gruM
gc.collect()


# -------------- plot and save ----------------- #

if not os.path.isdir(savePath):
    os.mkdir(savePath)

if os.path.isfile(savePath + recordName):
    with open(savePath + recordName, 'rb') as f:
        Record = load(f)
else:
    Record = []

Record.append([gruHist.history,
        {'BatchSize':BatSize, 'LR':LR,
            'Dropout':Drop, 'nEpoch':nEpoch}])

with open(savePath + recordName, 'wb') as f:
    dump(Record, f)

# Plot training & validation accuracy values
plt.figure()

plt.subplot(1, 2, 1)
plt.plot(gruHist.history['accuracy'])
plt.plot(gruHist.history['val_accuracy'])
plt.title('Accuracy')
plt.ylabel('Accuracy')
plt.xlabel('Epoch')
plt.legend(['Training', 'Test'], loc='upper left')

plt.subplot(1, 2, 2)
plt.plot(gruHist.history['loss'])
plt.plot(gruHist.history['val_loss'])
plt.title('Loss')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['Training', 'Test'], loc='upper left')

if len(savePath) == 0:
    plt.show()
else:
    saveName = "LR%.0e_B%d_D%d.png" % (LR, BatSize, Drop*100)
    plt.savefig(savePath + saveName)


