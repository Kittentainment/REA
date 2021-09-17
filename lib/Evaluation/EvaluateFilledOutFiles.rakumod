unit module EvaluateFilledOutFiles;

use IO::Glob;
use Parsing::ExamFileParser;
use Output::DisplayEvaluatedResult;
use Evaluation::Results;
use Evaluation::InexactMatchingHelpers;
use Text::Levenshtein::Damerau;

my Bool $verbose = False;
my Bool $debugging = False;

sub evaluateFilledOutFiles(:$masterFileName, :@filledOutFileNames) is export {
    my EFParser $parsedMasterFile = EFParser
            .new(fileName => $masterFileName) or die "The MasterFile could not be Parsed";
    dieIfMasterFileError(:$parsedMasterFile);
    my TestResult @results = gather {
        for @filledOutFileNames -> $givenFileName {
            for glob($givenFileName) -> $filledOutFile {
                next unless $filledOutFile.f;
                
                my $parsedFilledOutFile;
                try {
                    $parsedFilledOutFile = EFParser.new(fileName => $filledOutFile.relative);
                    CATCH {
                        default {
                            take FailedTestResult.new(failure => FailureInfo.new(failure => PARSING_FAILURE), fileName => $filledOutFile.relative);
                            next;
                        }
                    }
                }
                say "Evaluating file {$parsedFilledOutFile.fileName}" if $verbose;
                take evaluateFilledOutFile(:$parsedMasterFile, :$parsedFilledOutFile);
                say "...Evaluation done" if $debugging;
            }
        }
    }
    
    @results .= sort({ .fileName.Str });
    
    return @results;
}

#| Evaluates the parsed File and returns a TestResult with all the result info.
#| Evaluates the given answers with some inexact matching and tries to find the best match for each answer.
sub evaluateFilledOutFile(:$parsedMasterFile, EFParser :$parsedFilledOutFile) returns TestResult {
    
    my WarningInfo @warnings;
    my Int $score = 0;
    my Int $triedToAnswer = 0;
    my Str $fileName = $parsedFilledOutFile.fileName;
    my Str $comments = $parsedFilledOutFile.comments;
    
    # Warn if intro does not match exactly, as this could be a disadvantage to a student, but ignore if it's a very small difference.
    unless (normalizeAndCheckDistance($parsedMasterFile.intro, $parsedFilledOutFile.intro, maxDifference => 3)) {
        @warnings.append(WarningInfo.new(warning => INTRO_MISMATCH));
    }
    
    my Int @filledOutAnsersIndexedByMasterfile;
    my Int @correctMasterAnswerIndexes;
    
    CHECK_EVERY_QA_COMBO_LOOP:
    for ^$parsedMasterFile.QACombos -> $QAComboIndex {
        say "Comparing question number {$QAComboIndex + 1}" if $debugging;
        # If there is no question from the student file, some questions might have gone missing.
        unless ($parsedFilledOutFile.QACombos[$QAComboIndex]) {
            my Int $actualQuestionCount = $parsedFilledOutFile.QACombos.elems;
            my Int $expectedQuestionCount = $parsedMasterFile.QACombos.elems;
            @warnings.append(WarningInfo.new(warning => QUESTION_COUNT_ERROR, questionNumber => $QAComboIndex,
                    :$actualQuestionCount, :$expectedQuestionCount));
            last;
        }
        
        my $masterQACombo = $parsedMasterFile.QACombos[$QAComboIndex];
        my $filledOutQACombo = $parsedFilledOutFile.QACombos[$QAComboIndex];
        
        # Check if the question is the same, or at least similar (and warn if it is not the same)
        unless ($masterQACombo.question eq $filledOutQACombo.question) {
            if (normalizeAndCheckDistance($masterQACombo.question, $filledOutQACombo.question)) {
                # The question at the same number looks very similar. We assume it's the same, but tell the examiner about it.
                @warnings.append(WarningInfo.new(warning => QUESTION_MISMATCH, questionNumber => $QAComboIndex));
            } else {
                # If the questions don't match at all, we can't evaluate it, as we can't guarantee it's the same question.
                @warnings.append(WarningInfo.new(warning => QUESTION_MISMATCH_ERROR, questionNumber => $QAComboIndex));
                next;
            }
        }
        
        # For every answer in the exam file, find the best matching answer in the master file.
        my Str @filledOutAnswerTexts = $filledOutQACombo.getAllAnswerTexts();
        my Str @masterAnswerTexts = $masterQACombo.getAllAnswerTexts();
        my Str @matchedFilledOutAnswers;
        my Str @unmatchedFilledOutAnswers;
        my Str @unmatchedMasterAnswers;
        my %masterToFilledOutMatcher; # Matches the text of the master answer to it's matched filled out answer (if a match was found).
        
        MASTER_ANSER_LOOP:
        for ^@masterAnswerTexts -> $masterAnswerIndex {
            # take out the first Answer one after the other and compare them.
            my Str $masterAnswerText = @masterAnswerTexts[$masterAnswerIndex];
    
            my Int $shortestDistance;
            my Int $bestFoundAnswerIndex;

            # First check if any answer matches exactly, so we don't have to use the slow Levenshtein for all the non-matching answers. (Extreme performance boost)
            EXACT_MATCHING_TEST:
            for ^@filledOutAnswerTexts -> $filledOutAnswerIndex {
                my Str $filledOutAnswerText = @filledOutAnswerTexts[$filledOutAnswerIndex];
                if ($filledOutAnswerText eq $masterAnswerText) {
                    $shortestDistance = 0;
                    $bestFoundAnswerIndex = $filledOutAnswerIndex;
                    last EXACT_MATCHING_TEST;
                }
            }
            
            unless ($shortestDistance.defined) {
                # If we didn't find an exact match, try to find one with the Levenshtein-Damerau Algorithm.
                GIVEN_ANSWER_TO_COMPARE_TO_LOOP:
                for ^@filledOutAnswerTexts -> $filledOutAnswerIndex {
                    my Str $filledOutAnswerText = @filledOutAnswerTexts[$filledOutAnswerIndex];
                    my Int $distance = dld(normalizeText($masterAnswerText), normalizeText($filledOutAnswerText));
                    # ignore if it's not at least similar:
                    next unless (isGivenDistanceOK(:$distance, expectedText => $masterAnswerText));
                    if (!$shortestDistance.defined || $shortestDistance > $distance) {
                        $shortestDistance = $distance;
                        $bestFoundAnswerIndex = $filledOutAnswerIndex;
                    }
                }
            }
    
            unless ($bestFoundAnswerIndex.defined) {
                # We could not find a match for this answer.
                @unmatchedMasterAnswers.append($masterAnswerText);
                next;
            }
            my $filledOutanswerText = @filledOutAnswerTexts[$bestFoundAnswerIndex];
            unless ($filledOutanswerText eq $masterAnswerText) {
                # We found a match, but only with a certain Damerau Levenshtein Distance. Inform the examiner about it.
                @warnings.append(WarningInfo.new(warning => ANSWER_MISMATCH, questionNumber => $QAComboIndex,
                        expectedAnswerText => $masterAnswerText, actualAnswerText => $filledOutanswerText));
            }
            # Mark the match we found
            %masterToFilledOutMatcher{$masterAnswerText} = $filledOutanswerText;
            
            # Mark the filledOutAnswer as matched, so we can later take all the unmatched ones.
            @matchedFilledOutAnswers.append($filledOutanswerText);
        }
        
        # Now that we matched all the answer texts, check for the score.
        if ($filledOutQACombo.markedAnswers.elems == 1) {
            $triedToAnswer++;
            # The student gave a valid answer. Now we have to check if it is also correct.
            my $singleMarkedAnswerText = $filledOutQACombo.markedAnswers[0];
            my $correctAnswerText = @masterAnswerTexts[0];
            if (%masterToFilledOutMatcher{$correctAnswerText}
                    && %masterToFilledOutMatcher{$correctAnswerText} eq $singleMarkedAnswerText) {
                $score++;
            }
    
        }
        
        # Now for the statistics (Ex 4), mark which answer this file gave (with the corresponding Index of the
        # master file, as the master file is the same for every file, but every filled out file has different answer indexes)
        STATISTICS_GATHERING_LOOP:
        for ^($masterQACombo.getAllAnswerTexts()) -> $currMasterAnswerIndex {
            # Mark the correct answer Index
            my Str $currMasterAnswerText = $masterQACombo.getAllAnswerTexts()[$currMasterAnswerIndex];
            if ($masterQACombo.markedAnswers[0] eq $currMasterAnswerText) {
                # This is the Index of the correct answer. Mark it.
                @correctMasterAnswerIndexes[$QAComboIndex] = $currMasterAnswerIndex;
            }
            # Mark the filled out answer Index
            unless ($filledOutQACombo.markedAnswers.elems == 1) {
                # If they didn't even try to fill out this answer, mark this question index as not filled out.
                @filledOutAnsersIndexedByMasterfile[$QAComboIndex] = Nil;
                last STATISTICS_GATHERING_LOOP;
            }
            if (%masterToFilledOutMatcher{$currMasterAnswerText}
                    && %masterToFilledOutMatcher{$currMasterAnswerText} eq $filledOutQACombo.markedAnswers[0]) {
                # This is the index of the master file answer, which we filled out in the filled out file.
                @filledOutAnsersIndexedByMasterfile[$QAComboIndex] = $currMasterAnswerIndex;
            }
            
        }
        
        # Now find out all the unmatched filledOutAnswers
        for @filledOutAnswerTexts -> $currentText {
            next if grep $currentText, @matchedFilledOutAnswers;
            @unmatchedFilledOutAnswers.append($currentText);
        }

        # Add a warning if we found any answers we couldn't match
        if (@unmatchedFilledOutAnswers || @unmatchedMasterAnswers) {
            @warnings.append(WarningInfo.new(warning => ANSWER_MISMATCH_ERROR, questionNumber => $QAComboIndex,
                    expectedAnswerTexts => @unmatchedMasterAnswers, actualAnswerTexts => @unmatchedFilledOutAnswers));
        }
        
    }
    return OkTestResult.new(:@warnings, :$score, maxScore => $parsedMasterFile.QACombos.elems, :$triedToAnswer,
            :$comments, :$fileName, :@filledOutAnsersIndexedByMasterfile, :@correctMasterAnswerIndexes)
}


sub dieIfMasterFileError(EFParser :$parsedMasterFile) returns Bool {
    for $parsedMasterFile.QACombos -> $QACombo {
        if $QACombo.markedAnswers.elems > 1 {
            die "The MasterFile has multiple correct answers for one of the questions, only one is allowed!";
        }
        if $QACombo.markedAnswers.elems == 0 {
            die "The MasterFile contains a question without a correct answer!";
        }
    };
}


