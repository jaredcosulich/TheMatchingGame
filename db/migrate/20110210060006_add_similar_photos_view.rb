class AddSimilarPhotosView < ActiveRecord::Migration
  def self.up
    execute(similar_photos_view)
  end

  def self.down
  end

  def self.similar_photos_view
<<SQL
DROP VIEW IF EXISTS similar_photos;
CREATE OR REPLACE VIEW similar_photos AS
SELECT photo_pairs.photo_id as photo_id, similar_photo_pairs.photo_id as similar_photo_id, (sum(case when abs(photo_pairs.yes_percent - similar_photo_pairs.yes_percent) < 40 then 1 else 0 end) - sum(case when abs(photo_pairs.yes_percent - similar_photo_pairs.yes_percent) > 60 then 1 else 0 end)) as similar_count
FROM photo_pairs, photo_pairs similar_photo_pairs
WHERE photo_pairs.other_photo_id = similar_photo_pairs.other_photo_id AND photo_pairs.photo_id != similar_photo_pairs.photo_id AND photo_pairs.vote_count > 0 AND similar_photo_pairs.vote_count > 3
GROUP BY photo_pairs.photo_id, similar_photo_pairs.photo_id
SQL
  end

end
