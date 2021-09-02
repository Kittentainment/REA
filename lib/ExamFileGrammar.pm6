#use Grammar::Debugger;

grammar ExamFileGrammar {
    regex TOP {
        <intro>
        [<separator> <QACombo>]+
        <separator>?
        <endOfExam>?
    }
    
    regex separator {
        [^^ \h* '_'+ \h* $$ \n]+?
        # Multiple lines of separator -> one separator (e.g. if someone hits enter inside a separator)
    }
    
    regex intro {
        ^<singleLineExceptSeparator>+
    }
    
    token QACombo {
        \s*
        <question>?
        \s*
        <answers>
        \s* # Not actually necessary, as they are already all in the answers, but just for safety
    }
    
    regex question {
        [<!before [<answer>]><singleLineExceptSeparator>]+
    }
    
    regex answers {
        [<answer>\s*]+
    }
    
    regex answer {
        \h* '[' \s*<marker>?<-[\]]>* ']' \h* <answerText>
    }
    
    regex answerText {
        \N+
    }
    
    regex marker {
        <-[\s\]]>
    }
    
    regex endOfExam {
        ^^
        '=' ** 2..*
        \s*END\h*OF\h*EXAM\s*
        '=' ** 2..*
        $$
    }
    
    regex singleLineExceptSeparator {
        <!before [<separator>]><!before [<endOfExam>]> \N* \n
    }
    
}


#my $parsed = ExamFileGrammar.parse(
#"Complete this exam by placing an 'X' in the box beside each correct
#answer, like so:
#
#    [ ] This is not the correct answer
#    [ ] This is not the correct answer either
#    [ ] This is an incorrect answer
#    [X] This is the correct answer
#    [ ] This is an irrelevant answer
#
#Scoring: Each question is worth 2 points.
#         Final score will be: SUM / 10
#
#Warning: Each question has only one correct answer. Answers to
#         questions for which two or more boxes are marked with an 'X'
#         will be scored as zero.
#
#________________________________________________________________________________
#
#1. The name of this class is:
#
#    [X] Introduction to Perl for Programmers
#    [ ] Introduction to Perl for Programmers and Other Crazy People
#    [ ] Introduction to Programming for Pearlers
#    [ ] Introduction to Aussies for Europeans
#    [ ] Introduction to Python for Slytherins
#
#________________________________________________________________________________
#
#
#
#
#    [ ] Dr Theodor Seuss Geisel
#    [ ] Dr Sigmund Freud
#    [ ] Dr Victor von Doom
#    [X] Dr Damian Conway
#    [ ] Dr Who
#
#________________________________________________________________________________
#
#
#3. The correct way to answer each question is:
#
#    [X] To put an X in the box beside the correct answer
#    [ ] To put an X in every box, except the one beside the correct answer
#    [ ] To put an smiley-face emoji in the box beside the correct answer
#    [ ] To delete the box beside the correct answer
#    [ ] To delete the correct answer
#
#________________________________________________________________________________
#"
#        );
#
##say $parsed{"QACombo"}[0]{"answers"}{"answer"}[0]{"marker"};
#say $parsed{"QACombo"}[0]{"question"}.Str.trim-trailing;