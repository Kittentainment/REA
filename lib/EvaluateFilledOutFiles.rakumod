unit module EvaluateFilledOutFiles;

use IO::Glob;
use ExamFileParser;
use DisplayEvaluatedResult;
use Results;
use InexactMatchingHelpers;



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
                take evaluateFilledOutFile(:$parsedMasterFile, :$parsedFilledOutFile);
            }
        }
    }
    
    @results .= sort({ .fileName.Str });
    
    handleResults(:@results);
}


sub evaluateFilledOutFile(:$parsedMasterFile, :$parsedFilledOutFile) returns TestResult {
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






############################################################

#| Evaluates all Questions in both files, if they match exactly (task 1b).
#| Old version of evaluateFilledOutFile. Kept for testing purposes.
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




