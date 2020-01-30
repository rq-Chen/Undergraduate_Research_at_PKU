# Data Analysis



## Event Related Response Analysis

- averaged seperately for SIMPLE, REVERSED correct, REVERSED incorrect and so on, with equal number of trials (randomly selected)
- 100ms (before onset of S1) baseline correction
- Statistics test:
  - 250ms binned (totally 8 during retention period), computing the absolute value of the mean
  - cluster-level paired t-test (by FieldTrip) on EEG topologies for each time window, multiple comparison corrected
- ROI defined by overlapping area of the main effects of REVERSED versus SIMPLE, or REVERSED correct vs incorrect, etc.



## Time-frequency Analysis

- EEG signals were decomposed by complex Morlet’s wavelets (namely Gabor wavelets).

- Background knowledge:

  - Gabor transform

    Gabor transform is a special kind of short-time Fourier transform, where the signal is first multiplied by a Gaussian window before performing the STFT (for practical implementation, limit the integral to where the Gaussian function == 1*10^-5, namely $$ \tau \pm 1.9143$$, where $$\tau$$ is the time point and $$\omega$$ is the angular frequency):
    $$
    G_{x}(\tau ,\omega )=\int _{-\infty }^{\infty }x(t)e^{-\pi (t-\tau )^{2}}e^{-j\omega t}\,dt\\
    x(t)=\int _{-\infty }^{\infty }\int _{-\infty }^{\infty }G_{x}(\tau ,\omega )e^{j\omega t}\,d\omega \,d\tau
    $$
    It's easy to see that the equation is decomposing the signal with a series of Gabor functions, which is a complex exponential multiplied by a Gaussian window (both the real and imagine part are similar to this shape):

    <img src = "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/MorletWaveletMathematica.svg/1280px-MorletWaveletMathematica.svg.png" style = "zoom:30%" />

    Alternatively, we can transform the signal into its Gabor wavelet coefficients by convoluting the signal with a series of Gabor filters in the time domain.

  - Continuous wavelet analysis

    [This MATLAB topic](https://ww2.mathworks.cn/help/wavelet/gs/continuous-wavelet-transform-and-scale-based-analysis.html) provides clear explanation of the continuous wavelet transform and scale-based analysis. In a word, what we want to do is to decomposite the signal with a family of wavelet functions (mother functions) $$\frac{1}{a} \psi(\frac{t - b}{a})$$, centralized at $$b$$ (time) and stretched by scale $$a$$ (negatively related to frequency):
    $$
    G_x(b,a) = \int_{-\infin}^{\infin} x(t)\frac{1}{a} \psi^{*}(\frac{t - b}{a})\, dt
    $$
  
- Scaled Gabor transform
  
  Scaled Gabor transform enable us to modify the analyzing resolution in the time and frequency domain (simultaneously, with a trade-off) by changing the variance of the Gaussian window (t and f means time and frequency):
  $$
    W_{Gaussian}(t)=e^{-\sigma \pi t^{2}}\\
    G_{x}(t,f)={\sqrt[{4}]{\sigma }}\textstyle \int _{-\infty }^{\infty }\displaystyle e^{-\sigma \pi (\tau -t)^{2}}e^{-j2\pi f\tau }x(\tau )d\tau \qquad
  $$
  
- Gabor wavelet
  
  The shape of Gabor wavelet is Gaussian both in the time (centered at 0, sinusoidal) and frequency domain (centered at its central frequency $$\omega_c$$).
  $$
  \psi(t) = \frac{1}{\sqrt[4]\pi}e^{-\frac{t^2}{2}}e^{j\omega_ct}\\
    \Psi(\omega) = \sqrt2\sqrt[4]\pi e^{-\frac{(\omega - \omega_c)^2}{2}}
  $$
  



## Behavioral

### Accuracy

- one way ANOVA significant
- post hoc test, Tukey's hsd corrected
- `figures/accuracy.png`

### Reaction Time

**Errorneous, but p-value will only be lower if corrected.**

- two way ANOVA with unbalanced design (some subjects perform 100% accurate under some conditions) **(should have been repeated measure two-way ANOVA, so the error will be smaller and p will be smaller too)**
- both main effects of response and task are significant
- post hoc test, Tukey's hsd corrected **(maybe Bonfferoni is better?)**
- `figures/reaction time.png`

