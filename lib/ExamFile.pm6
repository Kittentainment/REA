grammar ExamFile {
    regex TOP {
        <intro>
        [<separator> <QACombo>]+
        <separator>?
        <endOfExam>?
    }
    
    regex separator {
        ^^ \s*_[\s | _]* $$
    }
    
    regex intro {
        ^ [<-[\n]>*\n]*?  $$ #Test the characters in a line greedily, but test the lines non greedily.
    }
    
}


# asj;lfgjkl\n___________