class FrenchPhoneme
  include MongoMapper::Document
  key :phoneme, String
  key :occurrences, Integer
  key :mined, Boolean
  key :_rand, Float
  before_create :set_rand

  def set_rand
    self._rand = rand
  end
end

