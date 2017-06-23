class BusinessMiner
  include Sidekiq::Worker
  sidekiq_options queue: :topic_miner_talia
  def get(business_topic, page, place)
    Nokogiri.parse(open("https://www.pagesjaunes.fr/annuaire/chercherlespros?quoiqui=boulangerie&ou=#{CGI.escape(place)}&idOu=L07505600&proximite=0&quoiQuiInterprete=#{CGI.escape(business_topic)}&contexte=jXIl2HqvYgcgFNh5quJAUriBXw3k7n%2B5zL2JJnpfRGU%3D&page=#{page}").read)
  end
  def parse(page, business_topic, page_count, place)
    lat_lons = Hash[JSON.parse(page.search("div.map-actions div#mapcontour").first.attributes["data-pjcartecontour"])["listePastilles"].collect{|x| [x["blocAjax"]["data"]["bloc_id"], x["coordonnees"]["coordinates"]]}]
    parsed_listings = []
    page.search("article.bi-bloc").each do |listing|
      listing_id = listing.attributes["id"].value.split("-").last
      parsed_listings << {
        link: listing.search(".pj-link")[2].attributes["href"].value,
        business_name: listing.search("h2")[0].search("a").last.children.text.strip,
        address: listing.search("div.main-adresse-container a").first.children.text.strip,
        business_topic: business_topic,
        page: page_count,
        place: place,
        listing_id: listing_id,
        lat: lat_lons[listing_id].first,
        lon: lat_lons[listing_id].last
      }
    end
    return parsed_listings
  end
  
  def perform(business_topic, place="Paris 75")
    first_page = get(business_topic, 1, place)
    all_businesses = parse(first_page, business_topic, 1, place)
    total_pages = first_page.search("span.pagination-compteur").last.inner_html.split(" ").last.to_i
    2.upto(total_pages) do |page_count|
      puts page_count
      parse(first_page, business_topic, page_count, place).each do |listing|
        all_businesses << listing
      end
    end
    all_businesses.each_slice(1000) do |business_slice|
      Business.collection.insert(business_slice.collect{|x| {listing_id: x[:listing_id], content: x}})
    end
  end
  
  def self.kickoff
    BusinessTopic.to_a.uniq.each do |topic|
      BusinessMiner.perform_async(topic)
    end
  end
end

