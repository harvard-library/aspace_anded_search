# And'ed Search Plugin

This plugin implements default "and" search, as developed by Yale University in https://github.com/archivesspace/archivesspace/commits/yale-search-updates

To be effective, it needs an 'mm' value set either in the Solr core's defaults, or in the query options.  ASpace has a config option for setting these, which looks like:

```
AppConfig[:solr_params] = {"mm" => proc{ "100%" } }
```

For potential values, see: https://lucene.apache.org/solr/guide/6_6/the-dismax-query-parser.html#TheDisMaxQueryParser-Themm_MinimumShouldMatch_Parameter

