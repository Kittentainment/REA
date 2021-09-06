unit module ExamFileParser;

use ExamFileGrammar;

#|{
Holds a Question with all its answers.
Stores the answers separately, whether they were marked or not.
}
class QACombo is export {
    has Str $.question is required;
    has Str @.markedAnswers is required;
    has Str @.unmarkedAnswers is required;
    
    submethod getAllAnswerTexts() {
        return (@!markedAnswers, @!unmarkedAnswers).flat;
    }
}

#|{
Parses the given exam file and splits it into its different components.

}
class EFParser is export {
    has Str $.fileName is required;
    has Str $.intro;
    has Str $.separator;
    has QACombo @.QACombos;
    has Str $.endOfExamText;
    
    submethod BUILD(
            :$!fileName,
            :$!separator = '_' x 80,
            :$!endOfExamText = " " x 34 ~ "END OF EXAM" ~ " " x 35) {
        unless ($!fileName.IO.e && $!fileName.IO.r) {
            die "File doesn't exist";
            # TODO better file error handling
        }
        
        my Str $fileContent = $!fileName.IO.slurp;
        my Match $parseTree = ExamFileGrammar.parse($fileContent) or die "Parsing of file $!fileName failed!";
        
        # The structure of the parse tree (only the relevant info)
        # $parsed{"QACombo"}[0]{"answers"}{"answer"}[0]{"marker"}
        # $parsed{"QACombo"}[0]{"answers"}{"answer"}[0]{"answerText"}
        # $parsed{"QACombo"}[0]{"question"}
        
        $!intro = $parseTree{"intro"}.Str;
        
        for $parseTree{"QACombo"} -> $qaComboParseTree {
            my Str $question = ($qaComboParseTree{"question"}.Str.trim-trailing or "");
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

