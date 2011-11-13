# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def processed_image_group(photo, size=:preview)
    if photo.image_processing
      image_group = <<-html
        #{image_tag(photo.image.url(size), :class => "processed_group_loading")}
        #{image_tag(photo.image.url_without_processed(size), "data-src" => photo.image.url_without_processed(size), :class => "processed_group_loaded", :style => "display: none;")}
      html
      image_group.html_safe
    else
      image_tag(photo.image.url(size))
    end
  end

  def clippy(text, bgcolor='#FFFFFF')
    html = <<-EOF
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
              width="110"
              height="14"
              id="clippy" >
      <param name="movie" value="/flash/clippy.swf"/>
      <param name="allowScriptAccess" value="always" />
      <param name="quality" value="high" />
      <param name="scale" value="noscale" />
      <param NAME="FlashVars" value="text=#{text}">
      <param name="bgcolor" value="#{bgcolor}">
      <embed src="/flash/clippy.swf"
             width="110"
             height="14"
             name="clippy"
             quality="high"
             allowScriptAccess="always"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer"
             FlashVars="text=#{text}"
             bgcolor="#{bgcolor}"
      />
      </object>
    EOF
    html.html_safe
  end


  def show_logout
    @current_player && @current_player.user
  end

  def like_button
    subdomain = Rails.env.production? ? 'www' : Rails.env
    "<iframe src=\"http://www.facebook.com/plugins/like.php?href=http%3A%2F%2F#{subdomain}.thematchinggame.com%2F%3Fr%3Dfb&amp;layout=button_count&amp;show_faces=false&amp;width=90&amp;height=20&amp;action=like&amp;colorscheme=light\" scrolling=\"no\" frameborder=\"0\" allowTransparency=\"true\" style=\"border:none; overflow:hidden; width:90px; height:20px\"></iframe>".html_safe
  end

  def twitter_button
    subdomain = Rails.env.production? ? 'www' : Rails.env
    "<a href=\"http://twitter.com/share\" class=\"twitter-share-button\" data-url=\"http://#{subdomain}.thematchinggame.com?r=twitter\" data-text=\"This might be the most amazing thing ever. You must check it out.\" data-count=\"none\" data-via=\"thematchinggame\" data-related=\"jaredcosulich\">Tweet</a><script type=\"text/javascript\" src=\"http://platform.twitter.com/widgets.js\"></script>".html_safe
  end

  def light_box(photo)
    link_to(
        "#{image_tag(photo.image.url(:thumbnail))}<div class='lightbox_text'>Click to Enlarge</div>".html_safe,
        photo.image.url(:large),
        :target => "_blank",
        :class => "lightbox"
    )
  end

  def facebook_connect_button(text, css_class)
    "<a class='#{css_class} fb_button fb_button_medium'><span class='fb_button_text'>#{text}</span></a>".html_safe
  end

  def render_anonymous_warning
    return unless @current_player.anonymous?
#    render :partial => @current_player.photos.empty? ? 'shared/anonymous_message' : 'shared/anonymous_with_photos_message'
    render :partial => 'shared/anonymous_message'
  end

  def need_user_action_to_set_cookie?
    session['player_id'].blank? && request.user_agent[/(WebKit)/] rescue false
  end

  def sparkline(data)
    min = data.min
    max = data.max
    range = max - min
    margin = range / 10
    min -= margin unless min == 0
    image_tag("#{Gchart.line(:size => '660x90', :data => data, :min_value => min, :max_value => max, :axis_with_labels => ['y'])}&chxr=0,#{min},#{max},#{max-min}")
  end

  def clixpy_script
    script = <<-script
      <script type="text/javascript">
        document.write(unescape("%3C")+"script src='"+(document.location.protocol=="https:"?"https://":"http://")+"clixpy.com/clixpy.js?user=5716"+unescape("%26")+"r="+Math.round(Math.random()*10000)+"' type='text/javascript'"+unescape("%3E%3C")+"/script"+unescape("%3E"));
      </script>
    script
    script.html_safe if RAILS_ENV["CLIXPY"] && @current_player && !@current_player.new_record? && Rails.env.production? && !@current_player.admin?
  end

  def social_gold_iframe
    content_tag(:iframe, "", :id => "add_credits", :src => SocialGoldTransaction.buy_credits_url(@current_player.user), :frameborder => "0", :height => "365", :scrolling => "no", :width => "417")
  end

  def user_voice_script
    return unless controller.show_user_voice
    script = <<-javascript
      <script type="text/javascript">
        var uservoiceOptions = {
          key: 'thematchinggame',
          host: 'thematchinggame.uservoice.com',
          forum: '59353',
          alignment: 'left',
          background_color:'#e600b0',
          text_color: 'white',
          hover_color: '#4fa710',
          lang: 'en',
          showTab: true
        };
        function _loadUserVoice() {
          var s = document.createElement('script');
          s.src = ("https:" == document.location.protocol ? "https://" : "http://") + "uservoice.com/javascripts/widgets/tab.js";
          document.getElementsByTagName('head')[0].appendChild(s);
        }
        _loadSuper = window.onload;
        window.onload = (typeof window.onload != 'function') ? _loadUserVoice : function() { _loadSuper(); _loadUserVoice(); };
      </script>
    javascript

  end

  def answer_image(answer, side)
    case answer
      when "good", "interested", "uninterested" :
        image_tag("famfam/#{side}_up.png", :class => "answer_image", :title => "This person said that this was a good match!")
      when "bad" :
        image_tag("famfam/#{side}_down.png", :class => "answer_image", :title => "This person didn't like this match :(")
      else
        image_tag("famfam/help.png", :class => "answer_image", :title => "This person has not rated this match yet.")
    end
  end

  # Men   http://www.google.com/analytics/siteopt/install?experiment=EAAAABi0glHhhUQI6qIbcC_vlZE&account=15570848&user=AN_xLxeAs_yJ3X-I1fO3kXlM6UCXTFMluQA&hl=en_us&portal=0&t=jOQ2zPfpliE
  # Women https://www.google.com/analytics/siteopt/install?experiment=EAAAAKTfK19cUrv9pnkkDR-DtIY&account=15570848&user=AN_xLxd-7_ledf5nrMLxg1_whOemGD97OR8&hl=en_us&portal=0&t=6rKdg1GygjI
  # Gender https://adwords.google.com/analytics/siteopt/install?experiment=EAAAADdQLLslla7c4Zl8DihC30w&account=15570848&user=AN_xLxdb2YCjSen0677IxU1V3AAOXI00EeA&hl=en_us&portal=1&t=4-r6GwpUa-o
  def control_script
    return unless Rails.env.production?
    men_script = <<-html
      <!-- Google Website Optimizer Control Script -->
      <script>
      function utmx_section(){}function utmx(){}
      (function(){var k='1286423360',d=document,l=d.location,c=d.cookie;function f(n){
      if(c){var i=c.indexOf(n+'=');if(i>-1){var j=c.indexOf(';',i);return c.substring(i+n.
      length+1,j<0?c.length:j)}}}var x=f('__utmx'),xx=f('__utmxx'),h=l.hash;
      d.write('<sc'+'ript src="'+
      'http'+(l.protocol=='https:'?'s://ssl':'://www')+'.google-analytics.com'
      +'/siteopt.js?v=1&utmxkey='+k+'&utmx='+(x?x:'')+'&utmxx='+(xx?xx:'')+'&utmxtime='
      +new Date().valueOf()+(h?'&utmxhash='+escape(h.substr(1)):'')+
      '" type="text/javascript" charset="utf-8"></sc'+'ript>')})();
      </script>
      <!-- End of Google Website Optimizer Control Script -->
    html

    women_script = <<-html
      <!-- Google Website Optimizer Control Script -->
      <script>
      function utmx_section(){}function utmx(){}
      (function(){var k='1989837939',d=document,l=d.location,c=d.cookie;function f(n){
      if(c){var i=c.indexOf(n+'=');if(i>-1){var j=c.indexOf(';',i);return c.substring(i+n.
      length+1,j<0?c.length:j)}}}var x=f('__utmx'),xx=f('__utmxx'),h=l.hash;
      d.write('<sc'+'ript src="'+
      'http'+(l.protocol=='https:'?'s://ssl':'://www')+'.google-analytics.com'
      +'/siteopt.js?v=1&utmxkey='+k+'&utmx='+(x?x:'')+'&utmxx='+(xx?xx:'')+'&utmxtime='
      +new Date().valueOf()+(h?'&utmxhash='+escape(h.substr(1)):'')+
      '" type="text/javascript" charset="utf-8"></sc'+'ript>')})();
      </script>
      <!-- End of Google Website Optimizer Control Script -->
    html

    generic_script = <<-html
      <!-- Google Website Optimizer Control Script -->
      <script>
      function utmx_section(){}function utmx(){}
      (function(){var k='3121101002',d=document,l=d.location,c=d.cookie;function f(n){
      if(c){var i=c.indexOf(n+'=');if(i>-1){var j=c.indexOf(';',i);return c.substring(i+n.
      length+1,j<0?c.length:j)}}}var x=f('__utmx'),xx=f('__utmxx'),h=l.hash;
      d.write('<sc'+'ript src="'+
      'http'+(l.protocol=='https:'?'s://ssl':'://www')+'.google-analytics.com'
      +'/siteopt.js?v=1&utmxkey='+k+'&utmx='+(x?x:'')+'&utmxx='+(xx?xx:'')+'&utmxtime='
      +new Date().valueOf()+(h?'&utmxhash='+escape(h.substr(1)):'')+
      '" type="text/javascript" charset="utf-8"></sc'+'ript>')})();
      </script>
      <!-- End of Google Website Optimizer Control Script -->
    html

#    @current_player.gender == 'f' ? women_script : men_script
    generic_script
  end

  def tracking_script
    return unless Rails.env.production?
    men_script = <<-html
      <!-- Google Website Optimizer Tracking Script -->
      <script type="text/javascript">
      if(typeof(_gat)!='object')document.write('<sc'+'ript src="http'+
      (document.location.protocol=='https:'?'s://ssl':'://www')+
      '.google-analytics.com/ga.js"></sc'+'ript>')</script>
      <script type="text/javascript">
      try {
      var gwoTracker=_gat._getTracker("UA-15570848-2");
      gwoTracker._trackPageview("/1286423360/test");
      }catch(err){}</script>
      <!-- End of Google Website Optimizer Tracking Script -->
    html

    women_script = <<-html
      <!-- Google Website Optimizer Tracking Script -->
      <script type="text/javascript">
      if(typeof(_gat)!='object')document.write('<sc'+'ript src="http'+
      (document.location.protocol=='https:'?'s://ssl':'://www')+
      '.google-analytics.com/ga.js"></sc'+'ript>')</script>
      <script type="text/javascript">
      try {
      var gwoTracker=_gat._getTracker("UA-15570848-2");
      gwoTracker._trackPageview("/1989837939/test");
      }catch(err){}</script>
      <!-- End of Google Website Optimizer Tracking Script -->
    html

    generic_script = <<-html
      <!-- Google Website Optimizer Tracking Script -->
      <script type="text/javascript">
      if(typeof(_gat)!='object')document.write('<sc'+'ript src="http'+
      (document.location.protocol=='https:'?'s://ssl':'://www')+
      '.google-analytics.com/ga.js"></sc'+'ript>')</script>
      <script type="text/javascript">
      try {
      var gwoTracker=_gat._getTracker("UA-15570848-2");
      gwoTracker._trackPageview("/3121101002/test");
      }catch(err){}</script>
      <!-- End of Google Website Optimizer Tracking Script -->
    html

#    @current_player.gender == 'f' ? women_script : men_script
    generic_script
  end

  def conversion_script
    return unless Rails.env.production?
    men_script = <<-html
      <!-- Google Website Optimizer Conversion Script -->
      <script type="text/javascript">
      if(typeof(_gat)!='object')document.write('<sc'+'ript src="http'+
      (document.location.protocol=='https:'?'s://ssl':'://www')+
      '.google-analytics.com/ga.js"></sc'+'ript>')</script>
      <script type="text/javascript">
      try {
      var gwoTracker=_gat._getTracker("UA-15570848-2");
      gwoTracker._trackPageview("/1286423360/goal");
      }catch(err){}</script>
      <!-- End of Google Website Optimizer Conversion Script -->
    html

    women_script = <<-html
      <!-- Google Website Optimizer Conversion Script -->
      <script type="text/javascript">
      if(typeof(_gat)!='object')document.write('<sc'+'ript src="http'+
      (document.location.protocol=='https:'?'s://ssl':'://www')+
      '.google-analytics.com/ga.js"></sc'+'ript>')</script>
      <script type="text/javascript">
      try {
      var gwoTracker=_gat._getTracker("UA-15570848-2");
      gwoTracker._trackPageview("/1989837939/goal");
      }catch(err){}</script>
      <!-- End of Google Website Optimizer Conversion Script -->
    html

    generic_script = <<-html
      <!-- Google Website Optimizer Conversion Script -->
      <script type="text/javascript">
      if(typeof(_gat)!='object')document.write('<sc'+'ript src="http'+
      (document.location.protocol=='https:'?'s://ssl':'://www')+
      '.google-analytics.com/ga.js"></sc'+'ript>')</script>
      <script type="text/javascript">
      try {
      var gwoTracker=_gat._getTracker("UA-15570848-2");
      gwoTracker._trackPageview("/3121101002/goal");
      }catch(err){}</script>
      <!-- End of Google Website Optimizer Conversion Script -->
    html

#    @current_player.gender == 'f' ? women_script.html_safe : men_script.html_safe
    generic_script.html_safe
  end

  def user_not_ready
    @no_sidebar || @current_player.nil? || @current_player.new_record? || @current_player.gender.blank?
  end

end
