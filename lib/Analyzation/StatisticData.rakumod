unit class StatisticData;

use Evaluation::Results;

has Num $.averageScore is required;
has Int $.minScore is required;
has Int $.minScoreCount is required;
has Int $.maxScore is required;
has Int $.maxScoreCount is required;
has Num $.averageTries is required;
has Int $.minTries is required;
has Int $.minTriesCount is required;
has Int $.maxTries is required;
has Int $.maxTriesCount is required;

# tests below expectation
has TestResult @.scoreBelow50perc is required;
has TestResult @.skipped75percQuestions is required;

method toString(:$displayWidth, :$lineIndent) returns Str {
    my Int $resultLength = 20;
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
    
    $outputString ~= "\n";
    $outputString ~= self!getBlockOfBelowExpectations(:$displayWidth, :$resultLength, :$lineIndent);
    
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

#| Returns a string displaying all the results that scored below the expectations and the reason they were included in this list.
method !getBlockOfBelowExpectations(:$displayWidth, :$resultLength, :$lineIndent) returns Str {
    my Str $outputString;
    
    $outputString ~= "Results below expectation:\n";
    for @!scoreBelow50perc -> $result {
        $outputString ~= $result.getResultAsString(:$displayWidth, :$lineIndent, rightIndentAmmount => $resultLength);
        $outputString ~= "  (Score < 50%)\n";
    }
    for @!skipped75percQuestions -> $result {
        $outputString ~= $result.getResultAsString(:$displayWidth, :$lineIndent, rightIndentAmmount => $resultLength);
        $outputString ~= "  (Skipped > 25%)\n";
    }
    
    return $outputString;
}