use Grammar::Debugger;

grammar ExamFile {
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
        <question>
        \s*
        <answers>
        \s*
        #        ^^<singleLineExceptSeparator>+
    }
    
    regex question {
        [<!before [<answer>]><singleLineExceptSeparator>]+
    }
    
    regex answers {
        [<answer>\s*]+
    }
    
    regex answer {
        \h* '[' \s*<marker>?<-[\]]>* ']' \N*
    }
    
    regex marker {
        \S
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


say ExamFile.parse(
"this is an intro
____
1. question
answer_1
answer 2
________
2. question
answer
=======
   END OF EXAM
======="
        )
