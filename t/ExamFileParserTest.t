use Test;
use ExamFileParser;

#| Parses the given file and checks whether the parsed information matches exactly the given values.
sub checkParser(:$fileName, :$intro, :@questions, :@markedAnswersList, :@unmarkedAnswersList, :$comments) {
    die if @questions.elems != @markedAnswersList.elems;
    die if @questions.elems != @unmarkedAnswersList.elems;

    my $parsed = EFParser.new(:$fileName);

    is $parsed.intro, $intro, "Test Intro";

    my QACombo @allQACombos;

    for ^@questions -> $i {
        my Str $question = @questions[$i];
        my Str @markedAnswers = @markedAnswersList[$i];
        my Str @unmarkedAnswers = @unmarkedAnswersList[$i];

        @allQACombos.append(QACombo.new(:$question, :@markedAnswers, :@unmarkedAnswers));
    }
    is-deeply $parsed.QACombos, @allQACombos, "Test QACombo";
    is $parsed.comments, $comments, "Test Comments"
}


say "Parser Test start...";
subtest "00: Compact, SingleLineIntro, 2Q/2A, No comment" => {
    checkParser(
            fileName => "t/testResources/OwnFiles/ParserTestFiles/exam-00.txt",
            intro => "This is the intro to the exam file 00\n",
            questions => ("1. first question",
                          "2. second question"),
            markedAnswersList => (("answer 1.1"),
                                  ("answer 2.1")),
            unmarkedAnswersList => (("answer 1.2"),
                                    ("answer 2.2")),
            comments => ()
                             );
}

subtest "01: Spaced, MultiLineIntro, 2Q/2A, MultiLineComment" => {
    checkParser(
            fileName => "t/testResources/OwnFiles/ParserTestFiles/exam-01.txt",
            intro => "\nThis is the intro to the exam file 01\nThis is the continuation of the intro to the exam file 01\n\n\n",
            questions => ("1. first question\n    first question second line",
                          "2. second question"),
            markedAnswersList => (("answer 1.1"),
                                  ("answer 2.1")),
            unmarkedAnswersList => (("answer 1.2"),
                                    ("answer 2.2")),
            comments => ("I am a Comment\n\n\nAs am I")
                             );
}
subtest "02: Spaced, MultiLineIntro, 2Q/2A, MultiLineComment, SeparatorVariations" => {
    checkParser(
            fileName => "t/testResources/OwnFiles/ParserTestFiles/exam-02.txt",
            intro => "\nThis is the intro to the exam file 01\nThis is the continuation of the intro to the exam file 01\n\n\n",
            questions => ("1. first question\n    first question second line",
                          "2. second question"),
            markedAnswersList => (("answer 1.1"),
                                  ("answer 2.1")),
            unmarkedAnswersList => (("answer 1.2"),
                                    ("answer 2.2")),
            comments => ("I am a Comment\n\n\nAs am I")
                             );
}

subtest "03: Spaced, MultiLineIntro, 2Q/2A, MultiLineComment, Answervariations" => {
    checkParser(
            fileName => "t/testResources/OwnFiles/ParserTestFiles/exam-03.txt",
            intro => "\nThis is the intro to the exam file 01\nThis is the continuation of the intro to the exam file 01\n\n\n",
            questions => ("1. first question\n    first question second line",
                          "2. second question"),
            markedAnswersList => (("answer 1.1"),
                                  ("answer 2.1")),
            unmarkedAnswersList => (("answer 1.2"),
                                    ("answer 2.2")),
            comments => ("I am a Comment\n\n\nAs am I")
                             );
}


    say "...Parser Test done.";


done-testing;
