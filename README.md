# time_series_analysis_and_statistics
A toolbox of Matlab functions developed over the course of my neuroscience PhD. Focused on EEG analysis but most functions should be widely applicable.

## Overview of functions

### Plotting functions

#### varplot
![varplot](https://github.com/edden-gerber/time_series_analysis_and_statistics/tree/master/img/varplot.png)
Plot time seriers with variance indicated by shaded area around the curve. Input your 2D data matrix and automatically produce a plot of the mean and variance in a publication-ready graphical format. Completey wraps around the plot() function supporting all of its existing functionality plus additional options for the variance plot. 
For anyone looking at time x trial style data, this can (and should) replace your standard 'plot(mean(data)) command.
