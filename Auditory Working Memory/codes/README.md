### Arguments that you may need to change:

For the left room
  - you need to change the PORTNUM in AudioPlay.m to 53264
  - and the WINID in Experiment.m to 2
  - if you want to debug, change PORTNUM in AudioPlayForTest.m to 53264 too (before other operations)

For the right room
  - you need to change the PORTNUM in AudioPlay.m to 49408
  - and the WINID in Experiment.m to 1
  - if you want to debug, change PORTNUM in AudioPlayForTest.m to 49408 too (before other operations)

If you want to debug, you can change the filename of AudioPlay.m, then change the filename of AudioPlayForTest.m to AudioPlay.m, and change them back after debugging. (of course you can save a copy of the original AudioPlay.m and change the trial numbers, too)

Copy the sti***.mat files to the same directory before running these scripts.