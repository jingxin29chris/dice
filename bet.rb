require 'sinatra'
require 'dm-core'
require 'dm-migrations'

enable :sessions

configure :development do
DataMapper.setup(:default,"sqlite3://#{Dir.pwd}/gambling.db")
end

configure :production do
DataMapper.setup(:default,ENV('DATABASE_URL'))
end

class Person
      include DataMapper::Resource
      property :username, String, key: true
      property :password,String
      property :totalWin, Integer
      property :totalLoss, Integer
      property :totalProfit, Integer
end

DataMapper.finalize
 
get '/' do
      erb :login
end

get '/login' do
      erb :login
end

post '/login' do
      @person = Person.get(params[:username])
       p "****************************"
       p params[:username]
      if(@person !=nil && @person.password == params[:password])
         session[:login] = true
         session[:name] = params[:username]
         session[:message] = "you have successful login"
         erb :person_page
       else
          session[:message] = "username and password do not match, please try again"
          redirect '/'
        end
 end


post '/bet/:username' do
   person = Person.get(params[:username])
   stake = params[:money].to_i
   number = params[:num].to_i
   roll = rand(6)+1
   if(number == roll)
    save_session(:win, 10*stake)
    session[:message] = "The dice landed on #{roll},  you win #{10*stake} chips"
  else
   save_session(:lost, stake)
   session[:message] = "The dice landed on #{roll}, your number is #{number}, you lost #{stake} chips"
   end
   redirect "/bet/#{person.username}"
end


get '/bet/:username' do
   @person = Person.get(params[:username])
    
   erb :person_page
end

#user logout and update his record and set session to nil
get '/bet/logout/:username' do
 person = Person.get(params[:username])
 session[:login] = nil
 session[:name] = nil
 session[:message] = "you have successfully logout"
 person.totalWin += (session[:win] || 0).to_i
 person.totalLoss += (session[:lost] || 0).to_i
 person.totalProfit += profit(:win, :lost)
 person.save
 session[:win] = 0
 session[:lost] = 0
 redirect '/'

end

   #save_session(:lost, 1000)
   #save_session(:win, 1000)
def save_session(won_lost, money)
   count = (session[won_lost] || 0).to_i
   count += money
   session[won_lost] = count
end

def profit(win, lost)
   count = (session[win] || 0).to_i
   count1 = (session[lost] || 0).to_i
   count - count1
end



