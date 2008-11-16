class ChatController < ApplicationController
  layout 'chat', :only => :index
  skip_before_filter :verify_authenticity_token

  before_filter :fil, :except => ["filt","filt2"]

  def fil
    unless params[:room].nil?
      unless params[:room] =~ /^[0-9a-zA-Z_]+$/
         redirect_to :controller=>'main',:action=>'index'
      end
      params[:room] = params[:room].toutf8 
      if params[:room].split(//u).length > 10
         redirect_to :controller=>'main',:action=>'index'
      end 
      session[:room] = params[:room] 
    end
    if session[:admin]!="testaaa" then
      #session[:url] = request.env["HTTP_REFERER"]
      #session[:url] = request.remote_ip
      session[:url] = root_url+'main/search'
      #redirect_to :controller=>'chat',:action=>'filt'
      render_component(:controller => 'chat', :action => 'filt')
      #redirect_to :controller=>'chat',:action=>'index'
    end
  end

  def filt2
    session[:admin]="testaaa"
    a = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    @code = (
          Array.new(30) do
            a[rand(a.size)]
          end
    ).join

    session[:privID] = @code + request.env["REMOTE_ADDR"]
    redirect_to :controller=>'chat',:action=>'index'
  end

  def index
    unless session[:room] =~ /^[0-9a-zA-Z_]+$/
       redirect_to :controller=>'main',:action=>'index'
    end
    session[:room] = session[:room].toutf8 
    if session[:room].split(//u).length > 10
       redirect_to :controller=>'main',:action=>'index'
    end  
 
    #session[:url] = @request.env["HTTP_REFERER"] 
    session[:roomID]  = 'chat_'+session[:room]
    session[:url]     ||= 'http://google.com'
    session[:name]    ||= 'guest'
    session[:n_size]  ||= '30'
    session[:n_color] ||= 'black'
    session[:f_font]  ||= '30'
    session[:f_color] ||= 'black'
    @chats = Chat.find_by_sql(["select * from chats where roomID=?",session[:roomID]]).reverse
  end

  def show
    @chat = Chat.find(params[:id])
  end
  
  def test
    @mes = Chat.find(params[:id])
  end

  def test2
    @mes = Urllog.find(params[:id])
  end


  def listen
    session[:name] = params[:name]
    unless params[:Sizes].nil?
      if params[:Sizes] == '1'
         session[:n_size] = '7'
      elsif params[:Sizes] == '2'
         session[:n_size] = '10'
      elsif params[:Sizes] == '3'
         session[:n_size] = '30'
      elsif params[:Sizes] == '4'
         session[:n_size] = '50'
      elsif params[:Sizes] == '5'
         session[:n_size] = '100'
      elsif params[:Sizes] == '6'
         session[:n_size] = '200'
      elsif params[:Sizes] == '7'
         session[:n_size] = '250'
      else
         session[:n_size] = '30'
      end
    end
    unless params[:Colors].nil?
      if params[:Colors] == 'Black'
         session[:n_color] = 'black'
      elsif params[:Colors] == 'White'
         session[:n_color] = 'white'
      elsif params[:Colors] == 'Red'
         session[:n_color] = '#ff0000'
      elsif params[:Colors] == 'Green'
         session[:n_color] = '#00ff00'
      elsif params[:Colors] == 'Yellow'
         session[:n_color] = 'yellow'
      elsif params[:Colors] == 'Blue'
         session[:n_color] = '#0000ff'
      else
         session[:n_color] = 'black'
      end
    end

    render :update do |page|
      page << <<-"EOH"
        meteorStrike[session[:roomID]].update(#{session[:name].to_json});
      EOH
    end

  end

  def talk
    unless params[:Sizes].nil?
      if params[:Sizes] == '1'
         session[:f_size] = '7'
      elsif params[:Sizes] == '2'
         session[:f_size] = '10'
      elsif params[:Sizes] == '3'
         session[:f_size] = '30'
      elsif params[:Sizes] == '4'
         session[:f_size] = '50'
      elsif params[:Sizes] == '5'
         session[:f_size] = '100'
      elsif params[:Sizes] == '6'
         session[:f_size] = '200'
      elsif params[:Sizes] == '7'
         session[:f_size] = '250'
      else
         session[:f_size] = '30'
      end
    end

    unless params[:Colors].nil?
      if params[:Colors] == 'Black'
         session[:f_color] = 'black'
      elsif params[:Colors] == 'White'
         session[:f_color] = 'white'
      elsif params[:Colors] == 'Red'
         session[:f_color] = '#ff0000'
      elsif params[:Colors] == 'Green'
         session[:f_color] = '#00ff00'
      elsif params[:Colors] == 'Yellow'
         session[:f_color] = 'yellow'
      elsif params[:Colors] == 'Blue'
         session[:f_color] = '#0000ff'
      else
         session[:f_color] = 'black'
      end
    end

   unless params[:talk].nil?
      if params[:message].split(//u).length > 100
         params[:message] = 'comment'
      end 
      if session[:roomID].split(//u).length > 100
         session[:roomID] = 'caht1'
      end 
      if session[:privID].split(//u).length > 100
         session[:privID] = 'abcdefg'
      end 

      @pos_x = params[:hf_x].to_i
      @pos_y = params[:hf_y].to_i
      if params[:pos] == 'checked'
         @pos_x = params[:hf_x].to_i - (session[:name].length.to_i - 1) * session[:n_size].to_i
         @pos_y = params[:hf_y].to_i - session[:f_size].to_i / 2
         if @pos_x > 2000
            @pos_x = 2000
         end
         if @pos_y > 2000
            @pos_y = 2000
         end
      else
         @pos_x = rand(400)
         @pos_y = rand(400)
      end
 
      #comment wo suru
      if params[:talk] == 'talk'
         @chat = Chat.new(
            :name => session[:name], :message => params[:message],
            :n_size => session[:n_size], :n_color => session[:n_color],
            :f_size => session[:f_size], :f_color => session[:f_color],
            :user_data => session[:privID], :roomID => session[:roomID] ) 
         if @chat.save
            content2 = render_component_as_string :action => 'show', :id => @chat.id
            content = render_component_as_string :action => 'test', :id => @chat.id, :params => { "pos_x" => @pos_x, "pos_y" => @pos_y }
            javascript = render_to_string :update do |page|
               page.insert_html :top, 'chat-list', content
               if params[:Effects] == 'Highlight'
                  page.visual_effect :highlight, 'lay'+@chat.id.to_s
               elsif params[:Effects] == 'Shake'
                  page.visual_effect :Shake, 'lay'+@chat.id.to_s
               elsif params[:Effects] == 'Fade'
                  page.visual_effect :Fade, 'lay'+@chat.id.to_s
               elsif params[:Effects] == 'Pulsate'
                  page.visual_effect :Pulsate, 'lay'+@chat.id.to_s
               elsif params[:Effects] == 'Fold'
                  page.visual_effect :Fold, 'lay'+@chat.id.to_s
               elsif params[:Effects] == 'DropOut'
                  page.visual_effect :DropOut, 'lay'+@chat.id.to_s, :duration=>'1'
               else
               end
               page.delay(2) do
                  page.remove 'lay'+@chat.id.to_s
               end
               ####chat####
               page.insert_html :top, 'chat-list2', content2 
            end
            Meteor.shoot session[:roomID], javascript

            render :update do |page|
               page[:message].clear #up sitatokini messagewokesu
               page[:message].focus #talk button wo ositatokini focus wo message nisuru
            end
         else
            render :nothing => true
         end
      elsif params[:talk] == 'jump'
         if /^http:/ =~ params[:message]
            @urllogs = Urllog.new(
               :privid => session[:privID], :url => params[:message]) 
            if @urllogs.save
               content = render_component_as_string :action => 'test2', :id => @urllogs.id
               javascript = render_to_string :update do |page|
                  page.insert_html :top, 'chat-list', content
                  page.delay(2) do
                     page.remove 'lay'+@urllogs.id.to_s
                  end
                  page.replace :furl, '<iframe id=furl src='+params[:message]+' style="width:100%; height:100%;" frameborder="0"></iframe>'
               end
               Meteor.shoot session[:privID], javascript
            end
            render :update do |page|
               page[:message].clear #up sitatokini messagewokesu
               page[:message].focus #talk button wo ositatokini focus wo message nisuru
            end
         end
      elsif params[:talk] == 'memo'
         unless params[:message]==""
            javascript = render_to_string :update do |page|
               page.insert_html :top, 'chat-list2', 
                '<font size=4 color="green">memo </font><font>'+ params[:message] + '</font><br>'
            end
            Meteor.shoot session[:privID], javascript
            render :update do |page|
               page[:message].clear #up sitatokini messagewokesu
               page[:message].focus #talk button wo ositatokini focus wo message nisuru
            end
         end
      elsif params[:talk] == 'home'
      # redirect_to :controller=>'main',:action=>'index'
         Meteor.shoot session[:privID],"
            flag = confirm('U-CHATに戻りますか？');
            if (flag) furl.location.href='"+root_url+"main/search';
          "
      elsif params[:talk] == 'image'
         if params[:message] == "heart" || params[:message] == "rails" || params[:message] == "beer" || params[:message] == "acorn" ||  params[:message] == "doughnut" ||  params[:message] == "grape" ||  params[:message] == "cocktail" ||  params[:message] == "ichigo" || params[:message] == "ichou" || params[:message] == "mochituki" || params[:message] == "poinsetia" ||  params[:message] == "sakura" ||  params[:message] == "utiwa" ||  params[:message] == "wine" || params[:message] == "youkan"  then
            if params[:message] == "rails" then  session[:message]="rails.png"
            else session[:message]= params[:message] + '.gif'
            end

            flash[:img_data] = 'img' + rand(10000000).to_s
            content = render_component_as_string :action => 'imgshow',:params => { "pos_x" => @pos_x, "pos_y" => @pos_y }
            javascript = render_to_string :update do |page|
               page.insert_html :top, 'chat-list', content 
               if params[:Effects] == 'Highlight'
                  page.visual_effect :highlight, flash[:img_data] 
               elsif params[:Effects] == 'Shake'
                  page.visual_effect :Shake, flash[:img_data] 
               elsif params[:Effects] == 'Fade'
                  page.visual_effect :Fade, flash[:img_data] 
               elsif params[:Effects] == 'Pulsate'
                  page.visual_effect :Pulsate, flash[:img_data] 
               elsif params[:Effects] == 'Fold'
                  page.visual_effect :Fold, flash[:img_data] 
               elsif params[:Effects] == 'DropOut'
                  page.visual_effect :DropOut, flash[:img_data] , :duration=>'1'
               else
               end
               page.delay(2) do
                  page.remove flash[:img_data] 
               end
           end
            Meteor.shoot session[:roomID], javascript

            render :update do |page|
               page[:message].clear
               page[:message].focus
            end
         else
            render :nothing => true
         end 
      end
    end 

 end

  def event
    message = case params[:event]
    when 'init'; "room is #{session[:roomID]}"
    when 'enter'; "#{params[:uid]} joined."
    when 'leave'; "#{params[:uid]} left."
    end
   # if params[:event] == 'init'
      #message = 'test'
      #@rd = Roomdata.find(:first,["roomID = ?",session[:roomID]])
   # end
   # @chat = Chat.new(
   #         :name => 'system', :message => message,
   #         :n_size => '30', :n_color => '#FFFFFF',
   #         :f_size => '30', :f_color => '#FFFFFF',
   #         :user_data => 'system', :roomID => session[:roomID])
    flash[:sysmes]=message
    render :action => 'show2'
  end
end
