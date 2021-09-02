use ExamFileGrammar;

module ExamFileParser {
    
    class QACombo is export {
        has Str $.question is required;
        has Str @.markedAnswers is required;
        has Str @.unmarkedAnswers is required;
    }
    
    
    class EFParser is export {
        has Str $.fileName is required;
        has Str $.intro; #TODO
        has Str $.separator;
        has QACombo @.QACombos;
        
        submethod BUILD(:$!fileName, :$!separator = '_' x 80) {
            unless ($!fileName.IO.e && $!fileName.IO.r) {
                die "File doesn't exist";
                # TODO better file error handling
            }
            
            my Str $fileContent = $!fileName.IO.slurp;
            my Match $parseTree = ExamFileGrammar.parse($fileContent);
#            say $parseTree;
            
            # The structure of the parse tree (only the relevant info)
            # $parsed{"QACombo"}[0]{"answers"}{"answer"}[0]{"marker"}
            # $parsed{"QACombo"}[0]{"answers"}{"answer"}[0]{"answerText"}
            # $parsed{"QACombo"}[0]{"question"}
            
            for $parseTree{"QACombo"} -> $qaComboParseTree {
                my Str $question = $qaComboParseTree{"question"}.Str.trim-trailing;
                my Match $answers = $qaComboParseTree{"answers"};
                my Str @markedAnswers;
                my Str @unmarkedAnswers;
                for $answers{"answer"} -> $answer {
                    my Str $answerText = $answer{"answerText"}.Str;
#                    say $answerText;
                    if $answer{"marker"} {
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




