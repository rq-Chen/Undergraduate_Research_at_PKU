"""trainCBOW.py - Train CBOW word vector

Author: Ruiqi Chen
Version: 03/23/2020

"""


# ---------- Import requirements ----------- #


from gensim.models import word2vec
from gensim.models.callbacks import CallbackAny2Vec
from keras.preprocessing import sequence
from keras.models import Sequential
from keras.layers import Dense, Embedding
from keras.layers import LSTM
from keras.datasets import imdb
from keras.optimizers import Adam
from keras.callbacks.callbacks import ReduceLROnPlateau
from keras import backend as K
from pickle import dump, load
import gc, os
import numpy as np
import matplotlib.pyplot as plt


# ------------- Hyperparameters ------------ #


# For data
datPath = './Embedding/'
datFile = 'voca.pickle'
cbowFile = 'cbow.pickle'

# For illustration
savePath = './Embedding/'
saveFile = 'cbowTest.pickle'
accLim = [0.5, 0.9]
lossLim = [0.3, 0.7]

# For cbow
cbowEpoch = [5, 15, 25]
cbowLoss = np.zeros([len(cbowEpoch), max(cbowEpoch)])

# For training
NSKTOP = 10
nWord = 5000  # Number of most frequent words to use
nDim = 64  # Dimension of the input word vector
nLen = 80  # Length of a token
lstmBatSize = 64
lstmLR = 1e-5
nEpoch = 30
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.2,
    patience=5, min_lr=1e-7)

# For LSTM
lstmDrop = 0.1  # feedforward and recurrent dropout ratio
lstmOut = 108  # output dimension

# Dangerous zoom (DON'T CHANGE)
PAD_CHAR   = 0
START_CHAR = 1
OOV_CHAR   = 2
INDEX_FROM = 3  # real word index begins from INDEX_FROM + 1
# Dangerous zoom (DON'T CHANGE)


# ------------ Utility function ---------- #


class callback(CallbackAny2Vec):
    """
    Callback to print loss after each epoch
    """
    def __init__(self, logLoss):
        self.epoch = 0
        self.log = logLoss

    def on_epoch_end(self, model):
        loss = model.get_latest_training_loss()
        if self.epoch == 0:
            self.log[self.epoch] = loss
        else:
            self.log[self.epoch] = loss - self.loss_previous_step
        print('Loss after epoch {}: {}'.format(self.epoch,
            self.log[self.epoch]))
        self.epoch += 1
        self.loss_previous_step = loss


# -------------- Load data ----------------- #


print('Loading data ...')
if not os.path.isfile(datPath + datFile):
    (x_train, y_train), (x_test, y_test) = imdb.load_data(
        num_words=nWord, skip_top=NSKTOP, start_char=START_CHAR,
        oov_char=OOV_CHAR, index_from=INDEX_FROM)
    print(len(x_train), 'train sequences')
    print(len(x_test), 'test sequences')

    print('Pading sequences (samples x time) ...')
    x_train = sequence.pad_sequences(x_train, maxlen=nLen, value=PAD_CHAR)
    x_test = sequence.pad_sequences(x_test, maxlen=nLen, value=PAD_CHAR)
    print('x_train shape:', x_train.shape)
    print('x_test shape:', x_test.shape)

    # Build inversed vocabulary table
    forDict = imdb.get_word_index()
    for curr in forDict:
        forDict[curr] += INDEX_FROM  # Important!
    forDict['<PAD>']    = PAD_CHAR
    forDict['<START>']  = START_CHAR
    forDict['<UNK>']    = OOV_CHAR
    forDict['<UNUSED>'] = INDEX_FROM
    invDict = [k for k, v in
        sorted(forDict.items(), key = lambda s:s[1])]
    wvTrain = [[invDict[i] for i in curr] for curr in x_train]

    # Check output
    print("Example input: ")
    print(' '.join(wvTrain[0]))
    # if input("Continue? (Y/N): ") != 'Y':
    #     exit()

    # Save file
    if not os.path.isdir(datPath):
        os.mkdir(datPath)
    with open(datPath + datFile, 'wb') as f:
        dump((x_train, x_test, y_train, y_test,
            forDict, invDict, wvTrain), f)
else:
    with open(datPath + datFile, 'rb') as f:
        (x_train, x_test, y_train, y_test,
            forDict, invDict, wvTrain) = load(f)
    print('Successfully load the training data.')


# ---------------- CBOW --------------- #


print("Training...")
if not os.path.isfile(datPath + cbowFile):
    cbowGram = []
    for curr, e in zip(cbowLoss, cbowEpoch):
        cbowGram.append(word2vec.Word2Vec(wvTrain, size=nDim,
            min_count=1, sg=0, callbacks=[callback(curr)],
            iter=e, compute_loss=True))
    if not os.path.isdir(datPath):
        os.mkdir(datPath)
    with open(datPath + cbowFile, 'wb') as f:
        dump((cbowLoss, cbowEpoch, cbowGram), f)
else:
    with open(datPath + cbowFile, 'rb') as f:
        (cbowLoss, cbowEpoch, cbowGram) = load(f)


# ------- Visualize word2vec training ------ #


# word2vec training loss
plt.figure(figsize=(9.6, 4.26))
for curr, e in zip(cbowLoss, cbowEpoch):
    plt.plot(range(e), np.transpose(curr[:e]))
plt.legend([("%d epochs" % e) for e in cbowEpoch])
plt.title('Loss')
plt.savefig("%scbowLoss.png" % (savePath))


# if input("Continue to train LSTM? (Y/N): ") != 'Y':
#     exit()


# --------------- Get weights -------------- #


allWV = np.random.rand(len(cbowGram), nWord, nDim)
# Each column is a word vector
for i in range(len(cbowGram)):
    for j, word in enumerate(cbowGram[i].wv.index2word):
        allWV[i, forDict[word], :] = cbowGram[i].wv.vectors[j,:]
    # The index of words begins from INDEX_FROM


# ---------------- LSTM -------------------- #


lstmHist = []
for i in range(len(cbowGram)):
    print('Building LSTM', i, '...')
    lstmM = Sequential()
    lstmM.add(Embedding(nWord, nDim, weights=[allWV[i]], trainable=False))
    lstmM.add(LSTM(lstmOut, dropout=lstmDrop, recurrent_dropout=lstmDrop))
    lstmM.add(Dense(1, activation='sigmoid'))
    lstmM.summary()

    lstmOpt = Adam(learning_rate=lstmLR)
    lstmM.compile(loss='binary_crossentropy',
        optimizer=lstmOpt, metrics=['accuracy'])

    print('Training LSTM...')
    tmp = lstmM.fit(x_train, y_train,
        batch_size=lstmBatSize, epochs=nEpoch,
        validation_data=(x_test, y_test), callbacks=[reduce_lr])
    lstmHist.append([tmp.history, 'CB',
        {'BatchSize':lstmBatSize, 'LR':lstmLR,
            'Dropout':lstmDrop, 'wvEpoch':cbowEpoch[i]}])

    K.clear_session()
    gc.collect()


# -------------- plot and save ----------------- #


if os.path.isfile(savePath + saveFile):
    with open(savePath + saveFile, 'rb') as f:
        tmp = load(f)
    tmp = tmp + lstmHist
else:
    tmp = lstmHist
if not os.path.isdir(savePath):
    os.mkdir(savePath)
with open(savePath + saveFile, 'wb') as f:
    dump(tmp, f)

filePre = 'LR%.0e_BS%d_D%d_' % (lstmLR, lstmBatSize, lstmDrop * 100)

# Plot accuracy
plt.figure(figsize=(9.6, 4.26))
plt.subplot(1, 2, 1)
currLegend = []
for curr in lstmHist:
    plt.plot(curr[0]['accuracy'])
    currTerm = "%d epochs" % (curr[-1]['wvEpoch'])
    currLegend.append(currTerm)
plt.title('Training Accuracy')
plt.ylabel('Accuracy')
plt.ylim(accLim)  # for direct comparison
plt.xlabel('Epoch')
plt.legend(currLegend, loc='lower right')

plt.subplot(1, 2, 2)
currLegend = []
for curr in lstmHist:
    plt.plot(curr[0]['val_accuracy'])
    currTerm = "%d epochs" % (curr[-1]['wvEpoch'])
    currLegend.append(currTerm)
plt.title('Validation Accuracy')
plt.ylim(accLim)  # for direct comparison
plt.xlabel('Epoch')
plt.legend(currLegend, loc='lower right')
plt.savefig(savePath + filePre + 'cmpCBAcc.png')

# Plot loss
plt.figure(figsize=(9.6, 4.26))
plt.subplot(1, 2, 1)
currLegend = []
for curr in lstmHist:
    plt.plot(curr[0]['loss'])
    currTerm = "%d epochs" % (curr[-1]['wvEpoch'])
    currLegend.append(currTerm)
plt.title('Training Loss')
plt.ylabel('Loss')
plt.ylim(lossLim)  # for direct comparison
plt.xlabel('Epoch')
plt.legend(currLegend, loc='upper right')

plt.subplot(1, 2, 2)
currLegend = []
for curr in lstmHist:
    plt.plot(curr[0]['val_loss'])
    currTerm = "%d epochs" % (curr[-1]['wvEpoch'])
    currLegend.append(currTerm)
plt.title('Validation Loss')
plt.ylim(lossLim)  # for direct comparison    
plt.xlabel('Epoch')
plt.legend(currLegend, loc='upper right')
plt.savefig(savePath + filePre + 'cmpCBLoss.png')