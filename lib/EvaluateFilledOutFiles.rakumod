unit module EvaluateFilledOutFiles;

use IO::Glob;
use ExamFileParser;

#my Str $WRONG_QA_COUNT = "The number of Questions in the MasterFile and the StudentFile do not match";
enum TestFailedReason <
    PARSING_ERROR
    COUNT_ERROR
    MISMATCH_ERROR
>;

enum TestResultWarnings <
    INTRO_MISMATCH
    QUESTION_MISMATCH

>;

class TestResult is export {
    has Str $.fileName is required;
    has Str $.comments;

    method isOK() returns Bool {...}
}

class FailedTestResult is export is TestResult {
    has TestFailedReason $.reason;

    method isOK() returns Bool {
        return False
    }
}

class OkTestResult is export is TestResult {
    has Int $.score is required;
    has Str @.warnings;

    submethod hasWarnings() returns Bool is export {
        return @!warnings.Bool;
    }

    method isOK() returns Bool {
        return True;
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



sub evaluateFilledOutFile(:$parsedMasterFile, :$parsedFilledOutFile) returns TestResult {
    unless ($parsedMasterFile.QACombos.elems == $parsedFilledOutFile.QACombos.elems) {
        return FailedTestResult.new(reason => COUNT_ERROR, fileName => $parsedFilledOutFile.fileName,
                comments => $parsedFilledOutFile.comments);
    }
    #check if intro is there-> warning

}

sub evaluateFilledOutFiles(:$masterFileName, :@filledOutFileNames) is export {
    my $parsedMasterFile = EFParser.new(fileName => $masterFileName);
    die unless isMasterFileOk(:$parsedMasterFile);
    for @filledOutFileNames -> $givenFileName {
        for glob($givenFileName) -> $filledOutFile {
            my $parsedFilledOutFile = EFParser.new(fileName => $filledOutFile.relative);
            evaluateFilledOutFile(:$parsedMasterFile, :$parsedFilledOutFile);
        }
    }

    #    my TestResult $testResult = TestResult.new(fileName => "i'm the FileName", score => 5, comments => "i'm a comment");
    #    say $testResult;
}




