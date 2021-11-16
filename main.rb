#!/user/bin/env ruby
require 'sinatra'
require 'dm-core'
require 'dm-migrations'


enable :sessions


# DataMapper.setup(:default,"sqlite3://#{Dir.pwd}/betDB.db")



configure :development do
  DataMapper.setup(:default,"sqlite3://#{Dir.pwd}/betDB.db")
end

configure :production do
  DataMapper.setup(:default,ENV['DATABASE_URL'])
end



#creates model (table will be called in plural)
class User_data
  include DataMapper::Resource #mixin
  #property :ID, Serial
  property :User, String, :key => true
  property :Password, String
  property :win_sum, Integer
  property :loss_sum, Integer
  property :profit_sum, Integer
end
DataMapper.finalize
DataMapper.auto_upgrade!




get '/' do
  redirect '/home'
end

get '/home' do
  @title = "this is my home page"
  #@instance = query result from database
  erb :home
end

get '/signup' do
  @title='sign up'
  erb :signup
end

# check for account username duplication during signup
post '/signup' do
  print(params[:Username])
  unless User_data.get(params[:Username])
    @newUser=User_data.new
    @newUser.User=params[:Username]
    @newUser.Password=params[:Password]
    @newUser.win_sum = 0
    @newUser.loss_sum = 0
    @newUser.profit_sum = 0
    @newUser.save
  end
  redirect '/'
end



get '/login' do
  erb :login
end

#if credentials are correct initializes session values from database gamblers.db
post '/login' do
  @account=User_data.get(params[:Username])
  if @account.User==params[:Username] && @account.Password==params[:Password]
    session[:admin]=true # mark as logged in\
    session[:Username]=params[:Username]
    session[:session_win]=0
    session[:session_loss]=0
    session[:session_profit]=0
    session[:win_sum]=@account.win_sum
    session[:loss_sum]=@account.loss_sum
    session[:profit_sum]=@account.profit_sum
    session[:roll]=0
    session[:message]=""
    redirect to ('/bet')
  else
    session[:message] = "Username or Password ERROR! Please try again!"
    erb :login
  end
end

get '/bet' do
  halt(401, 'Not Authorized') unless session[:admin]  #does not allow access unless logged in
  erb :bet
end

post '/bet' do
  session[:message]=" "
  if params[:stake] !~ /\d/ or params[:number] !~ /[1-6]/
    session[:message]="Input is not VALID!!"
    erb :bet
  else
    @account=User_data.get(session[:Username])
    stake = params[:stake].to_i
    number = params[:number].to_i
    roll = rand(6) + 1
    if number == roll
      session[:session_win] += 1
      session[:win_sum] += 1
      session[:session_profit] += stake
      session[:profit_sum] += stake
      session[:message]="You are win!"
      erb :bet
    else
      session[:session_loss] += 1
      session[:loss_sum] += 1
      session[:session_profit] -= stake
      session[:profit_sum] -= stake
      session[:message]="You are lose… The dice number is #{roll}"
      erb :bet
    end
  end
end

post '/logout' do
  @user=User_data.get(session[:Username])
  @user.update(win_sum: session[:win_sum], loss_sum: session[:loss_sum], profit_sum: session[:profit_sum])
  session.clear #clears all session values
  redirect :login
end

not_found do
  halt(401, 'Empty Page')
end

