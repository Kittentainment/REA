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
    
    method toString(:$displayWidth) returns Str {
        my Int $resultLength = 18;
        my Str $outputString;
        
        $outputString ~= self!getBlockOfAverage(
                :$displayWidth,
                :$resultLength,
                averageText => "Average number of questions answered",
                minText => "Minimum",
                maxText => "Maximum",
                average => $!averageTries,
                min => $!minTries,
                minCount => $!minTriesCount,
                max => $!maxTries,
                maxCount => $!maxTriesCount);
        
        $outputString ~= "\n";
        
        $outputString ~= self!getBlockOfAverage(
                :$displayWidth,
                :$resultLength,
                averageText => "Average number of correct answers",
                minText => "Minimum",
                maxText => "Maximum",
                average => $!averageScore,
                min => $!minScore,
                minCount => $!minScoreCount,
                max => $!maxScore,
                maxCount => $!maxScoreCount);
        
        return $outputString;
    }
    
    #| A string with the average, minimum and maximum displayed on three different lines
    method !getBlockOfAverage(:$displayWidth,
                              :$resultLength,
                              :$averageText,
                              :$minText,
                              :$maxText,
                              :$average,
                              :$min,
                              :$minCount,
                              :$max,
                              :$maxCount) returns Str {
        my Str $outputString;
        
        $outputString ~= $averageText;
        $outputString ~= '.' x ($displayWidth - $averageText.chars - $resultLength);
        $outputString ~= sprintf("%3d", $average);
        $outputString ~= "\n";
        
        my Str $extendedMinText = ' ' x ($averageText.chars - $minText.chars) ~ $minText;
        $outputString ~= $extendedMinText;
        $outputString ~= '.' x ($displayWidth - $extendedMinText.chars - $resultLength);
        $outputString ~= sprintf("%3d", $min);
        $outputString ~= "  ($minCount student{ $minCount == 1 ?? "" !! "s" })";
        $outputString ~= "\n";
        
        my Str $extendedMaxText = ' ' x ($averageText.chars - $maxText.chars) ~ $maxText;
        $outputString ~= $extendedMaxText;
        $outputString ~= '.' x ($displayWidth - $extendedMaxText.chars - $resultLength);
        $outputString ~= sprintf("%3d", $max);
        $outputString ~= "  ($maxCount student{ $maxCount == 1 ?? "" !! "s" })";
        $outputString ~= "\n";
        
        return $outputString;
    }
    
}

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
    
    my Num $averageScore = calcAverage(@allScores);
    my Int @minMaxScore = calcMinMax(@allScores);
    my Num $averageTries = calcAverage(@allTries);
    my Int @minMaxTries = calcMinMax(@allTries);
    
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
            maxTriesCount => @minMaxTries[3]
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


