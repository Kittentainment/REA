unit module EvaluateFilledOutFiles;

use IO::Glob;
use ExamFileParser;
use DisplayEvaluatedResult;

#my Str $WRONG_QA_COUNT = "The number of Questions in the MasterFile and the StudentFile do not match";
#|Fatal Errors, these mean the file could not be evaluated at all and needs to be looked at by the examiner
enum TestFailedReason <
    PARSING_ERROR
>;
# currently not useful, as the parse Error is the only reason
#class ErrorInfo is export {
#    has TestFailedReason $.reason is required;
#    has Int $.questionNumber;
#
#    method isFatal() returns Bool {
#        if ($!reason == PARSING_ERROR) {
#            return True;
#        }
#        return False;
#    }
#}

#| Warnings that came up during evaluation.
#| Some are mostly just informational, some require the attention of the examiner to ensure correct grading.
enum TestResultWarnings (
    INTRO_MISMATCH          => "Intro Mismatch",
    QUESTION_MISMATCH       => "Question Mismatch",
    ANSWER_MISMATCH         => "Answer Mismatch",

    QUESTION_COUNT_ERROR    => "Question Count Error",
    QUESTION_MISMATCH_ERROR => "Question Mismatch Error",
    ANSWER_MISMATCH_ERROR   => "Answer Mismatch Error",
);

#| WarningInfo stores additional information on the Warning that occurred
class WarningInfo is export {
    has TestResultWarnings $.warning is required;
    has Int $.questionNumber;
    has Str $.actualQuestionText;
    has Str $.expectedQuestionText;
    has Str $.actualAnswerText;
    has Str $.expectedAnswerText;
    has Int $.expectedQuestionCount;
    has Int $.actualQuestionCount;
    has Num $.mismatchSeverity;
    has Str @.expectedAnswerTexts;
    has Str @.actualAnswerTexts;
    
    #| True if we are not entirely sure if our grading was correctly parsed.
    method isSevere() returns Bool {
        return True if ($!warning ~~ /Error/);
        return False;
    }
    
    method toSingleLineString(:$symbolForSevereAnswers = '!', :$lineIndent = "\t") returns Str {
        return $lineIndent ~ (self.isSevere ?? $symbolForSevereAnswers !! "") ~ $!warning ~ "\n";
    }
    
    #| Display all the info about this warning on a single string.
    #| Currently this is the only way to display it, but additional methods can always be added.
    method toExtendedString(:$symbolForSevereAnswers = '!', :$lineIndent = "\t") returns Str {
        given $!warning {
            when INTRO_MISMATCH {
                return $lineIndent ~ "Intro Mismatch: This file's intro text differs from the intro in the master file.\n";
            }
            when QUESTION_MISMATCH {
                return $lineIndent ~ "TODO " ~ $!warning.Str ~ "\n";
            }
            when ANSWER_MISMATCH {
                return $lineIndent ~ "TODO " ~ $!warning.Str ~ "\n";
            }
            when QUESTION_COUNT_ERROR {
                return $lineIndent ~ "$symbolForSevereAnswers Question Count Error: Expected $.expectedQuestionCount questions, file only has $.actualQuestionCount questions.\n";
            }
            when QUESTION_MISMATCH_ERROR {
                return $lineIndent ~ "TODO " ~ $!warning.Str ~ "\n";
            }
            when ANSWER_MISMATCH_ERROR {
                my Str $string = $lineIndent ~ $symbolForSevereAnswers;
                if (@!actualAnswerTexts.elems == 0) {# yes this could be made simpler, but it's clearer that way.
                    # Too many expected answers -> answers missing
                    $string ~= "Answers Missing: The following answers were not present for question $!questionNumber:\n";
                    $string ~= self!listAllAnswers(answerList => @!expectedAnswerTexts, lineIndent => $lineIndent x 3);
                }
                elsif (@!expectedAnswerTexts.elems == 0) {
                    # Too many given answers -> new ones were added. Maybe the master file had no correct answer?
                    $string ~= "Too Many Answers: The following answers were added for question $!questionNumber:\n";
                    $string ~= self!listAllAnswers(answerList => @!actualAnswerTexts, lineIndent => $lineIndent x 3);
                }
                else {
                    $string ~= "Answer Mismatch: Some answers don't match the ones from the exam file on question $!questionNumber.\n";
                    $string ~= ($lineIndent x 2) ~ "Expected:\n";
                    $string ~= self!listAllAnswers(answerList => @!expectedAnswerTexts, lineIndent => $lineIndent x 3);
                    $string ~= ($lineIndent x 2) ~ "Actual:\n";
                    $string ~= self!listAllAnswers(answerList => @!actualAnswerTexts, lineIndent => $lineIndent x 3);
                }
                return $string;
            }
        }
        #        return $!warning.Str;
    }
    
    #| Just a helper method for displaying the ANSWER_MISMATCH_ERROR
    method !listAllAnswers(:@answerList, :$lineIndent) {
        my Str $string = "";
        for (@answerList) -> $answerText {
            $string ~= $lineIndent ~ '- ' ~ $answerText ~ "\n";
        }
        return $string;
    }
    
    method Str() returns Str {
        return self.toSingleLineString;
    }
}

#| superclass for Failed and Ok TestResults
class TestResult is export {
    has Str $.fileName is required;
    
    #| returns true if the evaluation finished without fatal errors
    method isOk() returns Bool {...}
}

#| A FailedTestResult means that the evaluation failed completely and needs to be done by the examiner
class FailedTestResult is export is TestResult {
    has TestFailedReason $.reason is required;
    
    #| returns true if the evaluation finished without fatal errors
    method isOk() returns Bool {
        return False;
    }
}

class OkTestResult is export is TestResult {
    has Int $.score is required;
    has Int $.triedToAnswer is required;
    has WarningInfo @.warnings;
    has Str $.comments;
    
    #| returns true if there are warnings about the evaluation
    submethod hasWarnings() returns Bool {
        return @!warnings.Bool;
    }
    
    #| returns true if the evaluation finished without fatal errors
    method isOk() returns Bool {
        return True;
    }
}

sub evaluateFilledOutFiles(:$masterFileName, :@filledOutFileNames) is export {
    my EFParser $parsedMasterFile = EFParser
            .new(fileName => $masterFileName) or die "The MasterFile could not be Parsed";
    die unless isMasterFileOk(:$parsedMasterFile);
    my TestResult @results = gather {
        for @filledOutFileNames -> $givenFileName {
            for glob($givenFileName) -> $filledOutFile {
                next unless $filledOutFile.f;
                
                my $parsedFilledOutFile;
                try {
                    $parsedFilledOutFile = EFParser.new(fileName => $filledOutFile.relative);
                    CATCH {
                        default {
                            take FailedTestResult.new(reason => PARSING_ERROR, fileName => $filledOutFile.relative);
                            next;
                        }
                    }
                }
                take evaluateFilledOutFileExactly(:$parsedMasterFile, :$parsedFilledOutFile);
            }
        }
    }
    
    @results .= sort({ .fileName.Str });
    
    handleResults(:@results);
}


#| Evaluates all Questions in both files, if they match exactly (task 1b).
sub evaluateFilledOutFileExactly(:$parsedMasterFile, :$parsedFilledOutFile) returns TestResult {
    my WarningInfo @warnings;
    my Int $score = 0;
    my Int $triedToAnswer = 0;
    my Str $fileName = $parsedFilledOutFile.fileName;
    my Str $comments = $parsedFilledOutFile.comments;
    
    # Warn if intro does not match exactly, as this could be a disadvantage to a student.
    unless ($parsedMasterFile.intro eq $parsedFilledOutFile.intro) {
        @warnings.append(WarningInfo.new(warning => INTRO_MISMATCH));
    }
    
    
    for ^$parsedMasterFile.QACombos -> $QAComboIndex {
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
        
        # If the questions don't match, we can't evaluate it, as we can't guarantee it's the same question.
        unless ($masterQACombo.question eq $filledOutQACombo.question) {
            @warnings.append(WarningInfo.new(warning => QUESTION_MISMATCH_ERROR, questionNumber => $QAComboIndex));
            next;
        }
        
        # Check if answered correctly.
        if ($filledOutQACombo.markedAnswers.elems == 1) {
            $triedToAnswer++;
            if ($masterQACombo.markedAnswers eq $filledOutQACombo.markedAnswers) {
                $score++;
            }
        }
        
        # Check if any warnings need to be applied for this answer block.
        my @filledOutAnswers = $filledOutQACombo.getAllAnswerTexts();
        
        my @masterAnswers = $masterQACombo.getAllAnswerTexts();
        my @unmatchedFilledOutAnswers = ();
        
        FILLED_OUT_ANSWERS_LOOP:
        while @filledOutAnswers.elems > 0 {
            # take out the first Answer one after the other and check if the answer matches a master answer
            my $filledOutAnswerText = @filledOutAnswers.pop();
            
            MASTER_ANSWERS_TO_COMPARE_TO:
            for ^@masterAnswers -> $masterAnswerIndex {
                if (@masterAnswers[$masterAnswerIndex] eq $filledOutAnswerText) {
                    # found match
                    @masterAnswers.splice($masterAnswerIndex, 1);
                    #remove from MasterAnswers and end the loop for this $filledOutAnswerText
                    next FILLED_OUT_ANSWERS_LOOP;
                }
            }
            # We found no exact match for our $filledOutAnswerText:
            @unmatchedFilledOutAnswers.append($filledOutAnswerText);
        }
        
        # @masterAnswers now holds only the unmatched ones.
        if (@unmatchedFilledOutAnswers || @masterAnswers) { #if any has elements
            @warnings.append(WarningInfo.new(warning => ANSWER_MISMATCH_ERROR, questionNumber => $QAComboIndex,
                    expectedAnswerTexts => @masterAnswers, actualAnswerTexts => @unmatchedFilledOutAnswers));
        }
        
        
        
        # check if number of answers match
        #for each answer in master
        # check all answers for matching exactly
        # return for each mismatch an answer mismatch error incl "expected answer text" question number
    }
    return OkTestResult.new(:@warnings, :$score, :$triedToAnswer, :$comments, :$fileName)
}



sub isMasterFileOk(EFParser :$parsedMasterFile) {
    for $parsedMasterFile.QACombos -> $QACombo {
        if $QACombo.markedAnswers.elems > 1 {
            die "The MasterFile has multiple correct answers for one of the questions, only one is allowed";
        }
        if $QACombo.markedAnswers.elems == 0 {
            die "The MasterFile contains a question without a correct answer";
        }
    };
    return 1;
}



