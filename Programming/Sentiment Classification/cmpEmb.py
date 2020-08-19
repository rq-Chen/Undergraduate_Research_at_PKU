"""cmpEmb.py - Compare different word2vec performance on IMDb dataset

Author: Ruiqi Chen
Version: 03/23/2020

This script aims at comparing different embedding strategies'
performance given the same classifier on the IMDb sentiment dataset.

Embedding Strategies:
    Dense: fully-connected layer with random initialization
    Skip-gram:
    CBOW:

When comparing different encoding strategies, we used a LSTM (with
    word vector dim = 64, output dim = 108) as benchmark classifier.
    

"""


# ---------- Import requirements ----------- #


from pickle import dump, load
import gc, os
import numpy as np
import matplotlib.pyplot as plt


# ------------- Hyperparameters ------------ #


# For illustration
savePath = './Embedding/'
accLim = [0.5, 0.9]
lossLim = [0.3, 0.7]

# For skip-gram
sgFile = 'sgTest.pickle'
sgInd = -2  # index in sgFile

# For CBOW
cbowFile = 'cbowTest.pickle'
cbowInd = 2  # the third one

# For dense
denseFile = 'denseTest.pickle'
denseInd = 1  # the second one


# ---------------- Load data ---------------- #


with open(savePath + sgFile, 'rb') as f:
    tmp = load(f)
sg = tmp[sgInd]
with open(savePath + cbowFile, 'rb') as f:
    tmp = load(f)
cbow = tmp[cbowInd]
with open(savePath + denseFile, 'rb') as f:
    tmp = load(f)
dense = tmp[denseInd]

toPlot = [sg, cbow, dense]


# --------------- Visualization --------------- #


# Plot accuracy
plt.figure(figsize=(9.6, 4.26))
plt.subplot(1, 2, 1)
for curr in toPlot:
    plt.plot(curr[0]['accuracy'])
plt.title('Training Accuracy')
plt.ylabel('Accuracy')
plt.ylim(accLim)  # for direct comparison
plt.xlabel('Epoch')

plt.subplot(1, 2, 2)
currLegend = []
for curr in toPlot:
    plt.plot(curr[0]['val_accuracy'])
plt.title('Validation Accuracy')
plt.ylim(accLim)  # for direct comparison
plt.xlabel('Epoch')
plt.legend(['Skip-gram', 'CBOW', 'Dense'], loc='lower right')
plt.savefig(savePath + 'cmpAcc.png')

# Plot loss
plt.figure(figsize=(9.6, 4.26))
plt.subplot(1, 2, 1)
for curr in toPlot:
    plt.plot(curr[0]['loss'])
plt.title('Training Loss')
plt.ylabel('Loss')
plt.ylim(lossLim)  # for direct comparison
plt.xlabel('Epoch')
plt.legend(['Skip-gram', 'CBOW', 'Dense'], loc='upper right')

plt.subplot(1, 2, 2)
currLegend = []
for curr in toPlot:
    plt.plot(curr[0]['val_loss'])
plt.title('Validation Loss')
plt.ylim(lossLim)  # for direct comparison    
plt.xlabel('Epoch')
plt.legend(['Skip-gram', 'CBOW', 'Dense'], loc='upper right')
plt.savefig(savePath + 'cmpLoss.png')