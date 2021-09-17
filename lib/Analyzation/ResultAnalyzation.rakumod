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

    my %worstAnsweredQuestions = getWorstAnsweredQuestions(:@results);

    my List @allPossibleCheaters = getPossibleCheaters(:@results, worstAnsweredQuestionIndexes => %worstAnsweredQuestions.keys);
    say @allPossibleCheaters[0][0];
    say @allPossibleCheaters[0][1];
    say @allPossibleCheaters[0][2];
    say @allPossibleCheaters.elems;

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
            :@skipped75percQuestions,
            :%worstAnsweredQuestions,
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

#| Gets the $count worst answered questions in the given results.
#| Returns a Hash with keys as question numbers and values as number of wrong answers.
sub getWorstAnsweredQuestions(:@results, :$worstQuestionCount = 3) returns Hash {
    # Stores for each question number the count of wrong answers
    my Int @numberOfWrongAnswersPerQuestion;

    say "result count: " ~ @results.elems;
    for @results -> $result {
        next unless $result.isOk();
        die "Somehow the filledOutAnsersIndexedByMasterfile has a different count than the correctMasterAnswerIndexes! This should never happen. Please contact the devs." unless $result
                .filledOutAnsersIndexedByMasterfile.elems == $result.correctMasterAnswerIndexes.elems;
        for ^$result.filledOutAnsersIndexedByMasterfile -> $index {
            if (!$result.filledOutAnsersIndexedByMasterfile[$index].defined
                    || $result.filledOutAnsersIndexedByMasterfile[$index]
                    != $result.correctMasterAnswerIndexes[$index]) {
                if (@numberOfWrongAnswersPerQuestion[$index]) {
                    @numberOfWrongAnswersPerQuestion[$index]++;
                } else {
                    @numberOfWrongAnswersPerQuestion[$index] = 1;
                }
            }
        }
    }
    say @numberOfWrongAnswersPerQuestion;
    say @numberOfWrongAnswersPerQuestion.elems;
    say "";

    # Maps the worst question numbers (keys) to their number of wrong answers (values)
    my %worstQuestionIndexes;

    # Now check which $worstQuestionCount questions have the highest wrong answers:
    for ^@numberOfWrongAnswersPerQuestion -> $iteratorIndex {
        say "current Index = $iteratorIndex";
        my Int $numberOfWrongAnswersToBeChecked = @numberOfWrongAnswersPerQuestion[$iteratorIndex];

        if (%worstQuestionIndexes.keys.elems < $worstQuestionCount) {
            # If we have fewer than the required questions, just add it (= adds the first $worstQuestionCount indexes)
            %worstQuestionIndexes{$iteratorIndex} = $numberOfWrongAnswersToBeChecked;
            say $iteratorIndex;
            next;
        }

        # We take the key from %worstQuestionIndexes with the lowest corresponding value.
        # Either this one gets replaced, or none at all.
        say %worstQuestionIndexes;
        my Str $keyWithTheLowestValue = (%worstQuestionIndexes.sort: *.value)[0].key;
        if (%worstQuestionIndexes{$keyWithTheLowestValue} < $numberOfWrongAnswersToBeChecked) {
            # We found a worse answered Question. Replace the best of the already found worst answered questions.
            %worstQuestionIndexes{$keyWithTheLowestValue}:delete;
            %worstQuestionIndexes{$iteratorIndex} = $numberOfWrongAnswersToBeChecked;
        }
    }

    return %worstQuestionIndexes;

}

#| Returns all probable cheating pairs and their calculated probability
#| In the form ($resultA, $resultB, $prob)
sub getPossibleCheaters(:@results, :@worstAnsweredQuestionIndexes, :$probabilityThreshold = 0.4, :$wrongQuestionThreshold = 3,
                        :$numberOfAnswersPerQuestion = 5) {
    # filter out all results, that disqualify because they have enough correct answers
    my @filteredResults = @results.grep(-> $result {
        $result.isOk() && ($result.maxScore - $result.score) >= $wrongQuestionThreshold
    });
    say "Number of filtered elements" ~ @filteredResults.elems;
    return gather {
        for ^@filteredResults -> $resultAIndex {
            my TestResult $resultA = @filteredResults[$resultAIndex];
            next unless ($resultA.isOk);

            for ($resultAIndex + 1) .. (@filteredResults - 1) -> $resultBIndex {
                my TestResult $resultB = @filteredResults[$resultBIndex];
                next unless ($resultB.isOk);
                #next unless $resultA.isSame($resultB); # Not necessary as we start at $resultAIndex + 1

                my $prob = getCheatingProbability(:$resultA, :$resultB, :$numberOfAnswersPerQuestion, :@worstAnsweredQuestionIndexes);
                if ($prob >= $probabilityThreshold) {
                    take ($resultA, $resultB, $prob);
                }
            }
        }
    }
}



sub postfix:<!>($n) {
    return [*] 1..$n
}

sub getCheatingProbability(:$resultA, :$resultB, :$numberOfAnswersPerQuestion, :@worstAnsweredQuestionIndexes) {
    # as a base metric we take the probability of such a match based on randomly choosing the wrong answers.
    # but since not every question is as reasonable as the others, we need to adjust a little
    my Int $numberOfWrongAnswersInCommon = 0;       # -> the higher the MORE likely
    my Int $numberOfDifferentAnswers = 0;           # -> the higher the LESS likely
    my Int $questionCount = $resultA.maxScore;
    
    # Evaluate all the questions
    for ^$questionCount -> $questionNumber {
        if (!$resultA.filledOutAnsersIndexedByMasterfile[$questionNumber].defined || !$resultB.filledOutAnsersIndexedByMasterfile[$questionNumber].defined) {
            say "$questionNumber: undefined.";
            # At least one of the students didn't answer the question.
            # Check if one answered and therefore they have different answers which indicates less cheating probability.
            if (!$resultA.filledOutAnsersIndexedByMasterfile[$questionNumber].defined && !$resultB.filledOutAnsersIndexedByMasterfile[$questionNumber].defined) {
                next;
            } else {
                $numberOfDifferentAnswers++;
                next;
            }
        }
        # Now the questions have both been answered.

        if ($resultA.filledOutAnsersIndexedByMasterfile[$questionNumber] == $resultA.correctMasterAnswerIndexes[$questionNumber]
                && $resultB.filledOutAnsersIndexedByMasterfile[$questionNumber] == $resultB.correctMasterAnswerIndexes[$questionNumber]) {
            # Skip if both answers are correct.
            say "$questionNumber: answered correctly.";
            next;
        }
        if ($resultA.filledOutAnsersIndexedByMasterfile[$questionNumber] != $resultB.filledOutAnsersIndexedByMasterfile[$questionNumber]) {
            # This question lowers the probability that they cheated, as they answered differently.
            say "$questionNumber: answered differently: A={$resultA.filledOutAnsersIndexedByMasterfile[$questionNumber]}; B={$resultB.filledOutAnsersIndexedByMasterfile[$questionNumber]}";
            $numberOfDifferentAnswers++;
            next;
        }
        # Now we know they didn't answer correctly and didn't answer differently
        # => This question was answered the same wrong way.
        unless ($questionNumber (elem) @worstAnsweredQuestionIndexes.Set) {
            # This question was among the hardest three questions.It's ok if they both answered the same wrong way.
            say "skipping worstAnsweredQuestionIndexes";
            next;
        }
        say "found a $numberOfWrongAnswersInCommon";
        $numberOfWrongAnswersInCommon++;
    }
    
    # We only look at the answers they did not answer both correctly.
    my Int $significantQuestionsCount = $numberOfDifferentAnswers + $numberOfWrongAnswersInCommon;

    my $probabilityOfSameWrongAnswerPerQuestion = (($numberOfAnswersPerQuestion - 1) / $numberOfAnswersPerQuestion) * (1/$numberOfAnswersPerQuestion);

    my $p = $probabilityOfSameWrongAnswerPerQuestion;
    my $K = $numberOfWrongAnswersInCommon;
    my $n = $significantQuestionsCount;
    
    say "K: $K";
    # probability that we have at least the amount of $numberOfWrongAnswersInCommon
    my $probability = 0;
    for ^$K -> $k {
        say "loop $k";
        $probability += ($n! / ($k! * ($n-$k)! )) * $p ** $k * (1 - $p) ** ($n - $k);
    }
    # From https://www.mathelike.de/abi-check-mathe-abi-skript-bayern/3-stochastik/3-2-urnenmodelle/3-2-2-berechnung-von-wahrscheinlichkeiten.html?dt=1631897757708
    
    
    say $probability;
    #chance of a specific wrong answer: 1/($numberOfPossibleAnswers-1)
    return $probability;
}
