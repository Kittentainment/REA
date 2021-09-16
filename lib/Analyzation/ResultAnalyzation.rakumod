unit module ResultAnalyzation;

use Evaluation::Results;
use Analyzation::StatisticData;

#| Calculates all the important statistic for our Results
#| No existing module calculated the exact things we needed, so we just calculated it ourself.
sub calculateStatistics(:@results) returns StatisticData is export {
    
    my Int @allScores;
    my Int @allTries;

    # Gather all results
    for @results -> $result {
        next unless $result.isOk;
        @allScores.append($result.score);
        @allTries.append($result.triedToAnswer);
    }
    
    # Calculate the basic Values
    my Num $averageScore = calcAverage(@allScores);
    my Int @minMaxScore = calcMinMax(@allScores);
    my Num $averageTries = calcAverage(@allTries);
    my Int @minMaxTries = calcMinMax(@allTries);

    # Gather all the below average students
    my TestResult @scoreBelow50perc;
    my TestResult @skipped75percQuestions;
    for @results -> $result {
        next unless $result.isOk;
        if ($result.score < $result.maxScore / 2) {
            @scoreBelow50perc.append($result)
        }
        if ($result.triedToAnswer < $result.maxScore / 4 * 3) {
            @skipped75percQuestions.append($result);
        }
    }

    return StatisticData.new(
            :$averageScore,
            minScore => @minMaxScore[0],
            minScoreCount => @minMaxScore[1],
            maxScore => @minMaxScore[2],
            maxScoreCount => @minMaxScore[3],
            :$averageTries,
            minTries => @minMaxTries[0],
            minTriesCount => @minMaxTries[1],
            maxTries => @minMaxTries[2],
            maxTriesCount => @minMaxTries[3],
            :@scoreBelow50perc,
            :@skipped75percQuestions
            )
    
}

#| Calculates the average of the given data
sub calcAverage(Int @data) returns Num {
    die "received an empty list" if @data.elems == 0;
    return (([+] @data) / @data.elems).Num;
}

#| Returns a list in the form ($min, $minCount, $max, $maxCount)
sub calcMinMax(Int @data) returns List {
    die "received an empty list" if @data.elems == 0;
    my $min;
    my $minCount;
    my $max;
    my $maxCount;
    
    for @data -> $entry {
        if (!$min.defined || $entry < $min) {
            $min = $entry;
            $minCount = 1;
        } elsif ($entry == $min) {
            $minCount++;
        }
        if (!$max.defined || $entry > $max) {
            $max = $entry;
            $maxCount = 1;
        } elsif ($entry == $max) {
            $maxCount++;
        }
    }
    return ($min, $minCount, $max, $maxCount);
}


