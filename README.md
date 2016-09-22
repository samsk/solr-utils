# solr-utils
Various SOLR utils used by [dob.sk](https://dob.sk) services

# Utils
* **SQLArrayTransformer** for SOLR DataImportHandler (sk.dob.search.solr.dih.SQLArrayTransformer)
  - split array returned from SQL query (tested with PostgresSQL)
  - fields declared with &lt;field> will be splitted

  **Example usage:**
     - Set ``transformer="sk.dob.search.solr.dih.SQLArrayTransformer"``
     - Return array from ``query="select 1 AS id, ARRAY['sk', 'cz', 'en'] AS lang;"``
     - Add ``<field name="lang">``

* [scripts for Nginx Lua module](lua)

# Installation
* Download & unpack or compile as needed
* Load in solrconfig.xml:
    ``<lib dir="/www/_lib/solr" regex="solr-utils(-\d.+)?\.jar" />``
