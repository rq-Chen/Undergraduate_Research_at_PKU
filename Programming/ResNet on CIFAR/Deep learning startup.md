<div>
    <center>
    	<span style = "float: left">
    		<a href = "https://rq-chen.github.io/visualization-project/index.html">Before: Visualization project</a>
    	</span>
        <a href = "https://rq-chen.github.io/index.html">Homepage</a>
    	<span style = "float: right">
    		<a href = "https://rq-chen.github.io/summer-school/index.html">Next: Summer school</a>
    	</span>
    </center>
</div>

---

# Train a ResNet20-v1 on CIFAR10



## Introduction

I try to implement a deep neural network on my laptop. Due to the weak computing capability (NVIDIA GTX 1060 3GB), I decided to train a relatively small network from scratch on a relatively small dataset. Therefore, I choosed [ResNet20-v1](https://towardsdatascience.com/resnets-for-cifar-10-e63e900524e0) and [CIFAR10](https://www.cs.toronto.edu/~kriz/cifar.html) dataset.

**My codes are available [here](trainRes20.py), and the model weights are available [here](saved_models/).**

ResNet is a famous convolutional neural network structure. It adopts identity/weighted shortcuts to facilitate the convergence of the model, which enables training super-deep neural networks (up to 1001 layers, much higher than the former models which only have no more than 20 layers). It's most characteristics structure is the residual block, where the arc arrow represents a shortcut connection:

<img src = "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/ResNets.svg/440px-ResNets.svg.png" style = "zoom:60%" />

The CIFAR-10 dataset consists of 60000 32x32 colour images in 10 classes, with 6000 images per class. There are 50000 training images and 10000 test images. 

I implement the model with [Keras](https://keras.io/) using [Tensorflow 2](https://www.tensorflow.org/) based on Python 3.7 ([Anaconda 3](https://www.anaconda.com/)) on Windows 10 (64bit). As a beginner, I referred to the [example code](https://keras.io/examples/cifar10_resnet/) provided by Keras. I understood and rewrite the code, but the structure and hyper-parameters are identical. I got hands-on experience with deep learning during this process, and became familiar with Keras model implementation and training.



## Environment

It is probably the most tiresome part:

1. Download and install [Anaconda 3](https://www.anaconda.com/distribution/) (using default settings).

   Anaconda helps maintain Python packages and enables switching between different python version (e.g. python 2.7 and python 3.6) through virtual environments. In my case, I use python 3.7 as the default python, and create another environment for deep learning with `numpy`, `scipy`, `tensorflow`, `keras` and so on. Besides, I also installed Anaconda 2 (32bit) with python 2.7 (32bit) for other purpose. And there is no conflict among these different python environments up to now.

2. Add Anaconda directories to the system path:
   1. `C:\Users\YOURNAME\Anaconda3`
   2. `C:\Users\YOURNAME\Anaconda3\Scripts`
   3. `C:\Users\YOURNAME\Anaconda3\Library\bin`

3. Create a virtual environment for deep learning (optional):

   Enter the command in cmd or Anaconda prompt (replace YOURENVNAME with the name your want, e.g. `tensorflow2py37`):

   ```shell
   conda create -n YOURENVNAME
   conda activate YOURENVNAME
   ```
   
4. Install tensorflow and relevant packages:

   (If you're in China, probably you need to change the channel first in order to improve the download speed:

   `conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/win-64/`)

   Enter the command:

   ```shell
   conda install tensorflow-gpu
   ```

   And Anaconda will prepare everything for you.

5. Install other required packages:

   View [Keras installation guidance](https://keras.io/#installation) to see if all dependencies are installed, if not, use `conda install xx` to install them.

6. Install Keras: `pip install keras`. You can deactivate the virtual environment now by `conda deactivate`.

7. Update the GPU driver with NVIDIA Geforce Experince.

8. Begin coding:

   I launch [Visual Studio Code](https://code.visualstudio.com/) for programming in the Anaconda Navigator GUI, after choosing the python version (**CAUTION: DON'T OPEN VSCODE DIRECTLY OUTSIDE ANACONDA, otherwise the virtual environment won't work**).



## Coding

I rewrote the ResNet layer function to make it more concise:

```python
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
```

And I extracted the residual block as a function for clearer model design:

```python
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
```

The model generator:

```python
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
```

The training configuration was roughly the same as the Keras example, but I didn't use data augmentation.



## Result

I trained for 50 epochs:

<img src = "models_saved.png" style = "zoom:40%" />

The training loss was steadily decreasing, but it seems that the accuracy continued to fluctuate. The final loss and accuracy are roughly the same on tesing and training set. Even though it seems that the model was still under-fitting, it performed well (80% accuracy, much higher than chance level 10%) on the testing set (since I was not so familiar with Keras visualization, I use Matlab to plot).

<img src = "TrainingProcess.png" style = "zoom:40%" />

A little problem is that the training process seems to be too slow (170 sec/epoch, while the benchmark on GTX 1080Ti (just 140% more powerful than my GPU, according to the [UserBenchmark](https://gpu.userbenchmark.com/Compare/Nvidia-GTX-1080-Ti-vs-Nvidia-GTX-1060-3GB/3918vs3646)) is 35 sec/epoch). Acoording to the terminal output, the GPU was correctly activated (`2019-12-03 02:48:20.844426: I tensorflow/core/common_runtime/gpu/gpu_device.cc:1304] Created TensorFlow device (/job:localhost/replica:0/task:0/device:GPU:0 with 2103 MB memory) -> physical GPU (device: 0, name: GeForce GTX 1060, pci bus id: 0000:01:00.0, compute capability: 6.1)`), but the GPU load is only around 20% during the training. Probably there are some other configurations to set in order to make full use of the GPU.



---

<div>
    <center>
    	<span style = "float: left">
    		<a href = "https://rq-chen.github.io/visualization-project/index.html">Before: Visualization project</a>
    	</span>
        <a href = "https://rq-chen.github.io/index.html">Homepage</a>
    	<span style = "float: right">
    		<a href = "https://rq-chen.github.io/summer-school/index.html">Next: Summer school</a>
    	</span>
    </center>
</div>