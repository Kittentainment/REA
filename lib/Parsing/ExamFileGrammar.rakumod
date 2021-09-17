#use Grammar::Debugger;

#| Grammar for an Exam File
grammar ExamFileGrammar {
    #|The highest level of separation for an Exam File, consisting of:
    #|- An intro of any kind of text
    #|- A separator
    #|- QACombos that are separated by a Separator
    #|- Using an End of Exam Marker turns all text that follows it into comments
    regex TOP {
        <intro>
        [<.separator> <QACombo>]+
        <.separator>?
        \s* # in case there is no end of exam, still take all trailing whitespace
        [<.endOfExam> <comments>?]?
    }
    
    #| Line(s) consisting of only horizontal whitespace and at least 10 equal characters, that are non-space and non-'='.
    #| Multiple lines of separator -> one separator (e.g. if someone hits enter inside a separator)
    #| A separator can't be '=' characters, as they are used for the End of Exam marker.
    regex separator {
        [^^                         #Must start at the start of a line
        [\h* (<-[\s=]>) \h*]        #capture any sign that is not "=", ignoring horizontal whitespace
        {}                          #apparently needed to make the captured value into $0
        [\h* $0 \h*] ** 9..*        #repeat the captured value at least 9 times, ignoring horizontal whitespace
        $$\n?                       #must be at the end of the line, also, read in the newline if present
        ]+                          #allow for multiple lines to count as one Separator
    }

    #|A block of any kind of non-separator lines of text
    regex intro {
        ^<.singleLineExceptSeparator>+
    }

    #| QACombos (Question-Answer combos) are a question followed by  answers
    token QACombo {
        \s*
        <question>?
        \s*
        <answers>
        # \s* # Not actually necessary, as they are already all in the answers
    }

    #| A question can be multi-line, as long as it does not qualify as neither separator, EndOfExamMarker nor as an answer
    regex question {
        [<!before [<answer>]><.singleLineExceptSeparator>]+
    }

    #| answers consists of 1 or more answer
    regex answers {
        [<answer>\s*]+
    }

    #| an answer is a line of text that is preceded by [ ], where horizontal whitespace is irrelevant
    #| the answer is separated into a Marker inside [] and AnswerText after
    regex answer {
        \h*             #ignore leading horizontal whitespace
        '['             #match a literal [
        \s*             #ignore any whitespace (incl. newline)
        <marker>?       # match a non-whitespace character if present
        <-[\]]>*        # match any non-] characters
        ']'             # match a literal ]
        \h*             # ignore horizontal whitespace
        <answerText>    # match the rest of the line as answerText
    }

    #| answerText consists of any non-newline characters
    regex answerText {
        \N+
    }

    #| a marker can be any non-whitespace character except for "]"
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

    #| the "End Of Exam" Marker consists of two lines of ='s with any text in between
    regex endOfExam {
        ^^                  # begin at the start of a line
        <.lineOfEquals>     # match a line of equals, ignoring it
        [\N*\n]+?           # match any characters in a line greedily, but match line-by-line non-greedily
        <.lineOfEquals>     # match another line of equals, ignoring it
        $$                  # must be at the end of line
        \s*                 # take all the space after End Of Exam, so comments are only registered, if there are any non-space characters.
    }

    #| a lineOfEquals is a line that consists of at least 4 "=" signs and only horizontal whitespace else
    regex lineOfEquals {
        ^^                      #must start at the beginning of a line
        [\h* '=' \h*] ** 4..*   # match 4 or more "=", ignoring horizontal whitespace
        $$                      # must now be at the end of the line
        \n?                     # if there is a newline, match it
    }

    #| comments is all the text (incl newlines) until the end of the String
    token comments {
        .+
    }

    #| singleLineExceptSeparator is a line of text that is neither a separator nor an endOfExam
    regex singleLineExceptSeparator {
        <!before [<separator>]>         #check if the current line is not a separator
        <!before [<endOfExam>]>         #check if the current line does not match an endOfExam
        \N* \n                          # read a line until and including the newline
    }
    
}
