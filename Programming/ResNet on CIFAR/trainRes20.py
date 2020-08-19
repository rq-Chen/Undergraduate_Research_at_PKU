"""trainRes20.py - Train a ResNet20 v1 on CIFAR10

Author: Ruiqi Chen
Version: 12/01/2019
Model Structure:
    See https://towardsdatascience.com/resnets-for-cifar-10-e63e900524e0
        https://towardsdatascience.com/understanding-and-visualizing-resnets-442284831be8
    - resLayer1
    - Stage0
      - resBlock1
        - resLayer1
        - resLayer1
        - identity shortcut
        - relu
      - resBlock1
    - Stage1
      - resBlock2
        - resLayer2 (s = 2)
        - resLayer1
        - projection shortcut (s = 2, no BN)
        - relu
      - resBlock1
    - Stage2 (similar to Stage1)
    - Pooling
    - Flatten
    - Dense
Reference: https://keras.io/examples/cifar10_resnet/

This model is (or at least it's meant to be) the same as the Keras's sample.
    I rewrite part of the code (mainly the structure) to help me understand
    how Keras works.

"""

# ----------import the utilities----------- #

import numpy as np
import os
import keras
from keras.datasets import cifar10
from keras import backend as K  # theano or tensorflow
from keras.models import Model  # the class for the network
# layers
from keras.layers import Dense, Conv2D, BatchNormalization, Activation
from keras.layers import AveragePooling2D, Input, Flatten
# regularization
from keras.regularizers import l2
# Optimizer
from keras.optimizers import Adam
# callback functions
from keras.callbacks import ModelCheckpoint, LearningRateScheduler
from keras.callbacks import ReduceLROnPlateau


# -------------- dubugging ----------------- #

# import tensorflow as tf
# a = tf.constant([1, 2])
# b = tf.constant([3, 4])
# print(a + b)


# --------------hyperparameters------------- #

NBASEFILTERS = 16  # number of filters in Stage0
L2WEIGHT = 1e-4
BATCHSIZE = 32
EPOCHS = 50

def lr_schedule(epoch):
    """Learning Rate Schedule
    Learning rate is scheduled to be reduced after 80, 120, 160, 180 epochs.
    Called automatically every epoch as part of callbacks during training.
    # Arguments
        epoch (int): The number of epochs
    # Returns
        lr (float32): learning rate
    """
    lr = 1e-3
    if epoch > 180:
        lr *= 0.5e-3
    elif epoch > 160:
        lr *= 1e-3
    elif epoch > 120:
        lr *= 1e-2
    elif epoch > 80:
        lr *= 1e-1
    print('Learning rate: ', lr)
    return lr


# -----------------the model---------------- #

def resLayer(_input, _filters = NBASEFILTERS, _kernelSize = 3, _stride = 1,
     _norm = True, _acti = True):
    """A ResNet layer: Conv + BN + ReLu

    The last (3rd) layer in each block has no ReLu.
    Projection shortcut has no BN and no ReLu.
    """
    x = _input
    x = Conv2D(_filters, kernel_size=_kernelSize, strides=_stride, padding='same',
        kernel_initializer='he_normal', kernel_regularizer=l2(L2WEIGHT))(x);
    if _norm:
        x = BatchNormalization()(x);
    if _acti:
        x = Activation('relu')(x);
    return x


def resBlock(_input, _stage, _block):
    """resBlock - a residual block containing 2 conv and 1 shortcut

    """
    nFilters = NBASEFILTERS * (2 ** _stage)
    if _stage > 0 and _block == 0:  # downsample
        strides = 2
    else:
        strides = 1

    # 2 conv
    output = resLayer(_input, nFilters, _stride=strides)
    output = resLayer(output, nFilters, _acti=False)

    # shortcut
    if _stage > 0 and _block == 0:  # projection
        # Caution: here the Keras document implementation differs from 
        #   the one mentioned before (in kernel size), and we use Keras's.
        _input = resLayer(_input, nFilters, _kernelSize=1,
            _stride=strides, _norm=False, _acti=False)

    output = keras.layers.add([_input, output])
    output = Activation('relu')(output)
    return output


def ResNet20(inputShape):
    """ResNet20 - the network

    Returns a Keras model.
    """
    inputs = Input(shape=inputShape)
    x = resLayer(inputs)  # resLayer1

    # resBlocks
    for nStage in range(3):
        for nBlock in range(3):
            x = resBlock(x, nStage, nBlock)

    x = AveragePooling2D(pool_size=8)(x)
    y = Flatten()(x)
    outputs = Dense(10, activation='softmax',
        kernel_initializer='he_normal')(y)

    # Generate model
    model = Model(inputs=inputs, outputs=outputs)
    return model    


# ------------------main-------------------- #

# Load the CIFAR10 data.
(x_train, y_train), (x_test, y_test) = cifar10.load_data()

# Input image dimensions.
input_shape = x_train.shape[1:]

# Normalize data
x_train = x_train.astype('float32') / 255
x_test = x_test.astype('float32') / 255
x_train_mean = np.mean(x_train, axis=0)
x_train -= x_train_mean
x_test -= x_train_mean

print('x_train shape:', x_train.shape)
print(x_train.shape[0], 'train samples')
print(x_test.shape[0], 'test samples')
print('y_train shape:', y_train.shape)

# Convert class to binary matrices for use of crossEntropy
y_train = keras.utils.to_categorical(y_train, 10)
y_test = keras.utils.to_categorical(y_test, 10)

# Generate model instance
model = ResNet20(input_shape)
model.compile(loss='categorical_crossentropy',
    optimizer=Adam(learning_rate=lr_schedule(0)),
    metrics=['accuracy'])
model.summary()

# Prepare model model saving directory
save_dir = os.path.join(os.getcwd(), 'saved_models')
model_name = 'cifar10_ResNet20_model.{epoch:03d}.h5'
if not os.path.isdir(save_dir):
    os.makedirs(save_dir)
filepath = os.path.join(save_dir, model_name)

# Prepare callbacks for model saving and for learning rate adjustment.
checkpoint = ModelCheckpoint(filepath=filepath,
    monitor='val_acc', verbose=1, save_best_only=False)
lr_scheduler = LearningRateScheduler(lr_schedule)
lr_reducer = ReduceLROnPlateau(factor=np.sqrt(0.1),
    cooldown=0, patience=5, min_lr=0.5e-6)
callbacks = [checkpoint, lr_reducer, lr_scheduler]

model.fit(x_train, y_train,
    batch_size=BATCHSIZE,
    epochs=EPOCHS,
    validation_data=(x_test, y_test),
    shuffle=True,
    callbacks=callbacks)

# Score trained model
scores = model.evaluate(x_test, y_test, verbose=1)
print('Test loss:', scores[0])
print('Test accuracy:', scores[1])