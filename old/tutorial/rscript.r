
# Set graphics device to PNG.
fname = 'plot.png'
png(fname)

# Generate the sample.
data = sample(1:3, size={{size.value}}, replace=TRUE, prob=c(.30,.60,.10))

# Turn it into a table.
data = table(data)

# Generate the barplot.
barplot(data)

# Tell the user what happened.
sprintf("Saved plot into file: %s", fname)
