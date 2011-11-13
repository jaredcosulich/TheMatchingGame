class Admin::ResponsesController < AdminController

  def index
    if params.include?(:a)
      answers = <<-sql
        AND (
          (photo_one_answer = '#{params[:a].split(/:/)[0]}' AND photo_two_answer = '#{params[:a].split(/:/)[1]}') OR
          (photo_two_answer = '#{params[:a].split(/:/)[0]}' AND photo_one_answer = '#{params[:a].split(/:/)[1]}')
        )
      sql
    end
    @response_combos = Combo.find(
      :all,
      :include => :response,
      :conditions => "responses.id is not null#{date_conditions(params, 'and', 'responses', :updated)}#{answers unless answers.blank?}",
      :order => "responses.updated_at desc"
    )
  end

  def progress
    @responses = Response.find(:all, :joins => {:combo => [:photo_one, :photo_two]}, :order => "combos.created_at desc")
    @photo_responses = Hash.new{|h,k| h[k]=[]}
    @total_responses = 0
    @correct_responses = 0
    @responses.each do |response|
      if response.photo_one_answer
        @photo_responses[response.combo.photo_one] << [response.combo.photo_two, response.photo_one_answer]
        @total_responses += 1
        @correct_responses += 1 unless response.photo_one_answer == 'bad'
      end

      if response.photo_two_answer
        @photo_responses[response.combo.photo_two] << [response.combo.photo_one, response.photo_two_answer]
        @total_responses += 1
        @correct_responses += 1 unless response.photo_two_answer == 'bad'
      end
    end
  end
end
