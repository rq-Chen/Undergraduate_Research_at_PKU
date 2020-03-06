# Preprocessing

## Pipeline

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

## Artifact Rejection

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