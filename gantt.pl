#!/usr/bin/perl
#use DateTime;

#https://metacpan.org/pod/Time::Moment
use Time::Moment;
#https://metacpan.org/pod/List::BinarySearch
use List::BinarySearch qw( binsearch  binsearch_pos  binsearch_range );
use Getopt::Long;
use Text::VisualWidth::PP;
use Data::Dumper;

binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";

# 休日など
my @holiday = (
    "2024/01/01",
    "2024/01/08",
    "2024/02/11",
    "2024/02/12",
    "2024/02/23",
    "2024/03/20",
    "2024/04/29",
    "2024/05/03",
    "2024/05/04",
    "2024/05/05",
    "2024/05/06",
    "2024/07/15",
    "2024/08/11",
    "2024/08/12",
    "2024/09/16",
    "2024/09/22",
    "2024/09/23",
    "2024/10/14",
    "2024/11/03",
    "2024/11/04",
    "2024/11/23",

    "2025/01/01",
    "2025/01/13",
    "2025/02/11",
    "2025/02/23",
    "2025/02/24",
    "2025/03/20",
    "2025/04/29",
    "2025/05/03",
    "2025/05/04",
    "2025/05/05",
    "2025/05/06",
    "2025/07/21",
    "2025/08/11",
    "2025/09/15",
    "2025/09/23",
    "2025/10/13",
    "2025/11/03",
    "2025/11/23",
    "2025/11/24",

    );

@Holiday = sort @holiday;

$use_TextVisualWidthPP = 1;
$Text::VisualWidth::PP::EastAsian = 1;     # East asian ambigious width

$TAB_WITDH        = 8;

$COLOR_BG_BLACK   = "\x1b[40m";
$COLOR_BG_RED     = "\x1b[41m";
$COLOR_BG_GREEN   = "\x1b[42m";
$COLOR_BG_YELLOW  = "\x1b[43m";
$COLOR_BG_BLUE    = "\x1b[44m";
$COLOR_BG_MAGENTA = "\x1b[45m";
$COLOR_BG_CYAN    = "\x1b[46m";
$COLOR_BG_WHITE   = "\x1b[47m";

$COLOR_FG_BLACK   = "\x1b[30m";
$COLOR_FG_RED     = "\x1b[31m";
$COLOR_FG_GREEN   = "\x1b[32m";
$COLOR_FG_YELLOW  = "\x1b[33m";
$COLOR_FG_BLUE    = "\x1b[34m";
$COLOR_FG_MAGENTA = "\x1b[35m";
$COLOR_FG_CYAN    = "\x1b[36m";
$COLOR_FG_WHITE   = "\x1b[37m";

$COLOR_BG_LBLACK  = "\x1b[100m";
$COLOR_BG_LRED    = "\x1b[101m";
$COLOR_BG_LGREEN  = "\x1b[102m";
$COLOR_BG_LYELLOW = "\x1b[103m";
$COLOR_BG_LBLUE   = "\x1b[104m";
$COLOR_BG_LMAGENTA= "\x1b[105m";
$COLOR_BG_LCYAN   = "\x1b[106m";
$COLOR_BG_LWHITE  = "\x1b[107m";

$COLOR_FG_LBLACK  = "\x1b[90m";
$COLOR_FG_LRED    = "\x1b[91m";
$COLOR_FG_LGREEN  = "\x1b[92m";
$COLOR_FG_LYELLOW = "\x1b[93m";
$COLOR_FG_LBLUE   = "\x1b[94m";
$COLOR_FG_LMAGENTA= "\x1b[95m";
$COLOR_FG_LCYAN   = "\x1b[96m";
$COLOR_FG_LWHITE  = "\x1b[97m";

$COLOR_REVERSE    = "\x1b[7m";
$COLOR_UNDERLINE  = "\x1b[4m";
$COLOR_BOLD       = "\x1b[1m";
$COLOR_RESET      = "\x1b[0m";

# terminal size
$TERM_WIDTH       = `tput cols`;
$TERM_HEIGHT      = `tput lines`;

# 文字列(YYYY/MM/DD)を日付に変換
sub str2date {
    my ($str_date) = @_;
    my @date = split(/\//, $str_date);

    my $dt = Time::Moment->new(
        year => $date[0],
        month => $date[1],
        day => $date[2],
        );
    return $dt;
}

# 日付間の日数(非稼働日を含む)
sub duration {
    my ($dt1, $dt2) = @_;
    my $delta = $dt1->delta_days($dt2);

    return $delta + 1;
}

# 日付を文字列に変換
sub date2str {
    my ($dt) = @_;
    my $ymd_slash = $dt->strftime('%Y/%m/%d');

    return $ymd_slash;
}

# 日付をMM/DDに変換
sub date2str_short {
    my ($dt) = @_;
    my $md_slash = $dt->strftime('%m/%d');

    return $md_slash;
}

# ２つの日付の間の稼働日を求める
sub workdays {
    my ($dt1, $dt2) = @_;
    my $delta = $dt1->delta_days($dt2);
    my $day = $dt1->day_of_week; # [1=Monday, 7=Sunday]
    # 1 = +0 2 = +1   5 = 4 6 = +5 7 +6, -1;
    my $delta2 += $delta + $day - 1;   #0 is Monday
    my $delta_week = int($delta2 / 7);
    my $non_workday = $delta_week * 2;
    if ($day == 7) {
        $non_workday--;
    }
    if ($delta2 % 7 == 5) {
        $non_workday++;
    }
    if ($delta2 % 7 == 6) {
        $non_workday+=2;
    }
    my $holiday = &count_holiday($dt1, $dt2);
    #print "DEBUG: workdays(): $delta $day $delta2 $delta_week $non_workday $holiday\n";

    return $delta + 1 - $non_workday - $holiday;
}

# 期間内の休日数を返す
sub count_holiday {
    my ($dt1, $dt2) = @_;

    my ($dt1s) = &date2str($dt1);
    my ($dt2s) = &date2str($dt2);

    my( $low_ix, $high_ix )
        = binsearch_range { $a cmp $b } $dt1s, $dt2s, @Holiday;

    if (defined($low_ix)) {
        return $high_ix - $low_ix + 1;
    } else {
        return 0;
    }
}

# 稼働日かチェックする
sub is_workday {
    my ($dt) = @_;
    my $day = $dt->day_of_week; # [1=Monday, 7=Sunday]
    my ($dts) = &date2str($dt);
    if ($day == 6 || $day == 7) {
        #print "debug $dts is sat or sun\n";
        return 0;
    }
    my ($ix) = binsearch {$a cmp $b} $dts, @Holiday;
    if (defined($ix)) {
        #print "debug $dts is holiday($ix, $day)\n";
        return 0;
    }
    #print "debug $dts is workday\n";
    return 1;
}

sub add_workday {
    my ($dt, $d) = @_;
    my $dt2 = $dt->plus_days($d - 1);
    my ($dt2s) = &date2str($dt2);
    my ($workday) = &workdays($dt, $dt2);
    #print "add_workday $dt2s ($workday)\n";
    while ($workday < $d) {
        $dt2 = $dt2->plus_days(1);
        $dt2s = &date2str($dt2);
        #print " add_workday $dt2s\n";
        if (&is_workday($dt2)) {
            $workday++;
        }
    }
    return $dt2;
}

# get string width in console
sub width_str {
    my ($str) = @_;
    if ($use_TextVisualWidthPP)  {
        return Text::VisualWidth::PP::width($str);
    } else {
        # TODO: not support all code in unicode
        # now checking below
        #
        #    ASCII [\x20-\x7E]   1
        #    hankaku kana(japan) 1  (?:\xEF\xBD[\xA1-\xBF]|\xEF\xBE[\x80-\x9F])
        #    latin?(utf8 2byte)  1  (?:[\xC2-\xDF][\x80-\xBF])
        #    other               2
        my $c, $u, $w = 0;

        $c = $str;
        foreach $c (split //, $str) {
            $u = encode_utf8($c);
            if ( $u !~ /(?:\xEF\xBD[\xA1-\xBF]|\xEF\xBE[\x80-\x9F])|(?:[\xC2-\xDF][\x80-\xBF])|[\x20-\x7E]/ ) {
                $w += 2;
            } else {
                $w += 1;
            }
        }
        return $w;
    }
}

# my $dt1 = &str2date("2024/01/02");
# my $dt2 = &str2date("2024/02/04");

# my $delta = &duration($dt1, $dt2);
# my $d1 = &date2str($dt1);
# my $dt3 = $dt2->plus_days(5);
# my $d3 = &date2str($dt3);

# print "$d1 $delta\n";
# print "$d3\n";

# my $workday = &workdays($dt1, $dt2);

# print "workday $workday\n";

# my $non1 = &count_holiday($dt1, $dt2);
# my $non2 = &count_holiday($dt1, $dt1);
# print "test $non1, $non2\n";

# my $dt4 = &add_workday($dt1, 5);
# my $d4 = &date2str($dt4);
# print "add workday $d1 +5 $d4\n";


# input
# task1: 2024/11/13-/2024/11/19(0%)
# task2: 2024/11/12 +5 (40%)
# task3: after task1 +2

# output
#          11/11 11/18
# task1  : __--- --___
# task2  : _**-- -____
# task3  : _____ __--_

GetOptions('debug' => \$opt_debug, 'color' => \$opt_color);

foreach $infile (@ARGV) {
    my (@task_list);

    open FILE, '<:encoding(UTF-8)', $infile || die "Can't open to $infile";
    while ($line = <FILE>) {
        if ($line =~ /\s*#/) {    # コメント無視
        } elsif ($line =~ /\s*(.+):\s*(.*)/) {
            $opt_debug && print "LINE: $line";
            my $task = $1;
            my $schedule = $2;
            my $start, $end, $progress = 0;
            if ($schedule =~ /(\d+\/\d+\/\d+)\s*\-\s*(\d+\/\d+\/\d+)/) {
                $start = &str2date($1);
                $end =&str2date($2);
            } elsif ($schedule =~ /(\d+\/\d+\/\d+)\s*\+\s*(\d+)/) {
                my $days = $2;
                $start = &str2date($1);
                $end = &add_workday($start, $days);
            } elsif ($schedule =~ /after\s+(.*)\+\s*(\d+)/) {
                my $before = $1;
                my $days = $2;

                foreach my $info (@task_list) {
                    $opt_debug && print Dumper $info;
                    $opt_debug && print "debug: $info->[0]\n";
                    if ($info->[0] eq $before) {
                        $opt_debug && print "match $before\n";
                        $start = &add_workday($info->[2], 2);  #start after 1day
                        $end = &add_workday($start, $days);
                        last;
                    }
                }
            } else {
                print "ERROR: $infile: $.: $task : '$schedule' unmatach\n";
                next;
            }

            if ($schedule =~ /\(\s*(\d+)\%\s*\)/) {
                $progress = $1;
            }
            my @info = ($task, $start, $end, $progress);
            push @task_list, \@info;
        }
    }
    #$opt_debug && print Dumper @task_list;

    close FILE;

    # 表示期間を求める
    my $min_day, $max_day;
    foreach my $info (@task_list) {
        my $task     = $info->[0];
        my $start    = $info->[1];
        my $end      = $info->[2];
        my $progress = $info->[3];
        my $start_str = &date2str($start);
        my $end_str = &date2str($end);
        $opt_debug && print "$task : $start_str - $end_str ( $progress % )\n";
        if (! defined($min_day) || $min_day > $start) {
            $min_day = $start;
        }
        if (! defined($max_day) || $max_day < $end) {
            $max_day = $end;
        }
    }
    my $day = $min_day->day_of_week; # [1=Monday, 7=Sunday]
    $min_day = $min_day->minus_days($day - 1);
    $day = $max_day->day_of_week;
    $max_day = $max_day->plus_days(7 - $day);

    if ($opt_color) {
        print "${COLOR_FG_LCYAN}schedule${COLOR_RESET} : ";
        my $day = $min_day;
        while ($day < $max_day) {
            my $day_str = &date2str_short($day);
            print "${COLOR_BG_BLUE}$day_str${COLOR_RESET} ";
            $day = $day->plus_days(7);
        }
        print "\n";

        $max_task_name = 9;
        foreach my $info (@task_list) {
            my $task     = $info->[0];
            my $start    = $info->[1];
            my $end      = $info->[2];
            my $progress = $info->[3];
            my $workedday = int(&workdays($start, $end) * $progress / 100);
            my $current = $start->plus_days($workedday);

            my $width = &width_str($task);
            if ($max_task_name > $width) {
                $task .= " " x ($max_task_name - $width);
            }
            print "${COLOR_FG_LCYAN}$task${COLOR_RESET}: ";
            my $day = $min_day;
            while ($day < $max_day) {
                if ($day->day_of_week == 7) {
                } elsif (! &is_workday($day)) {
                    print " ";
                } elsif ($day >= $start && $day < $current) {
                    print "${COLOR_BG_LYELLOW} ${COLOR_RESET}";
                } elsif ($day >= $start && $day <= $end) {
                    print "${COLOR_BG_GREEN} ${COLOR_RESET}";
                } else {
                    print "${COLOR_UNDERLINE} ${COLOR_RESET}";
                }
                $day = $day->plus_days(1);
            }
            print "\n";
        }
    } else {
        print "schedule : ";
        my $day = $min_day;
        while ($day < $max_day) {
            my $day_str = &date2str_short($day);
            print "$day_str ";
            $day = $day->plus_days(7);
        }
        print "\n";

        $max_task_name = 9;
        foreach my $info (@task_list) {
            my $task     = $info->[0];
            my $start    = $info->[1];
            my $end      = $info->[2];
            my $progress = $info->[3];
            my $workedday = int(&workdays($start, $end) * $progress / 100);
            my $current = $start->plus_days($workedday);

            my $width = &width_str($task);
            if ($max_task_name > $width) {
                $task .= " " x ($max_task_name - $width);
            }
            print "$task: ";
            my $day = $min_day;
            while ($day < $max_day) {
                if ($day->day_of_week == 7) {
                } elsif (! &is_workday($day)) {
                    print " ";
                } elsif ($day >= $start && $day < $current) {
                    print "*";
                } elsif ($day >= $start && $day <= $end) {
                    print "-";
                } else {
                    print "_";
                }
                $day = $day->plus_days(1);
            }
            print "\n";
        }
    }
}
