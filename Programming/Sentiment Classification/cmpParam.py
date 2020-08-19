"""cmpParam.py - Compare different combination of parameters

Author: Ruiqi Chen
Version: 03/30/2020

"""

import matplotlib.pyplot as plt
import os
from pickle import dump, load

# ----------------- Parameters ------------------- #

savePath = './RNN/'
allParam = ['LR', 'BS', 'DO']
accLim = [0.4, 0.9]  # Plot limit for accuracy
lossLim = [0.3, 0.7]  # Plot limit for loss value

# ----------------- Plot ------------------------- #

for par in allParam:
    currPath = savePath + 'Test' + par + '/'
    saveFile = currPath + 'Test' + par + '.pickle'
    if not os.path.isfile(saveFile):
        continue
    with open(saveFile, 'rb') as f:
        allDat = load(f)
    
    # Plot accuracy
    plt.figure()
    plt.subplot(1, 2, 1)
    currLegend = []
    for curr in allDat:
        plt.plot(curr[0]['accuracy'])
        if par == 'LR':
            currTerm = "%.0e" % curr[1]['LR']
        elif par == 'BS':
            currTerm = "%d" % curr[1]['BatchSize']
        else:
            currTerm = "%d%%" % (curr[1]['Dropout'] * 100)
        currLegend.append(par + '=' + currTerm)
    plt.title('Training Accuracy')
    plt.ylabel('Accuracy')
    plt.ylim(accLim)  # for direct comparison
    plt.xlabel('Epoch')
    plt.legend(currLegend, loc='lower right')

    plt.subplot(1, 2, 2)
    currLegend = []
    for curr in allDat:
        plt.plot(curr[0]['val_accuracy'])
        if par == 'LR':
            currTerm = "%.0e" % curr[1]['LR']
        elif par == 'BS':
            currTerm = "%d" % curr[1]['BatchSize']
        else:
            currTerm = "%d%%" % (curr[1]['Dropout'] * 100)
        currLegend.append(par + '=' + currTerm)
    plt.title('Validation Accuracy')
    plt.ylim(accLim)  # for direct comparison
    plt.xlabel('Epoch')
    plt.legend(currLegend, loc='lower right')
    plt.savefig(savePath + 'cmp' + par + 'Acc.png')

    # Plot loss
    plt.figure()
    plt.subplot(1, 2, 1)
    currLegend = []
    for curr in allDat:
        plt.plot(curr[0]['loss'])
        if par == 'LR':
            currTerm = "%.0e" % curr[1]['LR']
        elif par == 'BS':
            currTerm = "%d" % curr[1]['BatchSize']
        else:
            currTerm = "%d%%" % (curr[1]['Dropout'] * 100)
        currLegend.append(par + '=' + currTerm)
    plt.title('Training Loss')
    plt.ylabel('Loss')
    plt.ylim(lossLim)  # for direct comparison
    plt.xlabel('Epoch')
    plt.legend(currLegend, loc='upper right')

    plt.subplot(1, 2, 2)
    currLegend = []
    for curr in allDat:
        plt.plot(curr[0]['val_loss'])
        if par == 'LR':
            currTerm = "%.0e" % curr[1]['LR']
        elif par == 'BS':
            currTerm = "%d" % curr[1]['BatchSize']
        else:
            currTerm = "%d%%" % (curr[1]['Dropout'] * 100)
        currLegend.append(par + '=' + currTerm)
    plt.title('Validation Loss')
    plt.ylim(lossLim)  # for direct comparison    
    plt.xlabel('Epoch')
    plt.legend(currLegend, loc='upper right')
    plt.savefig(savePath + 'cmp' + par + 'Loss.png')

