class ResponseCorrelator

  def initialize
    @responses = Response.find(:all, :joins => :combo, :order => "combos.created_at desc")
    @photo_likes = Hash.new{|h,k| h[k]=[]}
    @photo_dislikes = Hash.new{|h,k| h[k]=[]}
    @photo_liked_by = Hash.new{|h,k| h[k]=[]}
    @photo_disliked_by = Hash.new{|h,k| h[k]=[]}

    @responses.each do |response|
      if response.photo_one_answer
        subject, object = if response.photo_one_answer == "bad"
          [@photo_dislikes, @photo_disliked_by]
        else
          [@photo_likes, @photo_liked_by]
        end
        subject[response.photo_one_id] << response.photo_two_id
        object[response.photo_two_id] << response.photo_one_id
      end
      if response.photo_two_answer
        subject, object = if response.photo_two_answer == "bad"
          [@photo_dislikes, @photo_disliked_by]
        else
          [@photo_likes, @photo_liked_by]
        end
        subject[response.photo_two_id] << response.photo_one_id
        object[response.photo_one_id] << response.photo_two_id
      end
    end
  end


  def suggestions_for(a_photo_id)
    a_photo_likes = @photo_likes[a_photo_id]
    a_photo_dislikes = @photo_dislikes[a_photo_id]

    in_common_with = Hash.new{|h,k| h[k]= Hash.new{|h,k| h[k] = 0}}


    a_photo_likes.each do |photo_id|
      @photo_liked_by[photo_id].each do |other_liker_id|
        in_common_with[other_liker_id][:like_like] += 1
      end
      @photo_disliked_by[photo_id].each do |other_disliker_id|
        in_common_with[other_disliker_id][:like_dislike] += 1
      end
    end
    a_photo_dislikes.each do |photo_id|
      @photo_liked_by[photo_id].each do |other_liker_id|
        in_common_with[other_liker_id][:dislike_like] += 1
      end
      @photo_disliked_by[photo_id].each do |other_disliker_id|
        in_common_with[other_disliker_id][:dislike_dislike] += 1
      end
    end

    scores = Hash.new{|k,v|k[v] = 0}
    in_common_with.each_pair do|id,counts|
      counts.each_pair{|key, count| scores[id] += (count * ((key == :like_like || key == :dislike_dislike) ? 1 : -1 ))}
    end

    already_comboed_photo_ids = Photo.find(a_photo_id).comboed_photo_ids
    scores.select{ |k,v| v > 3 }.collect { |k,v| @photo_likes[k] }.flatten.uniq - already_comboed_photo_ids
  end
end
