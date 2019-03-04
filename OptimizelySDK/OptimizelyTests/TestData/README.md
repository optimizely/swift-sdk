# support/datafiles

All datafiles used in compatibility suite specs can be found in this folder. When running `testapp` via docker-compose, this folder is mounted into `DATAFILES_DIR` in the testapp container, making the files available to the testapp (read-only).

If possible, we also try to create an "upstream" test script in optimizely/optimizely.git which "constructs" the datafile by issuing the relevant API calls. For an example of such a script, see [feature_experiments.feature](https://github.com/optimizely/optimizely/blob/devel/src/www/test/bdd/features/fullstack/integration/feature_experiments.feature) which generates [feature_experiments.json](./feature_experiments.json).

At present, the complete list of such datafiles is:

* [experiment_bucketing.json](./experiment_bucketing.json)
* [feature_experiments.json](./feature_experiments.json)
* [feature_flag.json](./feature_flag.json)
