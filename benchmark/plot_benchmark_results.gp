# Set terminal and output file
set terminal pngcairo size 1920,720 enhanced
set output 'benchmark-plot.png'

# Set background color to Tokyo Night theme
set object 1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb "#1a1b26" behind

# Set title and labels
set title 'Benchmark Results (iPhone 13 - 720p - H265)' textcolor rgb "#f8f8f2"
set xlabel 'Time (s)' textcolor rgb "#f8f8f2"
set ylabel 'Latency (ms)' textcolor rgb "#f8f8f2"

# Define the data file and separator
datafile = 'benchmark.txt'
separator = ' '

# Define the columns to be used for plotting
col_time = 1
col_latency = 2
col_bitrate = 3
col_jitter = 4
col_bytes_sent = 5
col_packets_lost = 6
col_encode_time = 7

# Automatically adjust the x-axis tics
set xtics auto

# Set grid lines
set grid linecolor rgb "#6272a4" lw 0.5

# Set line color and style for latency
set style line 1 lc rgb "#50fa7b" lw 2

# Set line color and style for bitrate
set style line 2 lc rgb "#ff79c6" lw 2

# Set line color and style for jitter
set style line 3 lc rgb "#8be9fd" lw 2

# Set line color and style for bytesSent
set style line 4 lc rgb "#ffb86c" lw 2

# Set border line color
set border linecolor rgb "#f8f8f2"

# Set zero line color
set zeroaxis linecolor rgb "#f8f8f2"

# Set title font
set title font ",14" tc rgb "#f8f8f2"

# Set label font
set xlabel font ",12" tc rgb "#f8f8f2"
set ylabel font ",12" tc rgb "#f8f8f2"

# Set tics font
set xtics font ",10" tc rgb "#f8f8f2"
set ytics font ",10" tc rgb "#f8f8f2"

# Set semi-transparent fill color for the plot area
set style fill transparent solid 0.5 noborder

# Set legend text color
set key textcolor rgb "#f8f8f2"

# Plot the data with multiple axes
plot datafile using col_time:col_latency with lines title 'Latency' linestyle 1, \
     datafile using col_time:col_bitrate axis x1y2 with lines title 'Bitrate (Mbps)' linestyle 2, \
     datafile using col_time:col_jitter axis x1y2 with lines title 'Jitter (s)' linestyle 3, \
     datafile using col_time:col_bytes_sent axis x1y2 with lines title 'Bytes Sent (MB)' linestyle 4
