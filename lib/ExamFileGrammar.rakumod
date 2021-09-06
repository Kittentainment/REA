#use Grammar::Debugger;

grammar ExamFileGrammar {
    regex TOP {
        <intro>
        [<.separator> <QACombo>]+
        <.separator>?
        \s* # For the end
        [<.endOfExam> <comments>?]?
    }
    
    #| Line(s) consisting of only horizontal whitespace and at least 10 equal characters, that are non-space and non-'='.
    #| Multiple lines of separator -> one separator (e.g. if someone hits enter inside a separator)
    #| A separator can't be '=' characters, as they are used for the End of Exam marker.
    regex separator {
        [^^[\h* (<-[\s=]>) \h*] {} [\h* $0 \h*] ** 9..* $$\n?]+
    }
    
    regex intro {
        ^<.singleLineExceptSeparator>+
    }
    
    token QACombo {
        \s*
        <question>?
        \s*
        <answers>
        # \s* # Not actually necessary, as they are already all in the answers
    }
    
    regex question {
        [<!before [<answer>]><.singleLineExceptSeparator>]+
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
    
#    Old version of EoE
#    regex endOfExam {
#        ^^
#        '=' ** 2..*
#        \s*END\h*OF\h*EXAM\s*
#        '=' ** 2..*
#        $$ \n*
#    }

    #| the "End Of Exam" Marker consists of two lines of 2 or more ='s with any text inside
    regex endOfExam {
        ^^
        <.lineOfEquals>
        [\N*\n]+?
        <.lineOfEquals>
        $$
        \s* # take all the space after End Of Exam, so comments are only registered, if there are any non-space characters.
    }

    regex lineOfEquals {
        ^^[\h* '=' \h*] ** 4..* $$\n?
        #^^[<[=\h]>* '=' \h* '=' <[=\h]>]$$ \n
    }
    
    token comments {
        .+
    }
    
    regex singleLineExceptSeparator {
        <!before [<separator>]><!before [<endOfExam>]> \N* \n
    }
    
}
