class Admin::PhotoPairsController < AdminController

  def index

  end

  def popular_photos
    photo_ids = Photo.popular_ids_from_other_answer(params[:g] || "f").limit(50).offset(params[:offset] ? params[:offset] : nil)
    @photos = Photo.where("id in (#{photo_ids.map(&:id).join(",")})")
  end

end
