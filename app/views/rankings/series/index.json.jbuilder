json.series @series do |serie|
  entry = SerieRankingExport.entry(serie, @ranking_ids, comment_brackets: SerieRankingExport::JSON_COMMENT_BRACKETS)
  json.merge! entry.compact
end
