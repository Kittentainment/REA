unit module Results;

#| The Types of warnings that can come up during evaluation of a file.
#| Some are mostly just informational, some require the attention of the examiner to ensure correct grading.
enum TestResultWarnings is export (
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
    
    #| Display all the info about this warning on a single string.
    method toSingleLineString(:$symbolForSevereAnswers = '!', :$lineIndent = "\t") returns Str {
        return $lineIndent ~ (self.isSevere ?? $symbolForSevereAnswers !! "") ~ $!warning ~ "\n";
    }
    
    #| Display all the info about this warning.
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



#| Fatal Errors
#| These mean the file could not be evaluated at all and needs to be looked at by the examiner.
enum TestFailedReason is export (
    PARSING_FAILURE => "Parsing Failure"
);

#| Failures that were thrown during evaluation of a file.
#| These all mean we completely failed to evaluate this file.
#| Maybe we were handed the wrong file, maybe there's an edge case our grammar can't handle.
#| (Not currently necessary to build a class around the TestFailedReason, but for consistency with WarningInfo and extendability)
class FailureInfo is export {
    has TestFailedReason $.failure is required;
    
    method toSingleLineString(:$lineIndent = "\t") returns Str {
        return $lineIndent ~ $!failure.uc ~ "\n";
    }
    
    method Str() returns Str {
        return self.failure;
    }
}




#| Superclass for Failed and Ok TestResults.
#| Holds all the resulting info from evaluating a single file.
class TestResult is export {
    has Str $.fileName is required;
    
    #| returns true if the evaluation finished without fatal errors.
    method isOk() returns Bool {...}

    method getResultAsString(:$displayWidth) returns Str {...}
    
}

#| An OkTestResult means the evaluation succeeded at least partially. Maybe some warnings were thrown, that need to be looked at.
class OkTestResult is TestResult is export {
    has Int $.score is required;
    has Int $.triedToAnswer is required;
    has WarningInfo @.warnings;
    has Str $.comments;
    
    #| returns true if there are warnings about the evaluation
    submethod hasWarnings() returns Bool {
        return @!warnings.Bool;
    }
    
    #| returns true if the evaluation finished without fatal errors.
    method isOk() returns Bool {
        return True;
    }

    method getResultAsString(:$displayWidth) returns Str {
        my $string = "";
        $string ~= $.fileName;
        
        $string ~= '.' x ($displayWidth - $.fileName.chars - 5);
        $string ~= sprintf("%02d/%02d", self.score, self.triedToAnswer);
        
        return $string;
    }
    
    method getWarningsAsString() returns Str {
    
    }
}

#| A FailedTestResult means that the evaluation failed completely and needs to be done by the examiner.
class FailedTestResult is TestResult is export {
    has FailureInfo $.failure is required;
    
    #| returns true if the evaluation finished without fatal errors.
    method isOk() returns Bool {
        return False; # Failures are always fatal, meaning this file could not be evaluated.
    }

    method getResultAsString(:$displayWidth) returns Str {
        my $string = "";
        $string ~= $.fileName;
        
        $string ~= '.' x ($displayWidth - $.fileName.chars - self.failure.Str.chars);
        $string ~= self.failure.Str;
        
        return $string;
    }
}


