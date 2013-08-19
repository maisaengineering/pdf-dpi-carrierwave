class Document
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessible :name,:source

  field :name, type: String

  mount_uploader :source, SourceUploader  ,dependent: :destroy
end
