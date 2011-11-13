class Crop < ActiveRecord::Base
  belongs_to :photo
  validates_presence_of :x, :y, :w, :h
end
