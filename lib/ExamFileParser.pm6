use ExamFileGrammar;

module ExamFileParser {
    class EFParser {
        has $.fileName is required;
        has @.QACombos;
        
        submethod BUILD(:$!fileName) {
            unless ($!fileName.IO.e && $!fileName.IO.r) {
                die "File doesn't exist";
                # TODO better file error handling
            }
            
            my $fileContent = $!fileName.IO.slurp;
            my $parseTree = ExamFileGrammar.parse($fileContent);
            
            # The structure of the parse tree (only the relevant info)
            # $parsed{"QACombo"}[0]{"answers"}{"answer"}[0]{"marker"}
            # $parsed{"QACombo"}[0]{"question"}
            
            for $parseTree{"QACombo"} -> $qaComboParseTree {
                my $question = $qaComboParseTree{"question"}.Str.trim-trailing;
                my $answers = $qaComboParseTree{"answers"};
                my @markedAnswers;
                my @unmarkedAnswers;
                for $answers -> $answer {
                    my $answerText = $answer{"answerText"};
                    if $answer{"marker"}.Str { # .Str not necessary, but just in case, so that there are no bugs if someone uses 0 to mark their answers.
                        @markedAnswers.append($answerText);
                    } else {
                        @unmarkedAnswers.append($answerText);
                    }
                }
                @!QACombos.append(QACombo.new(:$question, :@markedAnswers, :@unmarkedAnswers));
            }
        }
    }
}

class QACombo {
    has $.question is required;
    has @.markedAnswers is required;
    has @.unmarkedAnswers is required;
}


