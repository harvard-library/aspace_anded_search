# PUI Configurable Search Plugin

This plugin allows for default parameters applied to Solr search to apply to user searches in the PUI.  Functionality here is taken from work done by Mark Triggs on behalf of Yale University in https://github.com/archivesspace/archivesspace/commits/yale-search-updates

In order to set the default operator for search queries to "AND" rather than "OR", you would define the following in `config/config.rb`

```
AppConfig[:solr_params] = {"q.op" => "AND" }
```

For other potential settings of interest, see: https://lucene.apache.org/solr/guide/6_6/the-dismax-query-parser.html and related docs.
