unit module ResultAnalyzation;


class StatisticData is export {
    has Num $.averageScore;
    has Int $.minScore;
    has Int $.minScoreCount;
    has Int $.maxScore;
    has Int $.maxScoreCount;
    has Num $.averageTries;
    has Int $.minTries;
    has Int $.minTriesCount;
    has Int $.maxTries;
    has Int $.maxTriesCount;
}


sub calculateStatistics(:@results) returns StatisticData is export {
    
    my Int @allScores;
    my Int @allTries;
    
    # Gather all results
    for @results -> $result {
        next unless $result.isOk;
        @allScores.append($result.score);
        @allTries.append($result.triedToAnswer);
    }
    
    my Num $averageScore = calcAverage(@allScores);
    my Int $minMaxScore = calcMinMax(@allScores);
    my Num $averageTries = calcAverage(@allTries);
    my Int $minMaxTries = calcMinMax(@allTries);
    
    return StatisticData.new(
            :$averageScore,
            minScore => $minMaxScore[0],
            minScoreCount => $minMaxScore[1],
            maxScore => $minMaxScore[2],
            maxScoreCount => $minMaxScore[3],
            :$averageTries,
            minTries => $minMaxTries[0],
            minTriesCount => $minMaxTries[1],
            maxTries => $minMaxTries[2],
            maxTriesCount => $minMaxTries[3]
            )
    
}

#| Calculates the average of the given data
sub calcAverage(Int @data) returns Num {
    die "received an empty list" if @data.elems = 0;
    return (([+] @data) / @data.elems).Num;
}

#| Returns a list in the form ($min, $minCount, $max, $maxCount)
sub calcMinMax(Int @data) returns List {
    die "received an empty list" if @data.elems = 0;
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
        if (!$max.defined || $entry < $max) {
            $max = $entry;
            $maxCount = 1;
        } elsif ($entry == $max) {
            $maxCount++;
        }
    }
    return ($min, $minCount, $max, $maxCount);
}


