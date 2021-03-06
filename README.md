# Undergraduate Research at PKU

- `Auditory Working Memory`: the task design and analyzing method (and codes) for the first experiment in my independent research project.
- `EEG_Visual_Decoding`: My very first experience with cognitive neuroscience research.
- `Programming`: My programming projects.
- `Reading`: Some books and articles I've read through the process (not frequently updated) and the reviews I've written.

Below is the design and data analysis pipeline for my auditory working memory experiment (see `/Auditory Working Memory`).



# Auditory Working Memory Experiment Design



## Participants

- no limit on musical training
- no limit on handedness (but probably needing to analyze seperately)



## Stimuli

- two musical sequence seperated by 2000-ms silence

- each sequence containing three 250-ms piano tones (C4 to E6 (except for S2 of condition TRANSPOSITION, which may be as high as E7), 70 dB SPL, presented binaurally through air-conducting tubes with foam ear tips) presented successively without inter-tone-interval

- S1: 108 musical sequences generated by [Sibelius](http://www.sibelius.com) (probably we'll use another way)

  - tonal
  - no consecutive identical tones within a sequence
  - pitch interval between consecutive tones inferior to an octave

- S2: for the incorrect trials in condition SIMPLE, REVERSED and TRANSPOSITION:

  - one tone (at any position) changed for 2/3 semitones
  - maintaining the contour (the relative magnitude of three tones)

  for condition CONTOUR:

  - correct trials: modifying one tone of S1 by 2/3 semitones but maintaining the contour
  - incorrect trials: modifying one tone of S1 so as to change the contour (currently done by raising the 3rd tone to a pitch 2/3 semitones higher than the 1st, or lowering the 1st to that lower than the 3rd)



## Procedure

- Presentation software: [Neurobehavioral Systems](https://www.neurobs.com/presentation) (probably replaced by *Psychtoolbox*)
- Recording: 62 channels + EOG + nose reference + ground
- Trial pipeline:
  - No cue for trial beginning
  - Visual: fixating a continuously displayed cross (white on a gray background)
  - 750-ms S1
  - 2000-ms retention
  - 750-ms S2
  - 2000-ms reaction (pressing one of two buttons with right hand, no feedback)
  - 500-ms - 1000-ms randomized ITI (in order to remove the effect of expectation)
- Conditions:
  - SIMPLE: simple comparison
  - REVERSED: requiring subjects to mentally reverse S1 during retention, then compare it with S2
  - TRANSPOSITION: requiring subjects to mentally raise S1 for an octave during retention, then compare it with S2
  - CONTOUR: requiring subjects to mentally change the movement S1 into categories ("up-up" / "up-down" / "down-up" / "down-down") during retention, and that of S2 during reaction, then compare them
- Design:
  - block design
    - 2 blocks for each condition (totally 8 rather than the original 4), latin-square arrangement
    - 2-3 minutes rest between two blocks
    - each block containing 27 correct trials and 27 incorrect (totally 54 rather than the original 108), no consecutive three trials with the same response
    - totally 108 trials (rather than 216) for each condition
  - 4 * 27 practice trials (without feedback) at the very beginning, with sequences not used in formal experiments, 75% (can be a little lower considering the difficulty) accuracy required
- 10 practice trials or so before every block
- Total time estimation:
  - 6.25 * 84 / 60 = 8.75 min/block
  - approximately (8.75 + 2.25) * 8 = 88 min, 20% longer than the original study



## Preprocessing

### Pipeline

The first part is done by `Preprocessing.m`:

- Load data
- Select channel location
- Add FCz as reference
- Delete VEOG
- Re-refernce to average of all channels and insert FCz back
- Notch at 50Hz
- Filter between 0.15~30Hz
- Reject and interpolate pre-defined bad channels in `chnRej.mat`
- Epoch, -4~6s locked to all events
- Reject pre-defined bad trials in `xxRef.set`
- ICA with `binica.m`
- Save dataset as `NAME+NUMBER+'epoch'.set`, e.g. `crq1epoch.set`
- Clear the files created by `binica.m`

The bad channels were defined in `ArtifactPrepro.m`, and trials rejection is performed on a subset of the data with shorter baseline (actually we extracted such a long baseline merely to avoid the boundary effect in time-frequency decomposition). The process is described In the next section.

After that:

- Visually inspected the ICs and remove those clearly related to oculomotor artifacts
- Save the new set as `NAME+NUMBER.set`, e.g. `crq1.set` (`crq1` is myself; we will change these names before publishing our result)
- Collected data to `.mat` files by conditions, responses and subjects through `GroupDat.m`, e.g. `crq1/SimpleT.mat`

### Artifact Rejection

As mentioned before, we extracted a shorter epoch to reject the artifacts. This process is done by `artifactPrepro.m` and visual inspection.

The first part is exactly the same as in `Preprocessing.m`:

- Load data
- Select channel location
- Add FCz as reference
- Delete VEOG
- Re-refernce to average of all channels and insert FCz back
- Notch at 50Hz
- Filter between 0.15~30Hz

Then we defined bad channels:

- Reject and interpolate the bad channels recorded down during experiment
- Automatic channel rejection and interpolate back
- Merge and record the rejected and pre-defined bad channels in `chnRej.mat`

Then we extract a subset of the data for epoch rejection:

- Epoch, -1~6s locked to all events
- ICA with `binica.m`
- Save dataset as `NAME+NUMBER+'epochRef'.set`, e.g. `crq1epochRef.set`.
- Clear the files created by `binica.m`

Note that we performed the same preprocessing and rejected the same channels in `Preprocessing.m` and `ArtifactPrepro.m`, and the only difference is that the latter used a shorter epoch (and different ICs). We then performed a series of check to define bad trials:

First, we inspected and rejected the bad epochs (**not** because of blinking) with EEGLAB trial rejection function. The threshold analysis was limit to -200ms (baseline) to 3500ms (offset of S2) while the trend analysis was performed on the entire epoch (-1000ms to 5998ms). R-square limit for trend analysis was 0.3. Then we remove the oculomotor ICs and clipped the data to -1~4s. After that, we visually inspected for remaining artifacts (mainly noise in frontal channels) and saved the processed dataset as something like `crq1Ref.set`.



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