# Data Analysis



## ERP Analysis

We converted data to Fieldtrip structure with averaging and baseline correction by `prepare_ft.m` with `DATATYPE = 'ERP'`.

- Averaged within each subject for each condition and correct/incorrect response
- Baseline corrected by subtracting the mean amplitude between -0.2~0s
- Converted to Fieldtrip structure by function `mat2ft.m`

Then we performed statistical analysis in `ERPstat.m`.



## Wavelet Analysis

We converted data to Fieldtrip structure with averaging and baseline correction by `prepare_ft.m` with `DATATYPE = 'TF'`.

- Converted to Fieldtrip structure by function `mat2ft.m`
- Performed wavelet transform by `ft_freqanalysis`. Frequencies are `2:30Hz`, time centers are `-1:0.01:4s` and the variance in frequency domain is set by $$f_0 / \sigma_f = 7$$.
- Averaged within each subject for each condition and correct/incorrect response
- Baseline corrected by zscoring against the power for each frequency bin between -1~0s

Then we performed statistical analysis in `TFstat.m`.