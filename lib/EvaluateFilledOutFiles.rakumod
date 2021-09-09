unit module EvaluateFilledOutFiles;

use IO::Glob;
use ExamFileParser;

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
#| some are purely informational, some require the attention of the examiner to ensure correct grading.
enum TestResultWarnings <
    INTRO_MISMATCH
    QUESTION_MISMATCH
    ANSWER_MISMATCH
    ANSWER_MISSING
    TOO_MANY_ANSWERS

    COUNT_ERROR
    QUESTION_MISMATCH_ERROR
    ANSWER_MISMATCH_ERROR
>;

#| WarningInfo stores additional information on the Warning that occurred
class WarningInfo is export {
    has TestResultWarnings $.warning is required;
    has Int $.questionNumber;
    has Str $.actualQuestionText;
    has Str $.expectedQuestionText;
    has Str $.actualAnswerText;
    has Str $.expectedAnswerText;
    has Num $.mismatchSeverity;
    has Str @.missingAnswersTexts;
    #| returns true if the examiner needs to double check the result to ensure correct grading
    method isSevere() returns Bool {
        return True if  ($!warning == COUNT_ERROR ||
                $!warning == QUESTION_MISMATCH_ERROR ||
                $!warning == ANSWER_MISMATCH_ERROR);
        return False;
    }
}

#| superclass for Failed and Ok TestResults
class TestResult is export {
    has Str $.fileName is required;

    #| returns true if the evaluation finished without fatal errors
    method isOK() returns Bool {...}
}

#| A FailedTestResult means that the evaluation failed completely and needs to be done by the examiner
class FailedTestResult is export is TestResult {
    has TestFailedReason $.reason is required;

    #| returns true if the evaluation finished without fatal errors
    method isOK() returns Bool is export {
        return False;
    }
}

class OkTestResult is export is TestResult {
    has Int $.score is required;
    has WarningInfo @.warnings;
    has Str $.comments;

    #| returns true if there are warnings about the evaluation
    submethod hasWarnings() returns Bool is export {
        return @!warnings.Bool;
    }

    #| returns true if the evaluation finished without fatal errors
    method isOK() returns Bool is export {
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
    #    my TestResult $testResult = TestResult.new(fileName => "i'm the FileName", score => 5, comments => "i'm a comment");
    #    say $testResult;
}


#| Evaluates all Questions in both files, if they match exactly (task 1b).
sub evaluateFilledOutFileExactly(:$parsedMasterFile, :$parsedFilledOutFile) returns TestResult {
    my @warnings;
    my Int $score = 0;
    my Str $fileName = $parsedFilledOutFile.fileName;
    my Str $comments = $parsedFilledOutFile.comments;

    #check if intro is matching -> warning

    for ^$parsedMasterFile.QACombos -> $i{
        unless ($parsedFilledOutFile.QACombo[$i]) {
            @warnings.append(WarningInfo.new(warning => COUNT_ERROR, questionNumber => $i));
            last;
        }
        unless ($parsedMasterFile.QACombos[$i].question eq $parsedFilledOutFile.QACombo[$i].question) {
            @warnings.append(WarningInfo.new(warning => QUESTION_MISMATCH_ERROR, questionNumber => $i));
            next;
        }
        # check answers
        {
         # check if exactly one marked answer
         # check if marked answers match
          #=> count++

         # check if number of answers match
            #for each answer in master
            # check all answers for matching exactly
            # return for each mismatch an answer mismatch error incl "expected answer text" question number
        }
    }
    return OkTestResult.new(:@warnings, :$score, :$comments, :$fileName)
}


    #TODO
    #TODO
    #TODO


#TODO check if intro is there-> warning



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



