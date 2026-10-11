Workaround to use maxYMiser tunes
that uses Malloc() to allocate
space for multi-volume PCM-samples.

Sometimes demos will run under
circumstances when there is no OS
running, and the Malloc() calls that
maxYMiser does will not work.

Here's a workaround to emulate the
Malloc() calls made.



1. Measure amount of memory

Run the memcheck.ttp tool on the
tune in question.

The tool will output "Malloced size".
Take a note of that value.


2. Emulate the Malloc()

In your maxYMiser (SNDH) init code,
we need to be a bit naughty to catch
the trap #1 calls from maxYMiser.

See mymfix.s for the code to use.
Adjust the size according to step 1.


3. Pray for a micracle that it works



Original trap patch code made by
GGN/KUA

Bugfixed a bit by Nerve and Evil

Memory measure tool by Evil

