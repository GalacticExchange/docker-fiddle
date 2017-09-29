class Fiddle < ActiveRecord::Base
  scope :dockerfiles, ->  {where(code_type: :dockerfile)}
  scope :composes, ->  {where(code_type: :compose)}

  has_paper_trail :only => [:update_flag]
  HasTokens.on self
  REPO_ADDRESS = 'galacticx/docker-fiddle'

  attr_accessor :file
  has_tokens :public=>5
  validates_presence_of :code, :code_type

  enum code_type: [:dockerfile, :compose]

  belongs_to :fiddle, :foreign_key => :forked_from_id

  before_validation :generate_tokens, on: :create

  def self.for_token(token)
    find_by_public_token!(token)
  end

  def fork!
    Fiddle.create!({code_type: code_type, code: code, forked_from_id: self.id})
  end

  def to_param
    public_token
  end
end
