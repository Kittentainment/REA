use Test;
use ExamFileParser;

#| Parses the given file and checks whether the parsed information matches exactly the given values.
sub checkParser(:$fileName, :$intro, :@questions, :@markedAnswersList, :@unmarkedAnswersList) {
    die if @questions.elems != @markedAnswersList.elems;
    die if @questions.elems != @unmarkedAnswersList.elems;
    
    my $parsed = EFParser.new(:$fileName);
    
    is $parsed.intro, $intro;
    
    my QACombo @allQACombos;
    
    for ^@questions -> $i {
        my Str $question = @questions[$i];
        my Str @markedAnswers = @markedAnswersList[$i];
        my Str @unmarkedAnswers = @unmarkedAnswersList[$i];
        
        @allQACombos.append(QACombo.new(:$question, :@markedAnswers, :@unmarkedAnswers));
    }
    is-deeply $parsed.QACombos, @allQACombos;
}

subtest 'simple exam files' => {
    say "starting simple files tests...";
    checkParser(
            fileName => "t/testResources/OwnFiles/ParserTestFiles/exam-00.txt",
            intro => "This is the intro to the exam file 00\n",
            questions => ("1. first question",
                          "2. second question"),
            markedAnswersList => (("answer 1.1"),
                                  ("answer 2.1")),
            unmarkedAnswersList => (("answer 1.2"),
                                    ("answer 2.2"))
                         );

    checkParser(
            fileName => "t/testResources/OwnFiles/ParserTestFiles/exam-00.txt",
            intro => "This is the intro to the exam file 00\n",
            questions => ("1. first question",
                          "2. second question"),
            markedAnswersList => (("answer 1.1"),
                                  ("answer 2.1")),
            unmarkedAnswersList => (("answer 1.2"),
                                    ("answer 2.2"))
                             );
    
    say "...simple files tests done.";
}


done-testing;
