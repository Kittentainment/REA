use Grammar::Debugger;

grammar ExamFile {
    regex TOP {
        <intro>
        [<separator> <QACombo>]+
        <separator>?
        <endOfExam>?
    }
    
    regex separator {
        [^^ \h* '_'+ \h* $$ \n]+? # Multiple lines of separator -> one separator (e.g. if someone hits enter inside a separator)
    }
    
    regex intro {
        ^
        <singleLineExceptSeparator>+
        #^ [<-[\n]>*\n]*?  $$ #Test the characters in a line greedily, but test the lines non greedily.
    }
    
    regex QACombo {
        ^^<singleLineExceptSeparator>+
    }
    
    regex endOfExam {
        ^^
        '=' ** 2..*
        \s*END\h*OF\h*EXAM\s*
        '=' ** 2..*
        $
    }
    
    regex singleLineExceptSeparator {
        ^^<!before [<separator>]><!before [<endOfExam>]> \N* \n
    }
    
}


say ExamFile.parse(
"this is an intro
____
1. question
answer_1
answer 2
____
____
2. question
answer
=======
   END OF EXAM
======="
        )
