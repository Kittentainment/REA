unit module EvaluateFilledOutFiles;

use IO::Glob;
use ExamFileParser;

#my Str $WRONG_QA_COUNT = "The number of Questions in the MasterFile and the StudentFile do not match";
enum TestFailedReason <
    PARSING_ERROR
COUNT_ERROR

>; ## TODO MOve Count Error later

class ErrorInfo is export {
    has TestFailedReason $.reason is required;
    has Int $.questionNumber;

    method isFatal() returns Bool {
        if ($!reason == PARSING_ERROR) {
            return True;
        }
        return False;
    }
}

enum TestResultWarnings <
    INTRO_MISMATCH
    QUESTION_MISMATCH
    ANSWER_MISMATCH
    ANSWER_MISSING
    TOO_MANY_ANSWERS

    QUESTION_MISMATCH_ERROR
    ANSWER_MISMATCH_ERROR
>;

class WarningInfo is export {
    has TestResultWarnings $.warning is required;
    has Int $.questionNumber;
    has Str $.actualQuestionText;
    has Str $.expectedQuestionText;
    has Str $.actualAnswerText;
    has Str $.expectedAnswerText;
    has Num $.mismatchSeverity;
    has Str @.missingAnswersTexts;
    has Bool $.isSevere; ##maybe get better name
}

class TestResult is export {
    has Str $.fileName is required;
    has Str $.comments;

    method isOK() returns Bool {...}
}

class FailedTestResult is export is TestResult {
    has ErrorInfo $.reason is required;

    method isOK() returns Bool {
        return False
    }
}

class OkTestResult is export is TestResult {
    has Int $.score is required;
    has WarningInfo @.warnings;

    submethod hasWarnings() returns Bool is export {
        return @!warnings.Bool;
    }

    method isOK() returns Bool {
        return True;
    }
}

sub evaluateFilledOutFiles(:$masterFileName, :@filledOutFileNames) is export {
    my EFParser $parsedMasterFile = EFParser.new(fileName => $masterFileName);
    die unless isMasterFileOk(:$parsedMasterFile);
    my TestResult @results = gather {
        for @filledOutFileNames -> $givenFileName {
            for glob($givenFileName) -> $filledOutFile {
                my $parsedFilledOutFile;
                try {
                    $parsedFilledOutFile = EFParser.new(fileName => $filledOutFile.relative);
                    CATCH {
                        default {
                            take FailedTestResult.new(reason =>  ErrorInfo.new(reason => PARSING_ERROR), fileName => $filledOutFile.relative);
                            next;
                        }
                    }
                }
                take evaluateFilledOutFile(:$parsedMasterFile, :$parsedFilledOutFile);
            }
        }
    }
    #    my TestResult $testResult = TestResult.new(fileName => "i'm the FileName", score => 5, comments => "i'm a comment");
    #    say $testResult;
}

sub evaluateFilledOutFile(:$parsedMasterFile, :$parsedFilledOutFile) returns TestResult {
    unless ($parsedMasterFile.QACombos.elems == $parsedFilledOutFile.QACombos.elems) {
        return FailedTestResult.new(reason => ErrorInfo.new(reason => COUNT_ERROR), fileName => $parsedFilledOutFile.fileName,
                comments => $parsedFilledOutFile.comments);  ##TODO not fatal
    }
    return evalMatchingExactly(:$parsedMasterFile, :$parsedFilledOutFile);
    #TODO check if intro is there-> warning
}

#| evaluates all Questions in both files, if they match exactly (task 1b)
sub evalMatchingExactly(:$parsedMasterFile, :$parsedFilledOutFile) returns TestResult {
    my Int $score = 0;
    for ^$parsedMasterFile -> $i{
        if ($parsedMasterFile.QACombos[$i].question ne $parsedFilledOutFile.QACombo[$i].question) {
            next; ## but report
            return FailedTestResult.new(reason => ErrorInfo.new(reason => MISMATCH_ERROR), fileName => $parsedFilledOutFile.fileName,
                    comments => $parsedFilledOutFile.comments);
        }
        # check if answers match

        #TODO
        #TODO
        #TODO
    }
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



