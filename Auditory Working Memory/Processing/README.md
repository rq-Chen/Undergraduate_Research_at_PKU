# Data Preprocessing



## Pipeline

Use EEGLAB default parameters, unless stated otherwise.

**DON'T CHANGE THE ORDER OF THE FOLLOWING PROCESSES.**



### Section 1

0. new a folder for each subject entitled "name+number", e.g `crq1`, and copy the .mat file of this subject generated in the experiment to this folder, then load the data into EEGLAB and select channel location (select the second option "Use MNI...")
1. re-reference to average mastoids (TP9 & TP10) and add original reference channel back as FCz
2. notch at 50Hz, filter between 0.3 ~ 50 Hz
3. bad channel (marked during the experiment **and by automatic channel rejection**) rejection, save the rejected channels' name in `chnRej.mat`
4. interpolate the rejected channels
5. epoch, -1000 ~ 4000ms locked to S1 onset (**no baseline correction**)
6. run ICA
7. save the dataset as "name+number+Epoch.set", e.g. `crq1Epoch.set`

This section can be done automatically using script `Preprocessing.m`.

### Section 2

8. ICA ocular artifact removal, save the rejected component's landscape and activation profile (shown by EEGLAB) as `cmpRej1.fig`, `cmpRej2.fig`, ... (if found)

   <img src = "cmpRejExample.jpg" style = "zoom:30%"/>

9. visual inspection, reject epochs

11. save the dataset as "name+number.set", e.g. `crq1.set`

This section needs to be done manually.

### Section 3

11. seperate the dataset according to the condition and reaction type by `groupDat.m`.



## Data Processing Pipeline in the Original Paper

### EEG Preprocessing

- re-reference to average mastoids (TP9 & TP10, rather than the original nose reference)
- artifact rejection by EEGLAB (e.g., dead channels, channel jumps, etc.)
- Filtered between 0.3 - 50 Hz
- ICA ocular artifact removal
- epoching, -1000 - 4000ms with respect to S1 onset
- visual inspection for epoch rejection
- automatic trial rejection (range of values within a trial at any electrodes > 200uV)

### Event-Related Response Analysis

- averaged seperately for SIMPLE, REVERSED correct, REVERSED incorrect and so on, with equal number of trials (random selected)
- 100ms (before onset of S1) baseline correction
- Statistics test:
  - 250ms binned (totally 8 during retention period), computing the absolute value of the mean
  - cluster-level paired t-test (by FieldTrip) on EEG topologies for each time window, multiple comparison corrected
- ROI defined by overlapping area of the main effects of REVERSED versus SIMPLE, or REVERSED correct vs incorrect, etc.

