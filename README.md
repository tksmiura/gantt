# gantt

Create gantt chart from text

## install

  Intall packages below.

    cpan install Time::Moment
    cpan install Text::VisualWidth::PP

## usage

  Create schedule

    # input
    task1 : 2024/11/13-2024/11/19(0%)
    task2 : 2024/11/12 +5 (40%)
    task3 : after task1 +2

  Run gantt.pl

    gantt.pl sample.txt

   get below

    $ ./gantt.pl sample.txt
    schedule : 11/11 11/18
    task1    : __=== ==___
    task2    : _**== =____
    task3    : _____ __**_

   Option -c is ANSI color
   Option -o <file_name> is output SVG
