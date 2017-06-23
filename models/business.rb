class Business
  include MongoMapper::Document
  key :listing_id, String
  key :content, Hash
end
