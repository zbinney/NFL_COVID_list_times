# NFL COVID List Times

This repo contains 2 files:

1. Data from NFL transactions wire from 12-16-2021 to 01-04-2022.

2. Code to refine this into the dates players went on and off the COVID list (with manual adjustments for duplicates/false positive trips) and to produce KM curves.

Right now the code produces a KM curve only for 12/16-27/2021, which was an 11-day period where the NFL allowed players to test off the list at any time with 2 negative antigen tests and/or PCR tests with Ct>35.

You should NOT mix this time period with transactions from 12/28/2021 and later, during which time the NFL allowed players off at 5 days regardless of testing (though they could test off earlier) as long as they were asymptomatic or symptoms were improving.
