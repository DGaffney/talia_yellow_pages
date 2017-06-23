class TopicMiner
  include Sidekiq::Worker
  sidekiq_options queue: :topic_miner_talia
  def perform(fp_id, phoneme_range=6)
    fp = FrenchPhoneme.find(fp_id)
    topics = get(fp.phoneme.gsub("'", " "))["hits"].collect{|s| s["search01"]}
    BusinessTopic.collection.insert(topics.collect{|t| {topic: t}}) if !topics.empty?
    topics.collect{|a| 1.upto(phoneme_range).collect{|x| a[0..x]}}.flatten.counts.each do |phoneme, count|
      nfp = FrenchPhoneme.first_or_create(phoneme: phoneme)
      nfp.occurrences ||= 0
      nfp.occurrences += count
      nfp.mined ||= false
      nfp.save!
    end
    fp.mined = true
    fp.save!
#    if Sidekiq::Queue.new("topic_miner_talia").size < 1000
#      fp = FrenchPhoneme.where(mined: false, :_rand.gte => rand).first
#      TopicMiner.perform_async(fp.id) if fp
#    end
  end

  def get(topic)
    JSON.parse(request(topic))
  end

  def request(topic)
    `curl 'https://dsk3ufaxut-1.algolianet.com/1/indexes/PROD_QuiQuoiPub/query?x-algolia-agent=Algolia%20for%20vanilla%20JavaScript%203.22.1&x-algolia-application-id=DSK3UFAXUT&x-algolia-api-key=30a9c866c7245bafc39b9d3612ca1a95' -H 'Origin: https://www.pagesjaunes.fr' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36' -H 'content-type: application/x-www-form-urlencoded' -H 'accept: application/json' -H 'Referer: https://www.pagesjaunes.fr/' -H 'Connection: keep-alive' -H 'DNT: 1' --data '{"params":"query=#{topic}&getRankingInfo=1&hitsPerPage=10&allowTyposOnNumericTokens=0&useQueryEqualsOneAttributeInRanking=0&facets=&facetFilters=&distinct=1"}' --compressed`
  end
  
  def self.kickoff
    topics = []
    searches = "a".upto("z").to_a
    searches.each do |search|
      fp = FrenchPhoneme.first_or_create(phoneme: search)
      fp.occurrences ||= 0
      fp.mined ||= false
      fp.save!
      TopicMiner.perform_async(fp.id)
    end
  end
end
