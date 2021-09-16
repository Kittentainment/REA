unit module HandleResults;
use Output::DisplayEvaluatedResult;

#| Handles what happens once the results have been generated.
#| Currently it only displays them at the console.
#| But this extra step is for future extendability to also allow a different kind of output, like saving to a file.
sub handleResults(:@results) is export {
    # TODO if there is enough time, we can also save the results to a file here.
    displayResults(:@results)
}